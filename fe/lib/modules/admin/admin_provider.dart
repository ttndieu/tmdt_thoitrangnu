// lib/modules/admin/admin_provider.dart
import 'package:flutter/material.dart';
import '../../core/network/api_client.dart';
import '../../modules/auth/providers/auth_provider.dart';
import 'admin_routes.dart';

class AdminProvider with ChangeNotifier {
  final AuthProvider auth;
  final ApiClient api;

  AdminProvider(this.auth, this.api);

  String _currentRoute = AdminRoutes.dashboard;
  String get currentRoute => _currentRoute;

  bool get isAdmin => auth.user?.role == "admin";
  String? get token => auth.user?.token;

  // ====== SIDEBAR COLLAPSE SUPPORT ======
  bool isSidebarCollapsed = false;

  void toggleSidebar() {
    isSidebarCollapsed = !isSidebarCollapsed;
    notifyListeners();
  }

  // PRODUCT DETAIL / FORM SUPPORT
  String? selectedProductId;
  String? editingProductId;
  Map<String, dynamic>? editingProductData;

  void openProductDetail(String id) {
    selectedProductId = id;
    _currentRoute = AdminRoutes.productDetail;
    notifyListeners();
  }

  void openProductForm([Map<String, dynamic>? product]) {
    editingProductData = product;
    editingProductId = product?['_id'];
    _currentRoute = AdminRoutes.productForm;
    notifyListeners();
  }

  void backToProducts() {
    selectedProductId = null;
    editingProductId = null;
    editingProductData = null;
    _currentRoute = AdminRoutes.products;
    notifyListeners();
  }

  void changeRoute(String route) {
    _currentRoute = route;

    // reset editing when leaving form/detail
    if (route != AdminRoutes.productDetail) selectedProductId = null;
    if (route != AdminRoutes.productForm) {
      editingProductId = null;
      editingProductData = null;
    }

    if (route != AdminRoutes.userDetail) selectedUserId = null;
    if (route != AdminRoutes.userForm) editingUser = null;

    notifyListeners();
  }

  Future<void> logout(BuildContext context) async {
    await auth.logout();
    _currentRoute = AdminRoutes.dashboard;
    selectedProductId = null;
    editingProductId = null;
    editingProductData = null;

    selectedUserId = null;
    editingUser = null;

    notifyListeners();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    }
  }

  // USER DETAIL / FORM SUPPORT
  String? selectedUserId;
  Map<String, dynamic>? editingUser;

  void openUserDetail(String id) {
    selectedUserId = id;
    _currentRoute = AdminRoutes.userDetail;
    notifyListeners();
  }

  void openUserForm([Map<String, dynamic>? user]) {
    editingUser = user;
    _currentRoute = AdminRoutes.userForm;
    notifyListeners();
  }

  void backToUsers() {
    selectedUserId = null;
    editingUser = null;
    _currentRoute = AdminRoutes.users;
    notifyListeners();
  }
}
