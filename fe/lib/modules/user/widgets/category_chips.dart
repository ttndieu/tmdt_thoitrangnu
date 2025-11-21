import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/category_model.dart';

class CategoryChips extends StatefulWidget {
  final List<CategoryModel> categories;
  final Function(CategoryModel)? onCategorySelected;

  const CategoryChips({
    Key? key,
    required this.categories,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = widget.categories[index];
          final isSelected = _selectedCategoryId == category.id;
          
          return _CategoryChip(
            category: category,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategoryId = isSelected ? null : category.id;
              });
              if (widget.onCategorySelected != null) {
                widget.onCategorySelected!(category);
              }
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryModel category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.category,
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
          color: isSelected ? AppColors.mintPastel : AppColors.pinkPastel,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppColors.beColor.withOpacity(0.5)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.mintPastel.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_mall_outlined,
              size: 18,
              color: AppColors.darkText,
            ),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}