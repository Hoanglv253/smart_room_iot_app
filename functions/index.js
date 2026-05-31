import cors from 'cors';
import dotenv from 'dotenv';
import express from 'express';
import admin from 'firebase-admin';
import PayOS from '@payos/node';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

dotenv.config();

const app = express();
const port = Number(process.env.PORT || 8080);

const PAYOS_CLIENT_ID = defineSecret('PAYOS_CLIENT_ID');
const PAYOS_API_KEY = defineSecret('PAYOS_API_KEY');
const PAYOS_CHECKSUM_KEY = defineSecret('PAYOS_CHECKSUM_KEY');

const INVOICE_STATUS = {
  unpaid: 'unpaid',
  waitingPayment: 'waiting_payment',
  pending: 'pending',
  paid: 'paid',
  cancelled: 'cancelled',
};

const PAYOS_STATUS = {
  paid: 'PAID',
  pending: 'PENDING',
  cancelled: 'CANCELLED',
  expired: 'EXPIRED',
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

function envValue(name) {
  const directValue = process.env[name];
  if (directValue) return directValue;

  const secret = {
    PAYOS_CLIENT_ID,
    PAYOS_API_KEY,
    PAYOS_CHECKSUM_KEY,
  }[name];

  if (!secret) return '';

  try {
    return secret.value();
  } catch (_error) {
    return '';
  }
}

function requireEnv(name) {
  const value = envValue(name);
  if (!value) {
    throw new Error(`Missing environment variable ${name}`);
  }
  return value;
}

initializeFirebase();

const db = admin.firestore();
let payosInstance = null;

function hasGlobalPayosConfig() {
  return Boolean(
    envValue('PAYOS_CLIENT_ID') &&
      envValue('PAYOS_API_KEY') &&
      envValue('PAYOS_CHECKSUM_KEY'),
  );
}

function globalPayosConfig() {
  return {
    source: 'global',
    clientId: requireEnv('PAYOS_CLIENT_ID'),
    apiKey: requireEnv('PAYOS_API_KEY'),
    checksumKey: requireEnv('PAYOS_CHECKSUM_KEY'),
  };
}

function payosClient() {
  if (payosInstance) return payosInstance;

  const config = globalPayosConfig();
  payosInstance = payosClientFromConfig(config);
  return payosInstance;
}

function payosClientFromConfig(config) {
  return new PayOS(config.clientId, config.apiKey, config.checksumKey);
}

function appBaseUrl(request) {
  if (process.env.APP_PUBLIC_URL) return process.env.APP_PUBLIC_URL;

  const host = request?.get?.('x-forwarded-host') || request?.get?.('host');
  if (host && !host.includes('cloudfunctions.net')) {
    const protocol = request?.get?.('x-forwarded-proto') || request?.protocol || 'https';
    return `${protocol}://${host}`;
  }

  return 'https://asia-southeast1-unified-chess-496306-u1.cloudfunctions.net/api';
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

function invoiceRef(buildingId, invoiceId) {
  return db.collection('buildings').doc(buildingId).collection('invoices').doc(invoiceId);
}

function buildingRef(buildingId) {
  return db.collection('buildings').doc(buildingId);
}

function buildingPayosSettingsRef(buildingId) {
  return db.collection('buildingPayosSettings').doc(buildingId);
}

function paymentRef(orderCode) {
  return db.collection('payosPayments').doc(String(orderCode));
}

function maskedTail(value) {
  const text = readString(value);
  if (!text) return '';
  return text.length <= 6 ? text : text.slice(-6);
}

function publicPayosSettings(config) {
  return {
    configured: true,
    source: config.source,
    clientIdTail: maskedTail(config.clientId),
    apiKeyTail: maskedTail(config.apiKey),
    checksumKeyTail: maskedTail(config.checksumKey),
  };
}

async function ensureBuildingAdmin(buildingId, uid) {
  const buildingSnap = await buildingRef(buildingId).get();

  if (!buildingSnap.exists) {
    const error = new Error('Khong tim thay toa nha.');
    error.status = 404;
    throw error;
  }

  const building = buildingSnap.data();
  if (building.adminId !== uid) {
    const error = new Error('Ban khong co quyen cau hinh PayOS cho toa nha nay.');
    error.status = 403;
    throw error;
  }

  return building;
}

async function payosConfigForBuilding(buildingId) {
  const settingsSnap = await buildingPayosSettingsRef(buildingId).get();

  if (settingsSnap.exists) {
    const settings = settingsSnap.data();
    const clientId = readString(settings.clientId);
    const apiKey = readString(settings.apiKey);
    const checksumKey = readString(settings.checksumKey);

    if (clientId && apiKey && checksumKey) {
      return {
        source: 'building',
        clientId,
        apiKey,
        checksumKey,
      };
    }
  }

  if (hasGlobalPayosConfig()) return globalPayosConfig();

  const error = new Error('Admin chua cau hinh PayOS cho toa nha nay.');
  error.status = 409;
  throw error;
}

function rawWebhookOrderCode(requestBody) {
  return readInt(requestBody?.data?.orderCode || requestBody?.orderCode);
}

function isSuccessfulPayosWebhook(requestBody, webhookData) {
  return (
    requestBody?.success === true &&
    readString(requestBody?.code) === '00' &&
    readString(webhookData?.code) === '00'
  );
}

function isPaidPayosInformation(paymentInfo, invoiceAmount) {
  const status = readString(paymentInfo?.status).toUpperCase();
  const amountPaid = readInt(paymentInfo?.amountPaid);
  const amountRemaining = readInt(paymentInfo?.amountRemaining);

  return (
    status === PAYOS_STATUS.paid ||
    (invoiceAmount > 0 && amountPaid >= invoiceAmount) ||
    (invoiceAmount > 0 && amountRemaining === 0 && amountPaid > 0)
  );
}

function paymentResultPage(title, message) {
  return `<!doctype html>
<html lang="vi">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${title}</title>
    <style>
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        font-family: Arial, sans-serif;
        background: #f4f7fb;
        color: #172033;
      }
      main {
        width: min(420px, calc(100vw - 32px));
        padding: 28px;
        border-radius: 16px;
        background: #fff;
        box-shadow: 0 12px 40px rgba(15, 23, 42, 0.12);
        text-align: center;
      }
      h1 { margin: 0 0 12px; font-size: 24px; }
      p { margin: 0; line-height: 1.5; color: #4b5563; }
    </style>
  </head>
  <body>
    <main>
      <h1>${title}</h1>
      <p>${message}</p>
    </main>
  </body>
</html>`;
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
  if ((error.status || 500) >= 500) {
    console.error(error);
  } else {
    console.warn(error.message || 'Request error');
  }
  response.status(error.status || 500).json({
    message: error.message || 'Server error',
  });
}

async function syncPayosPaymentStatus(orderCode) {
  const targetPaymentRef = paymentRef(orderCode);
  const paymentSnap = await targetPaymentRef.get();

  if (!paymentSnap.exists) {
    return { synced: false, reason: 'payment_not_found' };
  }

  const payment = paymentSnap.data();
  const targetInvoiceRef = invoiceRef(payment.buildingId, payment.invoiceId);
  const invoiceSnap = await targetInvoiceRef.get();

  if (!invoiceSnap.exists) {
    return { synced: false, reason: 'invoice_not_found' };
  }

  const invoice = invoiceSnap.data();
  const invoiceAmount = readInt(invoice.totalAmount);
  const payosConfig = await payosConfigForBuilding(payment.buildingId);
  const paymentInfo = await payosClientFromConfig(
    payosConfig,
  ).getPaymentLinkInformation(orderCode);
  const amountPaid = readInt(paymentInfo.amountPaid);
  const paymentStatus = readString(paymentInfo.status).toUpperCase();

  if (!isPaidPayosInformation(paymentInfo, invoiceAmount)) {
    await targetPaymentRef.update({
      payosStatus: paymentStatus || PAYOS_STATUS.pending,
      lastSyncedInfo: paymentInfo,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { synced: false, reason: paymentStatus || 'not_paid' };
  }

  const isAmountMismatch =
    amountPaid > 0 && invoiceAmount > 0 && amountPaid !== invoiceAmount;

  await db.runTransaction(async (transaction) => {
    if (isAmountMismatch) {
      transaction.update(targetInvoiceRef, {
        status: INVOICE_STATUS.pending,
        paymentProvider: 'payos',
        paymentMethod: 'payos',
        paymentNote: `PayOS bao da nhan ${amountPaid}, hoa don ${invoiceAmount}. Can kiem tra lai.`,
        'payos.lastSyncedInfo': paymentInfo,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.update(targetPaymentRef, {
        status: INVOICE_STATUS.pending,
        payosStatus: paymentStatus,
        lastSyncedInfo: paymentInfo,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.update(targetInvoiceRef, {
      status: INVOICE_STATUS.paid,
      paymentProvider: 'payos',
      paymentMethod: 'payos',
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentConfirmedAt: admin.firestore.FieldValue.serverTimestamp(),
      paymentNote: 'PayOS da xac nhan thanh toan.',
      'payos.lastSyncedInfo': paymentInfo,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    transaction.update(targetPaymentRef, {
      status: INVOICE_STATUS.paid,
      payosStatus: paymentStatus,
      lastSyncedInfo: paymentInfo,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return {
    synced: true,
    amountMismatch: isAmountMismatch,
    status: paymentStatus,
  };
}

app.get('/', (_request, response) => {
  response.json({
    ok: true,
    service: 'Smart Room PayOS backend',
    health: '/health',
  });
});

app.get('/health', (request, response) => {
  response.json({
    ok: true,
    webhookUrl: `${appBaseUrl(request)}/payos-webhook`,
    payosConfigured: hasGlobalPayosConfig(),
    buildingPayosSupported: true,
    firebaseConfigured: Boolean(
      process.env.FIREBASE_SERVICE_ACCOUNT_JSON ||
        process.env.FIREBASE_SERVICE_ACCOUNT_BASE64 ||
        process.env.GOOGLE_APPLICATION_CREDENTIALS ||
        process.env.FUNCTION_TARGET ||
        process.env.K_SERVICE,
    ),
  });
});

app.get('/building-payos-settings', async (request, response) => {
  try {
    const decodedToken = await verifyFirebaseUser(request);
    const buildingId = readString(request.query?.buildingId);

    if (!buildingId) {
      response.status(400).json({ message: 'Thieu buildingId.' });
      return;
    }

    await ensureBuildingAdmin(buildingId, decodedToken.uid);

    const settingsSnap = await buildingPayosSettingsRef(buildingId).get();
    if (!settingsSnap.exists) {
      response.json({ configured: false });
      return;
    }

    const settings = settingsSnap.data();
    const clientId = readString(settings.clientId);
    const apiKey = readString(settings.apiKey);
    const checksumKey = readString(settings.checksumKey);

    if (!clientId || !apiKey || !checksumKey) {
      response.json({ configured: false });
      return;
    }

    response.json(publicPayosSettings({
      source: 'building',
      clientId,
      apiKey,
      checksumKey,
    }));
  } catch (error) {
    sendError(response, error);
  }
});

app.post('/building-payos-settings', async (request, response) => {
  try {
    const decodedToken = await verifyFirebaseUser(request);
    const buildingId = readString(request.body?.buildingId);
    const clientId = readString(request.body?.clientId);
    const apiKey = readString(request.body?.apiKey);
    const checksumKey = readString(request.body?.checksumKey);

    if (!buildingId) {
      response.status(400).json({ message: 'Thieu buildingId.' });
      return;
    }

    if (!clientId || !apiKey || !checksumKey) {
      response.status(400).json({
        message: 'Hay nhap du Client ID, API Key va Checksum Key PayOS.',
      });
      return;
    }

    await ensureBuildingAdmin(buildingId, decodedToken.uid);

    await buildingPayosSettingsRef(buildingId).set({
      buildingId,
      adminId: decodedToken.uid,
      clientId,
      apiKey,
      checksumKey,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    response.json(publicPayosSettings({
      source: 'building',
      clientId,
      apiKey,
      checksumKey,
    }));
  } catch (error) {
    sendError(response, error);
  }
});

app.post('/create-payos-payment', async (request, response) => {
  try {
    console.log('POST /create-payos-payment', {
      hasAuthorization: Boolean(request.headers.authorization),
      buildingId: readString(request.body?.buildingId),
      invoiceId: readString(request.body?.invoiceId),
    });

    const decodedToken = await verifyFirebaseUser(request);
    const buildingId = readString(request.body?.buildingId);
    const invoiceId = readString(request.body?.invoiceId);

    if (!buildingId || !invoiceId) {
      response.status(400).json({ message: 'Thieu buildingId hoac invoiceId.' });
      return;
    }

    const targetInvoiceRef = invoiceRef(buildingId, invoiceId);
    const invoiceSnap = await targetInvoiceRef.get();

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
    const baseUrl = appBaseUrl(request);
    const returnUrl = `${baseUrl}/payment/success?buildingId=${buildingId}&invoiceId=${invoiceId}`;
    const cancelUrl = `${baseUrl}/payment/cancel?buildingId=${buildingId}&invoiceId=${invoiceId}`;
    const payosConfig = await payosConfigForBuilding(buildingId);

    const paymentLink = await payosClientFromConfig(payosConfig).createPaymentLink({
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
      transaction.update(targetInvoiceRef, {
        status: INVOICE_STATUS.waitingPayment,
        paymentProvider: 'payos',
        payos: {
          orderCode,
          paymentLinkId: paymentLink.paymentLinkId || '',
          checkoutUrl: paymentLink.checkoutUrl || '',
          qrCode: paymentLink.qrCode || '',
          description,
          payosSource: payosConfig.source,
          payosClientIdTail: maskedTail(payosConfig.clientId),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      transaction.set(paymentRef(orderCode), {
        orderCode,
        buildingId,
        invoiceId,
        tenantId: decodedToken.uid,
        amount,
        status: INVOICE_STATUS.waitingPayment,
        paymentLinkId: paymentLink.paymentLinkId || '',
        checkoutUrl: paymentLink.checkoutUrl || '',
        payosSource: payosConfig.source,
        payosClientIdTail: maskedTail(payosConfig.clientId),
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

app.get('/payment/success', async (request, response) => {
  try {
    let orderCode = readInt(request.query?.orderCode);
    if (!orderCode) {
      const buildingId = readString(request.query?.buildingId);
      const invoiceId = readString(request.query?.invoiceId);
      if (buildingId && invoiceId) {
        const invoiceSnap = await invoiceRef(buildingId, invoiceId).get();
        orderCode = readInt(invoiceSnap.data()?.payos?.orderCode);
      }
    }

    if (orderCode) {
      await syncPayosPaymentStatus(orderCode);
    }

    response
      .status(200)
      .type('html')
      .send(
        paymentResultPage(
          'Thanh toan dang duoc xac nhan',
          'Ban co the quay lai ung dung. Hoa don se tu cap nhat khi PayOS xac nhan giao dich.',
        ),
      );
  } catch (error) {
    console.error('Payment success sync failed', error);
    response
      .status(200)
      .type('html')
      .send(
        paymentResultPage(
          'Da nhan ket qua thanh toan',
          'Ban co the quay lai ung dung. Neu hoa don chua doi trang thai, hay cho them mot chut de webhook PayOS cap nhat.',
        ),
      );
  }
});

app.get('/payment/cancel', (_request, response) => {
  response
    .status(200)
    .type('html')
    .send(
      paymentResultPage(
        'Thanh toan da huy',
        'Hoa don van giu trang thai chua thanh toan. Ban co the quay lai ung dung de thanh toan lai.',
      ),
    );
});

app.post('/payos-webhook', async (request, response) => {
  const rawOrderCode = rawWebhookOrderCode(request.body);

  if (!rawOrderCode) {
    response.status(200).send('Ignored');
    return;
  }

  const targetPaymentRef = paymentRef(rawOrderCode);
  const paymentSnap = await targetPaymentRef.get();

  if (!paymentSnap.exists) {
    console.warn('PayOS payment not found', { orderCode: rawOrderCode });
    response.status(200).send('Payment not found');
    return;
  }

  const payment = paymentSnap.data();
  let webhookData;

  try {
    const payosConfig = await payosConfigForBuilding(payment.buildingId);
    webhookData = payosClientFromConfig(payosConfig).verifyPaymentWebhookData(
      request.body,
    );
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

  if (orderCode !== rawOrderCode) {
    response.status(400).send('Invalid order code');
    return;
  }

  if (!isSuccessfulPayosWebhook(request.body, webhookData)) {
    await targetPaymentRef.update({
      status: INVOICE_STATUS.waitingPayment,
      lastWebhook: webhookData,
      lastWebhookAccepted: false,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    response.status(200).send('Webhook ignored');
    return;
  }

  const targetInvoiceRef = invoiceRef(payment.buildingId, payment.invoiceId);
  const invoiceSnap = await targetInvoiceRef.get();

  if (!invoiceSnap.exists) {
    response.status(200).send('Invoice not found');
    return;
  }

  const invoice = invoiceSnap.data();
  const invoiceAmount = readInt(invoice.totalAmount);
  const isAmountMismatch = amount > 0 && invoiceAmount > 0 && amount !== invoiceAmount;

  await db.runTransaction(async (transaction) => {
    if (isAmountMismatch) {
      transaction.update(targetInvoiceRef, {
        status: INVOICE_STATUS.pending,
        paymentProvider: 'payos',
        paymentMethod: 'payos',
        paymentNote: `PayOS bao so tien ${amount}, hoa don ${invoiceAmount}. Can kiem tra lai.`,
        'payos.lastWebhook': webhookData,
        'payos.paymentLinkId': paymentLinkId || invoice.payos?.paymentLinkId || '',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      transaction.update(targetPaymentRef, {
        status: INVOICE_STATUS.pending,
        lastWebhook: webhookData,
        lastWebhookAccepted: true,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return;
    }

    transaction.update(targetInvoiceRef, {
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
    transaction.update(targetPaymentRef, {
      status: INVOICE_STATUS.paid,
      reference: readString(webhookData.reference),
      transactionDateTime: readString(webhookData.transactionDateTime),
      lastWebhook: webhookData,
      lastWebhookAccepted: true,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  response.status(200).send(isAmountMismatch ? 'Amount mismatch' : 'OK');
});

export const api = onRequest(
  {
    region: 'asia-southeast1',
    secrets: [PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY],
  },
  app,
);

if (!process.env.FUNCTION_TARGET && !process.env.K_SERVICE) {
  app.listen(port, () => {
    console.log(`PayOS backend listening on port ${port}`);
  });
}
