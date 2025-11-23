// lib/core/config/api.dart
class ApiConfig {
  // nếu chạy trên mobile emulator: dùng IP máy dev hoặc tunnel. 
  // ví dụ khi backend chạy local và test trên Android emulator: 10.0.2.2
  static const String BASE_URL = "http://192.168.1.7:3000"; //chỉnh theo môi trường
  // Auth
  static const String AUTH_LOGIN = "/api/auth/login";
  static const String AUTH_REGISTER = "/api/auth/register";
  static const String USER_CHANGE_PASSWORD = "$BASE_URL/user/change-password";

  // Categories
  static const String CATEGORIES = "/api/category";
  
  // Products
  static const String PRODUCTS = "/api/products";
  static const String PRODUCT_BY_ID = "/api/products"; // + /:id
  
  // Vouchers
  static const String VOUCHERS = "/api/voucher";
  static const String APPLY_VOUCHER = "/api/voucher/apply";
  
  // User
  static const String USER_PROFILE = "/api/user/me";
  static const String USER_UPDATE = "/api/user/update";
  static const String USER_ADDRESS = "/api/user/address";
  
  // Cart & Orders
  static const String CART = "/api/cart";
  static const String ORDERS = "/api/orders";

  static String cancelOrder(String orderId) => "/api/orders/$orderId/cancel";
  
  // Wishlist
  static const String WISHLIST = "/api/wishlist";
  
  // Upload
  static const String UPLOAD = "/api/upload";
  static const String UPLOAD_AVATAR = "$BASE_URL/api/upload/avatar";

  // Notification endpoints
  static const String NOTIFICATIONS = '/api/notifications';
  static const String NOTIFICATIONS_UNREAD_COUNT = '/api/notifications/unread-count';
  static const String NOTIFICATIONS_READ_ALL = '/api/notifications/read-all';
  
  static String notificationRead(String id) => '/api/notifications/$id/read';
  static String deleteNotification(String id) => '/api/notifications/$id';
}

  
  

