// lib/modules/user/screens/mall_page.dart

import 'package:fe/modules/user/screens/product_detail_page.dart.dart';
import 'package:fe/modules/user/widgets/home/product_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../models/mall_provider.dart';
import '../widgets/home/home_app_bar.dart'; 
import '../widgets/mall/filter_bottom_sheet.dart';
import '../widgets/mall/sort_bottom_sheet.dart';
import '../../auth/providers/auth_provider.dart'; 
import '../providers/cart_provider.dart'; 
import 'cart_page.dart'; 

class MallPage extends StatefulWidget {
  const MallPage({Key? key}) : super(key: key);

  @override
  State<MallPage> createState() => _MallPageState();
}

class _MallPageState extends State<MallPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      context.read<CartProvider>().fetchCart(); // ✅ THÊM
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final provider = context.read<MallProvider>();
    await provider.refresh();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MallProvider>(),
        child: const FilterBottomSheet(),
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<MallProvider>(),
        child: const SortBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // ✅ THÊM: Get userName
    final authProvider = context.watch<AuthProvider>();
    final userName = authProvider.user?.name ?? 'Khách';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<MallProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                // ✅ THÊM: HomeAppBar với cart & notifications
                Consumer<CartProvider>(
                  builder: (context, cartProvider, _) {
                    return HomeAppBar(
                      userName: userName,
                      cartCount: cartProvider.itemCount,
                      notificationCount: 0,
                      onCartTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CartPage(),
                          ),
                        );
                      },
                      onNotificationTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🔔 Tính năng thông báo đang phát triển'),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Search Bar
                _buildSearchBar(provider),

                // Filter & Sort Bar
                _buildFilterSortBar(provider),

                // Products Grid
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadData();
                      await context.read<CartProvider>().fetchCart();
                    },
                    color: AppColors.primary,
                    child: _buildProductsGrid(provider),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(MallProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textHint, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: provider.search,
                decoration: const InputDecoration(
                  hintText: 'Tìm kiếm trong cửa hàng...',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (provider.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  _searchController.clear();
                  provider.search('');
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSortBar(MallProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: Icons.filter_list,
              label: 'Bộ lọc',
              hasIndicator: provider.hasActiveFilters,
              onTap: _showFilterBottomSheet,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: Icons.sort,
              label: provider.sortLabel,
              onTap: _showSortBottomSheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(MallProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (provider.error != null) {
      return _buildErrorState(provider);
    }

    if (provider.products.isEmpty) {
      return _buildEmptyState(provider);
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.products.length,
      itemBuilder: (context, index) {
        final product = provider.products[index];
        return ProductCard(
          product: product,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(MallProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text('Có lỗi xảy ra', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            provider.error!,
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(MallProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy sản phẩm',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử điều chỉnh bộ lọc hoặc tìm kiếm khác',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (provider.hasActiveFilters)
            TextButton.icon(
              onPressed: () {
                provider.clearFilters();
                _searchController.clear();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Xóa tất cả bộ lọc'),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool hasIndicator;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.hasIndicator = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                Icon(icon, size: 20, color: AppColors.textPrimary),
                if (hasIndicator)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}