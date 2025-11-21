import 'package:flutter/material.dart';
import '../admin/admin_routes.dart';

/// Sidebar dành cho Admin
class AdminSidebar extends StatelessWidget {
  final Function(String route) onSelect;

  const AdminSidebar({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.grey[900],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawerHeader(
            child: Text(
              "Admin Panel",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
          _menuItem("Dashboard", AdminRoutes.dashboard),
          _menuItem("Products", AdminRoutes.products),
          _menuItem("Orders", AdminRoutes.orders),
          _menuItem("Categories", AdminRoutes.categories),
          _menuItem("Vouchers", AdminRoutes.vouchers),
        ],
      ),
    );
  }

  Widget _menuItem(String title, String route) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => onSelect(route),
    );
  }
}
