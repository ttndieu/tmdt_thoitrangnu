// lib/modules/user/screens/product_detail_page.dart

import 'package:fe/modules/user/providers/cart_provider.dart';
import 'package:fe/modules/user/screens/cart_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../models/product_model.dart';
import '../providers/wishlist_provider.dart';

class ProductDetailPage extends StatefulWidget {
  final ProductModel product;

  const ProductDetailPage({Key? key, required this.product}) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _currentImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    // Set default selections
    if (widget.product.variants.isNotEmpty) {
      final firstVariant = widget.product.variants.first;
      _selectedSize = firstVariant.size;
      _selectedColor = firstVariant.color;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ProductVariant? get _selectedVariant {
    if (_selectedSize == null || _selectedColor == null) return null;
    
    try {
      return widget.product.variants.firstWhere(
        (v) => v.size == _selectedSize && v.color == _selectedColor,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfo(),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                _buildSizeSelector(),
                const SizedBox(height: 16),
                _buildColorSelector(),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                _buildQuantitySelector(),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                _buildDescription(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 20),
        ),
      ),
      actions: [
        Consumer<WishlistProvider>(
          builder: (context, wishlistProvider, _) {
            final isWishlisted = wishlistProvider.isWishlisted(widget.product.id);
            
            return IconButton(
              onPressed: () async {
                final success = await wishlistProvider.toggleWishlist(widget.product.id);
                if (mounted && success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isWishlisted 
                          ? '❤️ Đã xóa khỏi yêu thích' 
                          : '💝 Đã thêm vào yêu thích',
                      ),
                      duration: const Duration(seconds: 1),
                      backgroundColor: isWishlisted ? AppColors.error : Colors.green,
                    ),
                  );
                }
              },
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted ? AppColors.wishlistActive : AppColors.textPrimary,
                  size: 20,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.product.images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                return Image.network(
                  widget.product.images[index].url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.background,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 64),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.product.images.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentImageIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentImageIndex == index
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.product.category?.name ?? 'Sản phẩm',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.product.name, style: AppTextStyles.h1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_selectedVariant != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedVariant!.price.toStringAsFixed(0)}đ',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.primary,
                        fontSize: 28,
                      ),
                    ),
                    if (_quantity > 1)
                      Text(
                        'Tổng: ${(_selectedVariant!.price * _quantity).toStringAsFixed(0)}đ',
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                )
              else
                Text(
                  'Chọn phân loại',
                  style: AppTextStyles.h3.copyWith(color: AppColors.textHint),
                ),
              if (_selectedVariant != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedVariant!.stock > 0 
                      ? Colors.green.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedVariant!.stock > 0 ? Icons.check_circle : Icons.error,
                        size: 16,
                        color: _selectedVariant!.stock > 0 ? Colors.green : AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedVariant!.stock > 0
                            ? 'Còn ${_selectedVariant!.stock}'
                            : 'Hết hàng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: _selectedVariant!.stock > 0 ? Colors.green : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSelector() {
    final sizes = widget.product.variants.map((v) => v.size).toSet().toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kích thước', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sizes.map((size) {
              final isSelected = _selectedSize == size;
              final hasStock = widget.product.variants
                  .any((v) => v.size == size && v.stock > 0);
              
              return InkWell(
                onTap: hasStock ? () {
                  setState(() {
                    _selectedSize = size;
                    final availableColors = widget.product.variants
                        .where((v) => v.size == size)
                        .map((v) => v.color)
                        .toSet();
                    if (_selectedColor != null && 
                        !availableColors.contains(_selectedColor)) {
                      _selectedColor = availableColors.first;
                    }
                  });
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    size,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSelector() {
    final colors = widget.product.variants
        .where((v) => v.size == _selectedSize)
        .map((v) => v.color)
        .toSet()
        .toList();

    if (colors.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Màu sắc', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((color) {
              final isSelected = _selectedColor == color;
              
              return InkWell(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    color,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySelector() {
    final maxStock = _selectedVariant?.stock ?? 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Số lượng', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuantityButton(
                icon: Icons.remove,
                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_quantity', style: AppTextStyles.h2),
              ),
              _buildQuantityButton(
                icon: Icons.add,
                onTap: _quantity < maxStock ? () => setState(() => _quantity++) : null,
              ),
              const SizedBox(width: 12),
              if (maxStock > 0)
                Text(
                  'Tối đa: $maxStock',
                  style: AppTextStyles.bodySmall,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mô tả sản phẩm', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final canAddToCart = _selectedVariant != null && 
                         _selectedVariant!.stock >= _quantity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_selectedVariant != null)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng tiền', style: AppTextStyles.bodySmall),
                    Text(
                      '${(_selectedVariant!.price * _quantity).toStringAsFixed(0)}đ',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canAddToCart ? _addToCart : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAddToCart ? AppColors.primary : AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                label: const Text(
                  'Thêm vào giỏ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToCart() async {
  if (_selectedVariant == null || _selectedSize == null || _selectedColor == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚠️ Vui lòng chọn kích thước và màu sắc'),
        backgroundColor: AppColors.error,
      ),
    );
    return;
  }

  final cartProvider = context.read<CartProvider>();
  
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    ),
  );

  // Add to cart với size & color
  final success = await cartProvider.addToCart(
    productId: widget.product.id,
    size: _selectedSize!,
    color: _selectedColor!,
    quantity: _quantity,
  );

  // Close loading dialog
  if (mounted) Navigator.pop(context);

  // Show result
  if (mounted) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '🛒 Đã thêm $_quantity x ${widget.product.name} ($_selectedSize - $_selectedColor)',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('❌ Không thể thêm vào giỏ hàng'),
            ],
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
}