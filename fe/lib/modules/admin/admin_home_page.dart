// lib/modules/admin/admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_routes.dart';
import 'admin_provider.dart';

// pages
import 'dashboard/dashboard_page.dart';
import 'products/products_page.dart';
import 'orders/orders_page.dart';
import 'categories/categories_page.dart';
import 'vouchers/vouchers_page.dart';
import 'products/product_detail_admin.dart';
import 'products/product_form_page.dart';

final List<Map<String, dynamic>> adminMenuItems = [
  {'route': AdminRoutes.dashboard,  'icon': Icons.dashboard_rounded,        'label': 'Tổng quan', 'page': const DashboardPage()},
  {'route': AdminRoutes.products,   'icon': Icons.inventory_2_rounded,      'label': 'Sản phẩm',  'page': const ProductsPage()},
  {'route': AdminRoutes.orders,     'icon': Icons.receipt_long_rounded,     'label': 'Đơn hàng',  'page': const OrdersPage()},
  {'route': AdminRoutes.categories, 'icon': Icons.category_rounded,         'label': 'Danh mục',  'page': const CategoriesPage()},
  {'route': AdminRoutes.vouchers,   'icon': Icons.confirmation_num_rounded, 'label': 'Voucher',   'page': const VouchersPage()},
];

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});
  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    if (!admin.isAdmin) {
      return const Scaffold(
        body: Center(child: Text("Không có quyền truy cập", style: TextStyle(fontSize: 20, color: Colors.red))),
      );
    }

    // decide current page (include product detail & product form)
    Widget currentPage;
    if (admin.currentRoute == AdminRoutes.productDetail && admin.selectedProductId != null) {
      currentPage = ProductDetailAdmin(productId: admin.selectedProductId!);
    } else if (admin.currentRoute == AdminRoutes.productForm) {
      currentPage = ProductFormPage(product: admin.editingProductData);
    } else {
      final index = adminMenuItems.indexWhere((e) => e['route'] == admin.currentRoute);
      final safeIndex = index == -1 ? 0 : index;
      currentPage = adminMenuItems[safeIndex]['page'] as Widget;
    }

    return Scaffold(
      appBar: !isDesktop ? AppBar(title: Text(_getPageTitle(admin.currentRoute))) : null,
      drawer: !isDesktop ? _buildDrawer(admin, cs) : null,
      body: Column(
        children: [
          // Header
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: cs.surface, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0,4))]),
            child: Row(
              children: [
                if (isDesktop) ...[
                  Icon(Icons.admin_panel_settings_rounded, size: 32, color: cs.primary),
                  const SizedBox(width: 12),
                  Text("Admin Salio", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(width: 40),
                ],
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: _getHintText(admin.currentRoute),
                          prefixIcon: Icon(Icons.search, color: cs.outline),
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); _triggerSearch(""); }) : null,
                        ),
                        onChanged: (v) => _triggerSearch(v.trim().toLowerCase()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                if (isDesktop)
                  Row(children: [
                    CircleAvatar(radius: 20, backgroundColor: cs.primaryContainer, child: const Icon(Icons.person, color: Colors.white)),
                    const SizedBox(width: 12),
                    Text("Admin Salio", style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(width: 16),
                    IconButton(icon: const Icon(Icons.logout_rounded), color: cs.outline, onPressed: () => admin.logout(context)),
                  ]),
              ],
            ),
          ),

          // Main
          Expanded(
            child: Row(
              children: [
                if (isDesktop)
                  Container(width: 280, color: cs.surfaceContainerLowest, child: _buildSidebar(admin, cs)),
                if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: Padding(padding: EdgeInsets.all(isDesktop ? 32 : 16), child: currentPage)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: !isDesktop ? BottomNavigationBar(
        currentIndex: _getBottomIndex(admin.currentRoute),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.outline,
        onTap: (i) { admin.changeRoute(adminMenuItems[i]['route'] as String); searchController.clear(); _triggerSearch(""); },
        items: adminMenuItems.map((e) => BottomNavigationBarItem(icon: Icon(e['icon'] as IconData), label: e['label'] as String)).toList(),
      ) : null,
    );
  }

  void _triggerSearch(String query) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    final route = admin.currentRoute;

    if (route == AdminRoutes.products && ProductsPageState.instance != null) {
      ProductsPageState.instance!.filter(query);
    } else if (route == AdminRoutes.categories && CategoriesPageState.instance != null) {
      CategoriesPageState.instance!.filter(query);
    } else if (route == AdminRoutes.orders && OrdersPageState.instance != null) {
      OrdersPageState.instance!.filter(query);
    } else if (route == AdminRoutes.vouchers && VouchersPageState.instance != null) {
      VouchersPageState.instance!.filter(query);
    }
  }

  Widget _buildSidebar(AdminProvider admin, ColorScheme cs) {
    return ListView(padding: const EdgeInsets.only(top: 20), children: adminMenuItems.map((item) {
      final selected = item['route'] == admin.currentRoute;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Icon(item['icon'] as IconData, color: selected ? cs.primary : cs.outlineVariant),
          title: Text(item['label'] as String, style: TextStyle(fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
          selected: selected,
          selectedTileColor: cs.primary.withOpacity(0.12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onTap: () { admin.changeRoute(item['route'] as String); searchController.clear(); _triggerSearch(""); },
        ),
      );
    }).toList());
  }

  Widget _buildDrawer(AdminProvider admin, ColorScheme cs) {
    return Drawer(
      child: ListView(children: [
        DrawerHeader(decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.85)])), child: const Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [CircleAvatar(radius: 32, backgroundColor: Colors.white, child: Icon(Icons.person, size: 36)), SizedBox(height: 12), Text("Admin", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))])),
        ...adminMenuItems.map((item) {
          final selected = item['route'] == admin.currentRoute;
          return ListTile(leading: Icon(item['icon'] as IconData, color: selected ? cs.primary : null), title: Text(item['label'] as String), selected: selected, selectedTileColor: cs.primary.withOpacity(0.1), onTap: () { admin.changeRoute(item['route'] as String); searchController.clear(); _triggerSearch(""); Navigator.pop(context); });
        }).toList()
      ]),
    );
  }

  int _getBottomIndex(String route) => adminMenuItems.indexWhere((e) => e['route'] == route);

  String _getPageTitle(String route) {
    final item = adminMenuItems.firstWhere((e) => e['route'] == route, orElse: () => {'label': ''});
    return item['label'] as String;
  }

  String _getHintText(String route) {
    switch (route) {
      case AdminRoutes.products: return "Tìm sản phẩm theo tên, mã...";
      case AdminRoutes.categories: return "Tìm danh mục...";
      case AdminRoutes.orders: return "Tìm đơn hàng theo mã...";
      case AdminRoutes.vouchers: return "Tìm voucher theo mã...";
      default: return "Tìm kiếm...";
    }
  }
}
