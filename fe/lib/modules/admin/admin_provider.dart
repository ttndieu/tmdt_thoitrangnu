// lib/providers/admin_provider.dart
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../modules/auth/providers/auth_provider.dart';
import 'admin_routes.dart';

class AdminProvider with ChangeNotifier {
  final AuthProvider auth;
  final ApiClient api;

  AdminProvider(this.auth, this.api);

  /// Route hiện tại trong admin
  String _currentRoute = AdminRoutes.dashboard;
  String get currentRoute => _currentRoute;

  /// Kiểm tra quyền admin
  bool get isAdmin => auth.user?.role == "admin";

  /// Lấy token khi cần
  String? get token => auth.user?.token;

  /// Đổi màn khi nhấn sidebar
  void changeRoute(String route) {
    _currentRoute = route;
    notifyListeners();
  }

  /// ĐĂNG XUẤT HOÀN TOÀN – XÓA USER + ĐẨY VỀ LOGIN
  Future<void> logout(BuildContext context) async {
    // 1. Xóa user khỏi AuthProvider
    await auth.logout(); // giả sử AuthProvider có hàm logout()

    // 2. Reset route admin
    _currentRoute = AdminRoutes.dashboard;

    // 3. Thông báo UI
    notifyListeners();

    // 4. Đẩy về trang login (thay '/login' bằng route thật của bạn)
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      // Nếu dùng GoRouter thì dùng: context.go('/login');
    }
  }
}