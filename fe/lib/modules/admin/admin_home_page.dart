// lib/modules/admin/admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_provider.dart';
import 'admin_routes.dart';
import 'admin_menu.dart';

import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_bottom_bar.dart';

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
      bottomNavigationBar: !isDesktop ? const AdminBottomBar() : null,

      body: Row(
        children: [
          if (isDesktop) const AdminSidebar(),

          Expanded(
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: AdminHeader(
                    controller: searchController,
                    isDesktop: isDesktop,
                    onSearch: _triggerSearch,
                  ),
                ),

                if (!isDesktop)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _getPageTitle(admin.currentRoute),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF874A7A),
                      ),
                    ),
                  ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: KeyedSubtree(
                      key: ValueKey(admin.currentRoute),
                      child: _getPage(admin),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

    return adminMenuItems
        .firstWhere((e) => e['route'] == admin.currentRoute)['page'];
  }

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
