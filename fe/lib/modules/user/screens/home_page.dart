import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/voucher_slider.dart';
import '../widgets/category_chips.dart';
import '../widgets/product_grid.dart';
import '../widgets/custom_bottom_nav.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadHomeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainBackground,
      appBar: CustomAppBar(
        cartItemCount: 0,
        hasNewMessage: false,
        onCartTap: () => debugPrint('Navigate to cart'),
        onMessageTap: () => debugPrint('Navigate to messages'),
        onSearchChanged: (keyword) {
          context.read<HomeProvider>().searchProducts(keyword);
        },
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          return RefreshIndicator(
            onRefresh: () => homeProvider.loadHomeData(),
            child: CustomScrollView(
              slivers: [
                if (homeProvider.error != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: 12),
                          Expanded(child: Text(homeProvider.error!, style: const TextStyle(color: AppColors.error))),
                          IconButton(
                            onPressed: () => homeProvider.clearError(),
                            icon: const Icon(Icons.close, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: homeProvider.isLoadingVouchers
                      ? _buildLoadingVouchers()
                      : VoucherSlider(
                          vouchers: homeProvider.availableVouchers,
                          onSeeAllTap: () => debugPrint('Navigate to vouchers'),
                          onVoucherTap: (voucher) => _showVoucherDetail(voucher),
                        ),
                ),

                SliverToBoxAdapter(
                  child: homeProvider.isLoadingCategories
                      ? _buildLoadingCategories()
                      : CategoryChips(
                          categories: homeProvider.categories,
                          onCategorySelected: (category) {
                            homeProvider.filterByCategory(category.slug);
                          },
                        ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sản phẩm bán chạy', style: AppTextStyles.sectionTitle),
                        GestureDetector(
                          onTap: () => debugPrint('Navigate to all products'),
                          child: const Text(
                            'Xem thêm',
                            style: TextStyle(color: AppColors.priceGreen, fontSize: 14, decoration: TextDecoration.none),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (homeProvider.isLoadingProducts)
                  SliverToBoxAdapter(child: _buildLoadingProducts())
                else if (homeProvider.products.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Không có sản phẩm nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ProductGrid(
                    products: homeProvider.products,
                    onProductTap: (product) => debugPrint('Product tapped: ${product.name}'),
                    onFavoriteTap: (productId) => homeProvider.toggleFavorite(productId),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          _handleNavigation(index);
        },
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: break;
      case 1: debugPrint('Navigate to Mall'); break;
      case 2: debugPrint('Navigate to Notifications'); break;
      case 3: debugPrint('Navigate to Profile'); break;
    }
  }

  void _showVoucherDetail(voucher) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(voucher.title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(voucher.displayDescription),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mintPastel.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(voucher.code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2)),
                  IconButton(onPressed: () => debugPrint('Copy code: ${voucher.code}'), icon: const Icon(Icons.copy)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.priceGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sử dụng ngay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingVouchers() => const SizedBox(height: 170, child: Center(child: CircularProgressIndicator()));
  Widget _buildLoadingCategories() => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()));
  Widget _buildLoadingProducts() => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
}
