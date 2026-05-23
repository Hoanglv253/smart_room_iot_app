import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import admin from 'firebase-admin';
import PayOS from '@payos/node';

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 8080);

const INVOICE_STATUS = {
  unpaid: 'unpaid',
  waitingPayment: 'waiting_payment',
  pending: 'pending',
  paid: 'paid',
  cancelled: 'cancelled',
};

app.use(cors({ origin: true }));
app.use(express.json({ limit: '1mb' }));

function serviceAccountFromEnv() {
  const rawJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (rawJson) return JSON.parse(rawJson);

  const base64 = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;
  if (base64) {
    return JSON.parse(Buffer.from(base64, 'base64').toString('utf8'));
  }

  return null;
}

function initializeFirebase() {
  if (admin.apps.length > 0) return;

  const serviceAccount = serviceAccountFromEnv();
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    return;
  }

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

function requireEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing environment variable ${name}`);
  }
  return value;
}

initializeFirebase();

const db = admin.firestore();
const payos = new PayOS(
  requireEnv('PAYOS_CLIENT_ID'),
  requireEnv('PAYOS_API_KEY'),
  requireEnv('PAYOS_CHECKSUM_KEY'),
);

function appBaseUrl() {
  return process.env.APP_PUBLIC_URL || 'https://smart-room-iot-353c5.web.app';
}

function readString(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function readInt(value) {
  if (typeof value === 'number') return Math.trunc(value);
  if (typeof value === 'string') {
    const parsed = Number.parseInt(value.replace(/[.,\s]/g, ''), 10);
    return Number.isFinite(parsed) ? parsed : 0;
  }
  return 0;
}

function buildOrderCode() {
  return Number(`${Date.now()}${Math.floor(Math.random() * 90 + 10)}`);
}

function shortDescription(orderCode) {
  return `HD${String(orderCode).slice(-7)}`;
}

async function verifyFirebaseUser(request) {
  const authorization = request.headers.authorization || '';
  const match = authorization.match(/^Bearer (.+)$/);
  if (!match) {
    const error = new Error('Missing Firebase ID token');
    error.status = 401;
    throw error;
  }
  return admin.auth().verifyIdToken(match[1]);
}

function ensureTenantOwnsInvoice(invoice, uid) {
  if (invoice.tenantId !== uid) {
    const error = new Error('Ban khong co quyen thanh toan hoa don nay.');
    error.status = 403;
    throw error;
  }
}

function ensurePayable(invoice) {
  const status = readString(invoice.status) || INVOICE_STATUS.unpaid;
  if (status === INVOICE_STATUS.paid) {
    const error = new Error('Hoa don da thanh toan.');
    error.status = 409;
    throw error;
  }
  if (status === INVOICE_STATUS.cancelled) {
    const error = new Error('Hoa don da bi huy.');
    error.status = 409;
    throw error;
  }
}

function sendError(response, error) {
  console.error(error);
  response.status(error.status || 500).json({
    message: error.message || 'Server error',
  });
}

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.post('/create-payos-payment', async (request, response) => {
  try {
    const decodedToken = await verifyFirebaseUser(request);
    const buildingId = readString(request.body?.buildingId);
    const invoiceId = readString(request.body?.invoiceId);

    if (!buildingId || !invoiceId) {
      response.status(400).json({ message: 'Thieu buildingId hoac invoiceId.' });
      return;
    }

    const invoiceRef = db
      .collection('buildings')
      .doc(buildingId)
      .collection('invoices')
      .doc(invoiceId);
    const invoiceSnap = await invoiceRef.get();

    if (!invoiceSnap.exists) {
      response.status(404).json({ message: 'Khong tim thay hoa don.' });
      return;
    }

    const invoice = invoiceSnap.data();
    ensureTenantOwnsInvoice(invoice, decodedToken.uid);
    ensurePayable(invoice);

    const amount = readInt(invoice.totalAmount);
    if (amount <= 0) {
      response.status(409).json({ message: 'So tien hoa don khong hop le.' });
      return;
    }

    const existingPayos = invoice.payos || {};
    if (existingPayos.checkoutUrl && existingPayos.orderCode) {
      response.json({
        checkoutUrl: existingPayos.checkoutUrl,
        orderCode: existingPayos.orderCode,
        qrCode: existingPayos.qrCode || '',
      });
      return;
    }

    const orderCode = buildOrderCode();
    const description = shortDescription(orderCode);
    const returnUrl = `${appBaseUrl()}/payment/success?buildingId=${buildingId}&invoiceId=${invoiceId}`;
    const cancelUrl = `${appBaseUrl()}/payment/cancel?buildingId=${buildingId}&invoiceId=${invoiceId}`;

    const paymentLink = await payos.createPaymentLink({
      orderCode,
      amount,
      description,
      buyerName: readString(invoice.tenantName),
      buyerEmail: readString(invoice.tenantEmail),
      items: [
        {
          name: readString(invoice.roomName) || 'Hoa don phong',
          quantity: 1,
          price: amount,
        },
      ],
      returnUrl,
      cancelUrl,
    });

    await db.runTransaction(async (transaction) => {
      transaction.update(invoiceRef, {
        status: INVOICE_STATUS.waitingPayment,
        paymentProvider: 'payos',
        payos: {
          orderCode,
          paymentLinkId: paymentLink.paymentLinkId || '',
          checkoutUrl: paymentLink.checkoutUrl || '',
          qrCode: paymentLink.qrCode || '',
          description,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      transaction.set(db.collection('payosPayments').doc(String(orderCode)), {
        orderCode,
        buildingId,
        invoiceId,
        tenantId: decodedToken.uid,
        amount,
        status: INVOICE_STATUS.waitingPayment,
        paymentLinkId: paymentLink.paymentLinkId || '',
        checkoutUrl: paymentLink.checkoutUrl || '',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    response.json({
      checkoutUrl: paymentLink.checkoutUrl || '',
      orderCode,
      qrCode: paymentLink.qrCode || '',
    });
  } catch (error) {
    sendError(response, error);
  }
});

app.post('/payos-webhook', async (request, response) => {
  let webhookData;

  try {
    webhookData = payos.verifyPaymentWebhookData(request.body);
  } catch (error) {
    console.error('Invalid PayOS webhook', error);
    response.status(400).send('Invalid webhook');
    return;
  }

  if (!webhookData) {
    response.status(400).send('Invalid webhook');
    return;
  }

  const orderCode = readInt(webhookData.orderCode);
  const amount = readInt(webhookData.amount);
  const paymentLinkId = readString(webhookData.paymentLinkId);

  if (!orderCode) {
    response.status(200).send('Ignored');
    return;
  }

  const paymentRef = db.collection('payosPayments').doc(String(orderCode));
  const paymentSnap = await paymentRef.get();

  if (!paymentSnap.exists) {
    console.warn('PayOS payment not found', { orderCode });
    response.status(200).send('Payment not found');
    return;
  }

  const payment = paymentSnap.data();
  const invoiceRef = db
    .collection('buildings')
    .doc(payment.buildingId)
    .collection('invoices')
    .doc(payment.invoiceId);
  const invoiceSnap = await invoiceRef.get();

  if (!invoiceSnap.exists) {
    response.status(200).send('Invoice not found');
    return;
  }

  const invoice = invoiceSnap.data();
  const invoiceAmount = readInt(invoice.totalAmount);
  const isAmountMismatch = amount > 0 && invoiceAmount > 0 && amount !== invoiceAmount;

  await db.runTransaction(async (transaction) => {
    if (isAmountMismatch) {
      transaction.update(invoiceRef, {
        status: INVOICE_STATUS.pending,
        paymentProvider: 'payos',
        paymentMethod: 'payos',
        paymentNote: `PayOS bao so tien ${amount}, hoa don ${invoiceAmount}. Can kiem tra lai.`,
        'payos.lastWebhook': webhookData,
        'payos.paymentLinkId': paymentLinkId || invoice.payos?.paymentLinkId || '',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.update(paymentRef, {
        status: INVOICE_STATUS.pending,
        lastWebhook: webhookData,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.update(invoiceRef, {
      status: INVOICE_STATUS.paid,
      paymentProvider: 'payos',
      paymentMethod: 'payos',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentNote: readString(webhookData.reference)
        ? `PayOS: ${readString(webhookData.reference)}`
        : 'PayOS da xac nhan thanh toan.',
      'payos.reference': readString(webhookData.reference),
      'payos.transactionDateTime': readString(webhookData.transactionDateTime),
      'payos.lastWebhook': webhookData,
      'payos.paymentLinkId': paymentLinkId || invoice.payos?.paymentLinkId || '',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.update(paymentRef, {
      status: INVOICE_STATUS.paid,
      reference: readString(webhookData.reference),
      transactionDateTime: readString(webhookData.transactionDateTime),
      lastWebhook: webhookData,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  response.status(200).send(isAmountMismatch ? 'Amount mismatch' : 'OK');
});

app.listen(port, () => {
  console.log(`PayOS backend listening on port ${port}`);
});
