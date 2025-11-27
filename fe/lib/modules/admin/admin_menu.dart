import 'package:flutter/material.dart';
import 'dashboard/dashboard_page.dart';
import 'products/products_page.dart';
import 'orders/orders_page.dart';
import 'categories/categories_page.dart';
import 'vouchers/vouchers_page.dart';
import 'users/users_page.dart';

import 'admin_routes.dart';

final List<Map<String, dynamic>> adminMenuItems = [
  {
    'route': AdminRoutes.dashboard,
    'icon': Icons.dashboard_rounded,
    'label': 'Tổng quan',
    'page': const DashboardPage(),
  },
  {
    'route': AdminRoutes.products,
    'icon': Icons.inventory_2_rounded,
    'label': 'Sản phẩm',
    'page': const ProductsPage(),
  },
  {
    'route': AdminRoutes.orders,
    'icon': Icons.receipt_long_rounded,
    'label': 'Đơn hàng',
    'page': const OrdersPage(),
  },
  {
    'route': AdminRoutes.categories,
    'icon': Icons.category_rounded,
    'label': 'Danh mục',
    'page': const CategoriesPage(),
  },
  {
    'route': AdminRoutes.vouchers,
    'icon': Icons.confirmation_num_rounded,
    'label': 'Voucher',
    'page': const VouchersPage(),
  },
  {
    'route': AdminRoutes.users,
    'icon': Icons.person_rounded,
    'label': 'Người dùng',
    'page': const UsersPage(),
  },
];
