// lib/modules/user/widgets/mall/filter_bottom_sheet.dart

import 'package:fe/modules/user/constants/app_color.dart';
import 'package:fe/modules/user/constants/app_text_styles.dart';
import 'package:fe/modules/user/models/mall_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({Key? key}) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _tempMinPrice;
  late double _tempMaxPrice;

  @override
  void initState() {
    super.initState();
    final provider = context.read<MallProvider>();
    _tempMinPrice = provider.minPrice;
    _tempMaxPrice = provider.maxPrice;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Text('Bộ lọc', style: AppTextStyles.h2),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.read<MallProvider>().clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Xóa hết',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Consumer<MallProvider>(
              builder: (context, provider, _) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Categories
                    _buildSection(
                      'Danh mục',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChip(
                            label: 'Tất cả',
                            isSelected: provider.selectedCategorySlug == null,
                            onTap: () => provider.setCategoryFilter(null),
                          ),
                          ...provider.categories.map(
                            (cat) => _FilterChip(
                              label: cat.name,
                              isSelected:
                                  provider.selectedCategorySlug == cat.slug,
                              onTap: () => provider.setCategoryFilter(cat.slug),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Price Range
                    _buildSection(
                      'Khoảng giá',
                      Column(
                        children: [
                          RangeSlider(
                            values:
                                RangeValues(_tempMinPrice, _tempMaxPrice),
                            min: 0,
                            max: 10000000,
                            divisions: 100,
                            activeColor: AppColors.primary,
                            labels: RangeLabels(
                              '${_tempMinPrice.toStringAsFixed(0)}đ',
                              '${_tempMaxPrice.toStringAsFixed(0)}đ',
                            ),
                            onChanged: (values) {
                              setState(() {
                                _tempMinPrice = values.start;
                                _tempMaxPrice = values.end;
                              });
                            },
                            onChangeEnd: (values) {
                              provider.setPriceRange(values.start, values.end);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_tempMinPrice.toStringAsFixed(0)}đ',
                                style: AppTextStyles.bodySmall,
                              ),
                              Text(
                                '${_tempMaxPrice.toStringAsFixed(0)}đ',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sizes
                    _buildSection(
                      'Kích thước',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.availableSizes
                            .map(
                              (size) => _FilterChip(
                                label: size,
                                isSelected: provider.selectedSizes.contains(size),
                                onTap: () => provider.toggleSize(size),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Colors
                    _buildSection(
                      'Màu sắc',
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.availableColors
                            .map(
                              (color) => _FilterChip(
                                label: color,
                                isSelected:
                                    provider.selectedColors.contains(color),
                                onTap: () => provider.toggleColor(color),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Consumer<MallProvider>(
                    builder: (context, provider, _) {
                      return Text(
                        'Áp dụng (${provider.products.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.h3),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.textHint,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}