# PayOS Backend Rieng

Backend nay chay rieng tren Render/Railway/VPS, khong can Firebase Blaze.
Flutter goi backend nay de tao link PayOS. PayOS goi webhook ve backend nay, backend cap nhat Firestore bang Firebase Admin SDK.

## Cai dat local

```bash
cd functions
npm install
copy .env.example .env
npm start
```

## Bien moi truong can co

```text
PORT=8080
APP_PUBLIC_URL=https://example.com
PAYOS_CLIENT_ID=...
PAYOS_API_KEY=...
PAYOS_CHECKSUM_KEY=...
FIREBASE_SERVICE_ACCOUNT_BASE64=...
```

`FIREBASE_SERVICE_ACCOUNT_BASE64` la service account JSON duoc encode base64. Khong commit file service account len Git.

## Endpoint

```text
GET  /health
POST /create-payos-payment
POST /payos-webhook
```

Sau khi deploy len Render/Railway, cau hinh webhook trong PayOS:

```text
https://your-backend-domain.com/payos-webhook
```

Khi chay Flutter, truyen URL backend:

```bash
flutter run --dart-define=PAYOS_BACKEND_URL=https://your-backend-domain.com
```
