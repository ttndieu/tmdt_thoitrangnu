import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/product_model.dart';

class ProductGrid extends StatelessWidget {
  final List<ProductModel> products;
  final Function(ProductModel)? onProductTap;
  final Function(String)? onFavoriteTap;

  const ProductGrid({
    Key? key,
    required this.products,
    this.onProductTap,
    this.onFavoriteTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ DÙNG MediaQuery THAY VÌ LayoutBuilder
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (width > 600) crossAxisCount = 3;
    if (width > 900) crossAxisCount = 4;

    // ✅ RETURN TRỰC TIẾP SliverPadding + SliverGrid
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return ProductCard(
              product: products[index],
              onTap: () => onProductTap?.call(products[index]),
              onFavoriteTap: () => onFavoriteTap?.call(products[index].id),
            );
          },
          childCount: products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.68,
        ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const ProductCard({
    Key? key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted) setState(() => _isHovered = true);
        },
        onExit: (_) {
          if (mounted) setState(() => _isHovered = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: widget.product.mainImage != null
                          ? CachedNetworkImage(
                              imageUrl: widget.product.mainImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.beColor,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.mintPastel,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.beColor,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: AppColors.darkText,
                                  size: 40,
                                ),
                              ),
                            )
                          : Container(
                              color: AppColors.beColor,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.darkText,
                                size: 40,
                              ),
                            ),
                    ),
                    // Out of stock overlay
                    if (widget.product.totalStock == 0)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'HẾT HÀNG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Favorite button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: widget.onFavoriteTap,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.product.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: widget.product.isFavorite
                                ? Colors.red
                                : AppColors.darkText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Product info
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
        Expanded(       // 🔥 Thêm để chặn overflow ở Text
          child: Text(
            widget.product.name,
            style: AppTextStyles.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

                      const SizedBox(height: 8), 
                      // Price
                      Text(
                        '${widget.product.displayPrice}đ',
                        style: AppTextStyles.productPrice,
                      ),
                      const SizedBox(height: 4),
                      // Stock info
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: AppColors.darkText.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Còn ${widget.product.totalStock}',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.darkText.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
