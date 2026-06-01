# PayOS Backend Khong Can Blaze

Backend nay tao link thanh toan PayOS va nhan webhook PayOS de tu dong doi hoa don sang `paid`.
Neu khong nang Firebase len Blaze, deploy backend nay len Render/Railway/VPS va cho PayOS goi webhook ve backend do.

## Chay local

```bash
cd functions
npm install
copy .env.example .env
npm start
```

Khi chay tren dien thoai that, `localhost` cua dien thoai khong phai may tinh.
Muon test local thi dung mot URL public tam thoi nhu ngrok/cloudflared, roi cau hinh PayOS webhook vao URL do.

## Bien moi truong can co

```text
PORT=8080
PAYOS_CLIENT_ID=...
PAYOS_API_KEY=...
PAYOS_CHECKSUM_KEY=...
FIREBASE_SERVICE_ACCOUNT_BASE64=...
```

`FIREBASE_SERVICE_ACCOUNT_BASE64` la service account JSON duoc encode base64. Khong commit file service account len Git.

`APP_PUBLIC_URL` la tuy chon. Neu khong set, backend tu lay domain public cua request, vi du `https://smart-room-payos-backend.onrender.com`.

## Endpoint

```text
GET  /health
POST /create-payos-payment
POST /payos-webhook
GET  /payment/success
GET  /payment/cancel
```

## Deploy Render

Da co file `render.yaml` o thu muc goc du an Flutter. Khi tao Blueprint tren Render, Render se chay backend trong `functions`.

Can khai bao cac bien moi truong tren Render:

```text
PAYOS_CLIENT_ID
PAYOS_API_KEY
PAYOS_CHECKSUM_KEY
FIREBASE_SERVICE_ACCOUNT_BASE64
```

Sau khi Render tao xong domain backend, vi du:

```text
https://smart-room-payos-backend.onrender.com
```

Thi chay Flutter voi URL backend do:

```bash
flutter run --dart-define=PAYOS_BACKEND_URL=https://your-backend-domain.com
```

Va cau hinh webhook trong PayOS:

```text
https://your-backend-domain.com/payos-webhook
```

## Neu sau nay dung Firebase Blaze

Van co the deploy cung backend nay len Firebase Functions. Khi do URL backend se la:

```text
https://asia-southeast1-unified-chess-496306-u1.cloudfunctions.net/api
```

Va webhook PayOS la:

```text
https://asia-southeast1-unified-chess-496306-u1.cloudfunctions.net/api/payos-webhook
```
