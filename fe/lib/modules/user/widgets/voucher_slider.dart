import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/voucher_model.dart';

class VoucherSlider extends StatelessWidget {
  final List<VoucherModel> vouchers;
  final VoidCallback? onSeeAllTap;
  final Function(VoucherModel)? onVoucherTap;

  const VoucherSlider({
    Key? key,
    required this.vouchers,
    this.onSeeAllTap,
    this.onVoucherTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (vouchers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ưu đãi hot 🔥', style: AppTextStyles.sectionTitle),
              if (onSeeAllTap != null)
                GestureDetector(
                  onTap: onSeeAllTap,
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: vouchers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _VoucherCard(
                voucher: vouchers[index],
                onTap: () => onVoucherTap?.call(vouchers[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final VoidCallback? onTap;

  const _VoucherCard({
    required this.voucher,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [AppColors.pinkPastel, AppColors.mintPastel],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.card_giftcard,
              size: 48,
              color: AppColors.darkText,
            ),
            const SizedBox(height: 12),
            Text(
              voucher.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              voucher.displayDescription,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.darkText,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.darkText.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voucher.code,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.darkText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.content_copy,
                    size: 14,
                    color: AppColors.darkText.withOpacity(0.6),
                  ),
                ],
              ),
            ),
            if (voucher.quantity < 10) ...[
              const SizedBox(height: 8),
              Text(
                '⚡ Chỉ còn ${voucher.quantity} mã',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}