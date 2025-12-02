# README

## 1. Giới thiệu

Dự án gồm hai phần:  
- Backend viết bằng Node.js + Express + MongoDB.  
- Frontend viết bằng Flutter.

## 2. Yêu cầu hệ thống

- Node.js >= 18  
- Flutter >= 3.9.x  
- Dart >= 3.9.x  
- MongoDB Atlas hoặc MongoDB Local  
- Thiết bị Android hoặc Chrome (nếu chạy Flutter Web)


## 3. Cài đặt Backend
### 3.1 Cấu trúc Backend
BE/
 ├── src/
 ├── package.json
 ├── server.js
 └── .env

### 3.2 Cài đặt thư viện

Đi vào thư mục Backend:
cd BE
npm install


### 3.3 Tạo file .env

Tạo file `.env` trong thư mục BE với nội dung sau:

PORT=3000
MONGO_URI=mongodb+srv://...yourcluster...
CLIENT_URL=http://localhost:3000

JWT_SECRET=yoursecret
JWT_REFRESH=yourrefreshsecret

CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...

MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=...
MAIL_PASS=...

# VNPay
VNPAY_TMN_CODE=KEI7KOTN
VNPAY_HASH_SECRET=TVHGUW10Z9QC9JFWB0OHV64F2ZB6NM8H
VNPAY_URL=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html

VNPAY_RETURN_URL=https://<your-ngrok>/api/payment/vnpay/callback
VNP_IPN_URL=https://<your-ngrok>/api/payment/vnpay/ipn

### 3.4 Chạy Backend
npm run dev
Nếu kết nối thành công sẽ xuất hiện:

Server running at http://localhost:3000
Connected MongoDB...

## 4. Cài đặt Frontend (Flutter)
### 4.1 Cấu trúc Flutter
FE/
 ├── lib/
 ├── assets/
 ├── pubspec.yaml

### 4.2 Cài đặt thư viện
Di chuyển vào FE và chạy:
flutter pub get

Các thư viện chính bao gồm:  
provider, dio, shared_preferences, flutter_secure_storage, cached_network_image, fl_chart, image_picker, webview_flutter, pdf, printing.
### 4.3 Khai báo assets trong pubspec.yaml
assets:
  - assets/logo.png

### 4.4 Cấu hình API base URL cho frontend
Tạo file lib/core/config/api.dart:
static const String BASE_URL = "http://192.168.1.5:3000"; //chỉnh theo môi trường

### 4.5 Chạy ứng dụng Flutter

Android:
flutter run

Web:
flutter run -d chrome

## 5. Thiết lập VNPay
VNPay yêu cầu Backend phải có URL public.  
Nếu chạy local, cần:
### 5.1 Bật ngrok
ngrok http 3000
Sau đó lấy URL:
https://xxxxx.ngrok-free.app
Gán vào `.env`:
VNPAY_RETURN_URL=https://xxxxx.ngrok-free.app/api/payment/vnpay/callback
VNP_IPN_URL=https://xxxxx.ngrok-free.app/api/payment/vnpay/ipn

## 6. Quy trình chạy đầy đủ

### Backend
1. Cài thư viện: `npm install`
2. Tạo `.env`
3. Chạy server: `npm run dev`
4. Nếu dùng VNPay → chạy ngrok

### Frontend
1. Chạy `flutter pub get`
2. Cập nhật API baseUrl
3. Chạy ứng dụng: `flutter run`
