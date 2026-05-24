# PayOS Backend

Backend nay tao link thanh toan PayOS va nhan webhook PayOS de tu dong doi hoa don sang `paid`.
Co the chay bang Firebase Functions khi du an da len Blaze, hoac chay rieng tren Render/Railway/VPS.

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

Khi deploy Firebase Functions tren Blaze, chi can 3 secret PayOS. Firebase Admin SDK tu dung quyen cua Functions, khong can `FIREBASE_SERVICE_ACCOUNT_BASE64`.

Khi chay backend rieng tren Render/Railway/VPS, can them `FIREBASE_SERVICE_ACCOUNT_BASE64`. Day la service account JSON duoc encode base64. Khong commit file service account len Git.

## Endpoint

```text
GET  /health
POST /create-payos-payment
POST /payos-webhook
GET  /payment/success
GET  /payment/cancel
```

## Deploy Firebase Functions

```bash
firebase functions:secrets:set PAYOS_CLIENT_ID --project smart-room-iot-353c5
firebase functions:secrets:set PAYOS_API_KEY --project smart-room-iot-353c5
firebase functions:secrets:set PAYOS_CHECKSUM_KEY --project smart-room-iot-353c5
firebase deploy --only functions --project smart-room-iot-353c5
```

Webhook PayOS can cau hinh:

```text
https://asia-southeast1-smart-room-iot-353c5.cloudfunctions.net/api/payos-webhook
```

Flutter dang mac dinh goi backend nay. Neu dung backend rieng, chay Flutter voi URL backend rieng:

```bash
flutter run --dart-define=PAYOS_BACKEND_URL=https://your-backend-domain.com
```

Sau khi deploy len Render/Railway, cau hinh webhook trong PayOS:

```text
https://your-backend-domain.com/payos-webhook
```
