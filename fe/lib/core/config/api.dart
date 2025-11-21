// lib/core/config/api.dart
class ApiConfig {
  // nếu chạy trên mobile emulator: dùng IP máy dev hoặc tunnel. 
  // ví dụ khi backend chạy local và test trên Android emulator: 10.0.2.2
  static const String BASE_URL = "http://192.168.1.5:3000"; //chỉnh theo môi trường
  static const String AUTH_LOGIN = "$BASE_URL/api/auth/login";
  static const String AUTH_REGISTER = "$BASE_URL/api/auth/register";


  // products, cart... later
  static const String PRODUCTS = "$BASE_URL/api/products";
  static const String CART = "$BASE_URL/api/cart";
  static const String ORDERS = "$BASE_URL/api/orders";
  static const String USER_PROFILE = "$BASE_URL/api/user/me";
  static const String WISHLIST = "$BASE_URL/api/wishlist";
  static const String UPLOAD = "$BASE_URL/api/upload";
}

  
  

