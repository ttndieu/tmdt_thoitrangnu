// lib/modules/user/widgets/mall/sort_bottom_sheet.dart

import 'package:fe/modules/user/constants/app_color.dart';
import 'package:fe/modules/user/constants/app_text_styles.dart';
import 'package:fe/modules/user/models/mall_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SortBottomSheet extends StatelessWidget {
  const SortBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('Sắp xếp theo', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Options
          Consumer<MallProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  _SortOption(
                    label: 'Mới nhất',
                    icon: Icons.new_releases_outlined,
                    isSelected: provider.sortOption == SortOption.newest,
                    onTap: () {
                      provider.setSortOption(SortOption.newest);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Giá: Thấp → Cao',
                    icon: Icons.arrow_upward,
                    isSelected: provider.sortOption == SortOption.priceAsc,
                    onTap: () {
                      provider.setSortOption(SortOption.priceAsc);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Giá: Cao → Thấp',
                    icon: Icons.arrow_downward,
                    isSelected: provider.sortOption == SortOption.priceDesc,
                    onTap: () {
                      provider.setSortOption(SortOption.priceDesc);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Tên: A → Z',
                    icon: Icons.sort_by_alpha,
                    isSelected: provider.sortOption == SortOption.nameAZ,
                    onTap: () {
                      provider.setSortOption(SortOption.nameAZ);
                      Navigator.pop(context);
                    },
                  ),
                  _SortOption(
                    label: 'Tên: Z → A',
                    icon: Icons.sort_by_alpha,
                    isSelected: provider.sortOption == SortOption.nameZA,
                    onTap: () {
                      provider.setSortOption(SortOption.nameZA);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color:
                      isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}