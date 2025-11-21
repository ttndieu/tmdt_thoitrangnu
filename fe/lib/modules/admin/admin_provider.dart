import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../modules/auth/providers/auth_provider.dart';
import 'admin_routes.dart';

class AdminProvider with ChangeNotifier {
  final AuthProvider auth;
  final ApiClient api;

  AdminProvider(this.auth, this.api);

  /// Route hiện tại trong admin
  String currentRoute = AdminRoutes.dashboard;

  /// Kiểm tra quyền admin
  bool get isAdmin => auth.user?.role == "admin";

  /// Lấy token khi cần
  String? get token => auth.user?.token;

  /// Đổi màn khi nhấn sidebar
  void changeRoute(String route) {
    currentRoute = route;
    notifyListeners();
  }
}
