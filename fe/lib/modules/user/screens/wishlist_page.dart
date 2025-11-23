// lib/modules/user/screens/wishlist_page.dart

import 'package:fe/modules/user/screens/product_detail_page.dart.dart';
import 'package:fe/modules/user/widgets/home/product_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../providers/wishlist_provider.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({Key? key}) : super(key: key);

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('📱 Loading wishlist...');
      await _loadData();
    });
  }

  Future<void> _loadData() async {
    await context.read<WishlistProvider>().fetchWishlist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Sản phẩm yêu thích', style: AppTextStyles.h2),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, provider, _) {
              if (provider.wishlist.isNotEmpty) {
                return TextButton(
                  onPressed: () => _showClearConfirm(context),
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(color: AppColors.error),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          if (provider.wishlist.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            color: AppColors.primary,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: provider.wishlist.length,
              itemBuilder: (context, index) {
                final product = provider.wishlist[index];
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: AppColors.textHint.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm yêu thích',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm sản phẩm vào danh sách yêu thích để xem sau',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Khám phá sản phẩm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(WishlistProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              provider.error ?? 'Unknown error',
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
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả'),
        content: const Text('Bạn có chắc muốn xóa tất cả sản phẩm yêu thích?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement clear all
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Tính năng xóa tất cả đang phát triển'),
                ),
              );
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}