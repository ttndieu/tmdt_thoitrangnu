import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../models/product_model.dart';
import '../providers/review_provider.dart';
import '../widgets/review_item_widget.dart';
import '../widgets/rating_bar_widget.dart';

class ReviewsPage extends StatefulWidget {
  final ProductModel product;

  const ReviewsPage({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final ScrollController _scrollController = ScrollController();
  String _currentSort = 'newest';

  final Map<String, String> _sortOptions = {
    'newest': 'Mới nhất',
    'oldest': 'Cũ nhất',
    'highest': 'Rating cao',
    'lowest': 'Rating thấp',
  };

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadReviews() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewProvider>().fetchProductReviews(
            widget.product.id,
            sort: _currentSort,
          );
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final reviewProvider = context.read<ReviewProvider>();
      if (!reviewProvider.isLoading &&
          reviewProvider.currentPage < reviewProvider.totalPages) {
        reviewProvider.loadMore(widget.product.id);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Đánh giá sản phẩm', style: AppTextStyles.h2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildRatingOverview(),
          const Divider(height: 1, color: AppColors.border),
          _buildSortBar(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildReviewsList()),
        ],
      ),
    );
  }

Widget _buildRatingOverview() {
  // SAFE ACCESS: Check và default to 0
  final averageRating = widget.product.averageRating;
  final reviewCount = widget.product.reviewCount;
  final hasValidRating = widget.product.hasValidRating;

  return Container(
    color: AppColors.surface,
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        // Big Rating Number
        Column(
          children: [
            Text(
              averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            RatingBarWidget(
              rating: hasValidRating ? averageRating.round() : 0,
              size: 20,
              readOnly: true,
            ),
            const SizedBox(height: 4),
            Text(
              '$reviewCount đánh giá',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),

        const SizedBox(width: 32),

        // Rating Bars
        Expanded(
          child: Column(
            children: List.generate(5, (index) {
              final star = 5 - index;
              return _buildRatingBar(star);
            }),
          ),
        ),
      ],
    ),
  );
}

Widget _buildRatingBar(int star) {
  // TÍNH % THỰC TẾ TỪ REVIEWS
  final reviewProvider = context.watch<ReviewProvider>();
  final totalReviews = reviewProvider.reviews.length;
  
  if (totalReviews == 0) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$star',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                value: 0,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0 (0%)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ĐẾM SỐ REVIEW CÓ RATING = star
  final countWithRating = reviewProvider.reviews
      .where((review) => review.rating == star)
      .length;
  
  final percentage = (countWithRating / totalReviews * 100).round();

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        // ✅ SỐ SAO
        Text(
          '$star',
          style: AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        
        // ICON SAO
        const Icon(Icons.star, size: 14, color: Colors.amber),
        const SizedBox(width: 8),
        
        // PROGRESS BAR
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // SỐ LƯỢNG + %
        SizedBox(
          width: 60,
          child: Text(
            '$countWithRating ($percentage%)',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSortBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.sort, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          const Text('Sắp xếp:', style: AppTextStyles.bodyMedium),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _sortOptions.entries.map((entry) {
                  final isSelected = _currentSort == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _currentSort = entry.key);
                          context.read<ReviewProvider>().changeSortBy(
                                widget.product.id,
                                entry.key,
                              );
                        }
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        if (reviewProvider.isLoading && reviewProvider.reviews.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (reviewProvider.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 80,
                  color: AppColors.textHint.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có đánh giá nào',
                  style: AppTextStyles.h3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Hãy là người đầu tiên đánh giá sản phẩm này',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: reviewProvider.reviews.length + 1,
          itemBuilder: (context, index) {
            if (index == reviewProvider.reviews.length) {
              // Load more indicator
              if (reviewProvider.currentPage < reviewProvider.totalPages) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }
              return const SizedBox(height: 16);
            }

            final review = reviewProvider.reviews[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ReviewItemWidget(review: review),
            );
          },
        );
      },
    );
  }
}