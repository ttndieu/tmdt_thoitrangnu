// lib/modules/user/widgets/voucher_select_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../providers/voucher_provider.dart';
import '../models/voucher_model.dart';

class VoucherSelectSheet extends StatefulWidget {
  final double totalAmount;
  final VoucherModel? selectedVoucher;

  const VoucherSelectSheet({
    Key? key,
    required this.totalAmount,
    this.selectedVoucher,
  }) : super(key: key);

  @override
  State<VoucherSelectSheet> createState() => _VoucherSelectSheetState();
}

class _VoucherSelectSheetState extends State<VoucherSelectSheet> {
  final _codeController = TextEditingController();
  bool _isApplying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VoucherProvider>().fetchVouchers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildCodeInput(),
          if (_error != null) _buildError(),
          Expanded(child: _buildVoucherList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Text('Chọn voucher', style: AppTextStyles.h2),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: 'Nhập mã voucher',
                border: InputBorder.none,
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _applyCode(),
            ),
          ),
          TextButton(
            onPressed: _isApplying ? null : _applyCode,
            child: _isApplying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherList() {
    return Consumer<VoucherProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final vouchers = provider.availableVouchers;

        if (vouchers.isEmpty) {
          return const Center(child: Text('Không có voucher khả dụng'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            final canUse = widget.totalAmount >= voucher.minOrderValue;
            final isSelected = widget.selectedVoucher?.id == voucher.id;

            return _VoucherCard(
              voucher: voucher,
              canUse: canUse,
              isSelected: isSelected,
              onTap: canUse
                  ? () async {
                      final result = await provider.applyVoucher(
                        code: voucher.code,
                        totalAmount: widget.totalAmount,
                      );
                      if (result != null && mounted) {
                        Navigator.pop(context, voucher);
                      } else {
                        setState(() {
                          _error = provider.error;
                        });
                      }
                    }
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _applyCode() async {
    if (_codeController.text.isEmpty) return;

    setState(() {
      _isApplying = true;
      _error = null;
    });

    try {
      final result = await context.read<VoucherProvider>().applyVoucher(
            code: _codeController.text.toUpperCase(),
            totalAmount: widget.totalAmount,
          );

      if (result != null && mounted) {
        Navigator.pop(context, context.read<VoucherProvider>().appliedVoucher);
      } else {
        setState(() {
          _error = context.read<VoucherProvider>().error;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }
}

class _VoucherCard extends StatelessWidget {
  final VoucherModel voucher;
  final bool canUse;
  final bool isSelected;
  final VoidCallback? onTap;

  const _VoucherCard({
    required this.voucher,
    required this.canUse,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : canUse
                  ? Colors.transparent
                  : AppColors.textHint.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canUse ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: canUse
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.textHint.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_offer,
                    color: canUse ? AppColors.primary : AppColors.textHint,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher.code,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: canUse ? null : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        voucher.discountText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: canUse ? AppColors.primary : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.conditionText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        voucher.expiryText,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColors.primary)
                else if (canUse)
                  const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}