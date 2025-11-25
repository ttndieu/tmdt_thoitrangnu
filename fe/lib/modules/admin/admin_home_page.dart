// lib/modules/admin/admin_home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin_routes.dart';
import 'admin_provider.dart';

// confirm dialog
import 'common/common_confirm.dart';

// pages
import 'dashboard/dashboard_page.dart';
import 'products/products_page.dart';
import 'orders/orders_page.dart';
import 'categories/categories_page.dart';
import 'vouchers/vouchers_page.dart';
import 'products/product_detail_admin.dart';
import 'products/product_form_page.dart';
import 'users/users_page.dart';
import 'users/user_detail_admin.dart';
import 'users/user_form_page.dart';

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
        body: Center(
          child: Text(
            "Không có quyền truy cập",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
    }

    // decide current page (include product detail & product form)
    Widget currentPage;

    if (admin.currentRoute == AdminRoutes.productDetail &&
        admin.selectedProductId != null) {
      currentPage = ProductDetailAdmin(productId: admin.selectedProductId!);
    } else if (admin.currentRoute == AdminRoutes.productForm) {
      currentPage = ProductFormPage(product: admin.editingProductData);
    } else if (admin.currentRoute == AdminRoutes.userDetail &&
        admin.selectedUserId != null) {
      currentPage = UserDetailAdmin(userId: admin.selectedUserId!);
    } else if (admin.currentRoute == AdminRoutes.userForm) {
      currentPage = UserFormPage(user: admin.editingUser);
    } else {
      final index = adminMenuItems.indexWhere(
        (e) => e['route'] == admin.currentRoute,
      );
      final safeIndex = index == -1 ? 0 : index;
      currentPage = adminMenuItems[safeIndex]['page'] as Widget;
    }

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(title: Text(_getPageTitle(admin.currentRoute)))
          : null,
      drawer: !isDesktop ? _buildDrawer(admin, cs) : null,
      body: Column(
        children: [
          // Header (GIỮ NGUYÊN, CÓ THANH TÌM KIẾM)
          _buildHeader(context, admin, cs, isDesktop),

          // Main
          Expanded(
            child: Row(
              children: [
                if (isDesktop)
                  Container(
                    width: 280,
                    color: cs.surfaceContainerLowest,
                    child: Column(
                      children: [
                        Expanded(
                          child: _buildSidebar(admin, cs),
                        ),

                        // --- LOGOUT Ở CUỐI SIDEBAR ---
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            leading: const Icon(Icons.logout_rounded,
                                color: Colors.red),
                            title: const Text(
                              "Đăng xuất",
                              style: TextStyle(color: Colors.red),
                            ),
                            onTap: () async {
                              final ok = await showConfirmDialog(
                                context,
                                title: "Đăng xuất",
                                message: "Bạn có chắc muốn đăng xuất?",
                              );
                              if (ok) admin.logout(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                if (isDesktop) const VerticalDivider(thickness: 1, width: 1),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: currentPage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ------------------- BOTTOM NAVIGATION (mobile) -------------------
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _getBottomIndex(admin.currentRoute),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: cs.primary,
              unselectedItemColor: cs.outline,
              onTap: (i) {
                admin.changeRoute(adminMenuItems[i]['route'] as String);
                searchController.clear();
                _triggerSearch("");
              },
              items: adminMenuItems.map((e) {
                final selected = e['route'] == admin.currentRoute;
                return BottomNavigationBarItem(
                  icon: Icon(e['icon']),
                  // chỉ mục đang chọn được hiển thị chữ
                  label: selected ? e['label'] : "",
                );
              }).toList(),
            )
          : null,
    );
  }

  // ------------------------------------------------------------------
  // HEADER (có thanh tìm kiếm) — GIỮ NGUYÊN
  // ------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, AdminProvider admin,
      ColorScheme cs, bool isDesktop) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isDesktop) ...[
            Icon(Icons.admin_panel_settings_rounded,
                size: 32, color: cs.primary),
            const SizedBox(width: 12),
            Text(
              "Admin Salio",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              _triggerSearch("");
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) =>
                      _triggerSearch(v.trim().toLowerCase()),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          if (isDesktop)
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: cs.primaryContainer,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Text("Admin Salio"),
                const SizedBox(width: 16),
              ],
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SIDEBAR (desktop)
  // ------------------------------------------------------------------
  Widget _buildSidebar(AdminProvider admin, ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.only(top: 20),
      children: adminMenuItems.map((item) {
        final selected = item['route'] == admin.currentRoute;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: Icon(
              item['icon'],
              color: selected ? cs.primary : cs.outlineVariant,
            ),
            title: Text(
              item['label'],
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: selected,
            selectedTileColor: cs.primary.withOpacity(0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onTap: () {
              admin.changeRoute(item['route']);
              searchController.clear();
              _triggerSearch("");
            },
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------------
  // MOBILE DRAWER (không đổi)
  // ------------------------------------------------------------------
  Widget _buildDrawer(AdminProvider admin, ColorScheme cs) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary, cs.primary.withOpacity(0.85)],
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                "Admin",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ...adminMenuItems.map((item) {
            final selected = item['route'] == admin.currentRoute;
            return ListTile(
              leading: Icon(
                item['icon'],
                color: selected ? cs.primary : null,
              ),
              title: Text(item['label']),
              selected: selected,
              selectedTileColor: cs.primary.withOpacity(0.1),
              onTap: () {
                admin.changeRoute(item['route']);
                searchController.clear();
                _triggerSearch("");
                Navigator.pop(context);
              },
            );
          }),

          const Divider(),

          // --- LOGOUT MOBILE ---
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text("Đăng xuất", style: TextStyle(color: Colors.red)),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                title: "Đăng xuất",
                message: "Bạn có chắc muốn đăng xuất?",
              );
              if (ok) admin.logout(context);
            },
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SEARCH LOGIC
  // ------------------------------------------------------------------
  void _triggerSearch(String query) {
    final admin = Provider.of<AdminProvider>(context, listen: false);

    if (admin.currentRoute == AdminRoutes.products &&
        ProductsPageState.instance != null) {
      ProductsPageState.instance!.filter(query);
    } else if (admin.currentRoute == AdminRoutes.categories &&
        CategoriesPageState.instance != null) {
      CategoriesPageState.instance!.filter(query);
    } else if (admin.currentRoute == AdminRoutes.orders &&
        OrdersPageState.instance != null) {
      OrdersPageState.instance!.filter(query);
    } else if (admin.currentRoute == AdminRoutes.vouchers &&
        VouchersPageState.instance != null) {
      VouchersPageState.instance!.filter(query);
    } else if (admin.currentRoute == AdminRoutes.users &&
        UsersPageState.instance != null) {
      UsersPageState.instance!.filter(query);
    }
  }

  int _getBottomIndex(String route) =>
      adminMenuItems.indexWhere((e) => e['route'] == route);

  String _getPageTitle(String route) {
    return adminMenuItems
        .firstWhere((e) => e['route'] == route)['label'];
  }

  String _getHintText(String route) {
    switch (route) {
      case AdminRoutes.products:
        return "Tìm sản phẩm...";
      case AdminRoutes.categories:
        return "Tìm danh mục...";
      case AdminRoutes.orders:
        return "Tìm đơn hàng...";
      case AdminRoutes.vouchers:
        return "Tìm voucher...";
      default:
        return "Tìm kiếm...";
    }
  }
}
