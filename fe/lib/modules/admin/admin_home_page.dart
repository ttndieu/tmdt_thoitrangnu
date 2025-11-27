import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_provider.dart';
import 'admin_routes.dart';
import 'admin_menu.dart';

// Widgets
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';

// Pages
import 'dashboard/dashboard_page.dart';
import 'products/products_page.dart';
import 'products/product_form_page.dart';
import 'products/product_detail_admin.dart';
import 'orders/orders_page.dart';
import 'orders/order_detail_admin.dart';
import 'categories/categories_page.dart';
import 'vouchers/vouchers_page.dart';
import 'users/users_page.dart';
import 'users/user_detail_admin.dart';
import 'users/user_form_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final searchController = TextEditingController();
  String _getPageTitle(String route) {
    final item = adminMenuItems.firstWhere(
      (e) => e['route'] == route,
      orElse: () => {'label': 'Trang'},
    );
    return item['label'];
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      drawer: !isDesktop ? const Drawer(child: AdminSidebar()) : null,

      body: Row(
        children: [
          // ---------------------- SIDEBAR (CỘT 1) ----------------------
          if (isDesktop) const AdminSidebar(),

          // ---------------------- CỘT 2 = HEADER + CONTENT ----------------------
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER
                AdminHeader(
                  controller: searchController,
                  isDesktop: isDesktop,
                  onSearch: _triggerSearch,
                ),

                // 🔥 MOBILE ONLY: HIỂN THỊ TÊN MENU ĐANG CHỌN
                if (!isDesktop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E7F1), // hồng nhạt
                      border: Border(
                        bottom: BorderSide(color: Color.fromARGB(50, 0, 0, 0)),
                      ),
                    ),
                    child: Text(
                      _getPageTitle(admin.currentRoute),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color.fromARGB(255, 136, 79, 125),
                      ),
                    ),
                  ),

                // CONTENT
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _getPage(admin),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Load đúng page theo route
  Widget _getPage(AdminProvider admin) {
    switch (admin.currentRoute) {
      case AdminRoutes.productDetail:
        return ProductDetailAdmin(productId: admin.selectedProductId!);
      case AdminRoutes.productForm:
        return ProductFormPage(product: admin.editingProductData);
      case AdminRoutes.userDetail:
        return UserDetailAdmin(userId: admin.selectedUserId!);
      case AdminRoutes.userForm:
        return UserFormPage(user: admin.editingUser);
      case AdminRoutes.orderDetail:
        return OrderDetailAdmin(order: admin.selectedOrder!);
    }

    return adminMenuItems.firstWhere(
      (e) => e['route'] == admin.currentRoute,
    )['page'];
  }

  // Search
  // void _triggerSearch(String v) {
  //   v = v.trim().toLowerCase();
  // }
  void _triggerSearch(String query) {
    query = query.trim().toLowerCase();

    final admin = Provider.of<AdminProvider>(context, listen: false);

    if (admin.currentRoute == AdminRoutes.products &&
        ProductsPageState.instance != null) {
      ProductsPageState.instance!.filter(query);
    }

    if (admin.currentRoute == AdminRoutes.categories &&
        CategoriesPageState.instance != null) {
      CategoriesPageState.instance!.filter(query);
    }

    if (admin.currentRoute == AdminRoutes.orders &&
        OrdersPageState.instance != null) {
      OrdersPageState.instance!.filter(query);
    }

    if (admin.currentRoute == AdminRoutes.vouchers &&
        VouchersPageState.instance != null) {
      VouchersPageState.instance!.filter(query);
    }

    if (admin.currentRoute == AdminRoutes.users &&
        UsersPageState.instance != null) {
      UsersPageState.instance!.filter(query);
    }
  }
}
