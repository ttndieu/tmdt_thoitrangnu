import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_routes.dart';
import 'admin_widgets.dart';
import 'admin_provider.dart';

import 'dashboard/dashboard_page.dart';
import 'products/products_page.dart';
import 'orders/orders_page.dart';
import 'categories/categories_page.dart';
import 'vouchers/vouchers_page.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    // CHẶN USER THƯỜNG
    if (!admin.isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Bạn không có quyền truy cập trang Admin",
            style: TextStyle(color: Colors.red, fontSize: 18),
          ),
        ),
      );
    }

    // CHỌN PAGE THEO ROUTE HIỆN TẠI
    final Widget body = switch (admin.currentRoute) {
      AdminRoutes.dashboard => const DashboardPage(),
      AdminRoutes.products => const ProductsPage(),
      AdminRoutes.orders => const OrdersPage(),
      AdminRoutes.categories => const CategoriesPage(),
      AdminRoutes.vouchers => const VouchersPage(),
      _ => const DashboardPage(),
    };

    return Scaffold(
      body: Row(
        children: [
          AdminSidebar(onSelect: (route) => admin.changeRoute(route)),
          Expanded(child: body),
        ],
      ),
    );
  }
}
