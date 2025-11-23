// lib/modules/user/screens/checkout_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/address_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../providers/voucher_provider.dart'; 
import '../models/voucher_model.dart'; 
import '../widgets/select_address_sheet.dart';
import '../widgets/voucher_select_sheet.dart'; 
import '../screens/add_address_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'cod';
  bool _isProcessing = false;
  AddressModel? _selectedAddress;
  VoucherModel? _selectedVoucher;  // ✅ ADD
  double _discount = 0;  // ✅ ADD

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Tự động chọn địa chỉ mặc định
      final user = context.read<AuthProvider>().user;
      if (user?.defaultAddress != null) {
        setState(() {
          _selectedAddress = user!.defaultAddress;
        });
      }

      // ✅ Load vouchers
      context.read<VoucherProvider>().fetchVouchers();
    });
  }

  double _calculateTotal(CartProvider cartProvider) {
    return cartProvider.items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // ✅ SHOW VOUCHER SHEET
  void _showVoucherSheet() async {
    final cartTotal = context.read<CartProvider>().totalAmount;
    
    final result = await showModalBottomSheet<VoucherModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherSelectSheet(
        totalAmount: cartTotal,
        selectedVoucher: _selectedVoucher,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedVoucher = result;
        _discount = result.calculateDiscount(cartTotal);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Thanh toán', style: AppTextStyles.h2),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.items.isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildShippingAddress(),
                    const SizedBox(height: 16),
                    _buildOrderItems(cartProvider),
                    const SizedBox(height: 16),
                    _buildVoucherSection(),  // ✅ ADD
                    const SizedBox(height: 16),
                    _buildPaymentMethod(),
                    const SizedBox(height: 16),
                    _buildOrderSummary(cartProvider),
                  ],
                ),
              ),
              _buildBottomBar(cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text('Giỏ hàng trống', style: AppTextStyles.h2),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingAddress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Địa chỉ giao hàng', style: AppTextStyles.h3),
              const Spacer(),
              TextButton(
                onPressed: _showAddressSelection,
                child: Text(
                  _selectedAddress == null ? 'Chọn' : 'Thay đổi',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          if (_selectedAddress != null)
            _buildSelectedAddress()
          else
            _buildNoAddress(),
        ],
      ),
    );
  }

  Widget _buildSelectedAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _selectedAddress!.fullName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedAddress!.isDefault) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Mặc định',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _selectedAddress!.phone,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _selectedAddress!.fullAddress,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoAddress() {
    return Column(
      children: [
        const Text(
          'Chưa có địa chỉ giao hàng',
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddAddressPage()),
            );
            if (result == true && mounted) {
              final user = context.read<AuthProvider>().user;
              if (user?.addresses.isNotEmpty == true) {
                setState(() {
                  _selectedAddress = user!.addresses.last;
                });
              }
            }
          },
          icon: const Icon(Icons.add),
          label: const Text('Thêm địa chỉ mới'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  void _showAddressSelection() async {
    final result = await showModalBottomSheet<AddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SelectAddressSheet(
        selectedAddress: _selectedAddress,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  Widget _buildOrderItems(CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Sản phẩm (${cartProvider.itemCount})',
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const Divider(height: 20),
          ...cartProvider.items.map((item) {
            final imageUrl = item.product.imageUrl;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: AppColors.background,
                              child: const Icon(Icons.image),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: AppColors.background,
                            child: const Icon(Icons.image),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SL: ${item.quantity} | ${item.size} - ${item.color}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${item.subtotal.toStringAsFixed(0)}đ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ✅ VOUCHER SECTION
  Widget _buildVoucherSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Mã giảm giá', style: AppTextStyles.h3),
              const Spacer(),
              TextButton(
                onPressed: _showVoucherSheet,
                child: Text(
                  _selectedVoucher == null ? 'Chọn mã' : 'Thay đổi',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (_selectedVoucher != null) ...[
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedVoucher!.code,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Giảm ${_discount.toStringAsFixed(0)}đ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedVoucher = null;
                        _discount = 0;
                      });
                      context.read<VoucherProvider>().removeVoucher();
                    },
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ] else ...[
            const Divider(height: 20),
            Text(
              'Chọn hoặc nhập mã giảm giá',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Phương thức thanh toán', style: AppTextStyles.h3),
            ],
          ),
          const Divider(height: 20),
          RadioListTile<String>(
            value: 'cod',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: const Text('Thanh toán khi nhận hàng (COD)'),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'momo',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: const Text('Ví MoMo'),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'vnpay',
            groupValue: _paymentMethod,
            onChanged: (value) => setState(() => _paymentMethod = value!),
            title: const Text('VNPAY'),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ✅ ORDER SUMMARY WITH DISCOUNT
  Widget _buildOrderSummary(CartProvider cartProvider) {
    const shippingFee = 15000.0;
    final subtotal = _calculateTotal(cartProvider);
    final total = subtotal + shippingFee - _discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tạm tính', subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Phí vận chuyển', shippingFee),
          if (_discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Giảm giá', -_discount, isDiscount: true),
          ],
          const Divider(height: 20),
          _buildSummaryRow('Tổng cộng', total, isTotal: true),
        ],
      ),
    );
  }

  // ✅ SUMMARY ROW WITH DISCOUNT STYLING
  Widget _buildSummaryRow(String label, double amount, {
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.h3
              : AppTextStyles.bodyMedium.copyWith(
                  color: isDiscount ? AppColors.error : AppColors.textSecondary,
                ),
        ),
        Text(
          '${amount.abs().toStringAsFixed(0)}đ',
          style: isTotal
              ? AppTextStyles.h2.copyWith(color: AppColors.primary)
              : isDiscount
                  ? AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    )
                  : AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ✅ BOTTOM BAR WITH DISCOUNT
  Widget _buildBottomBar(CartProvider cartProvider) {
    const shippingFee = 15000.0;
    final subtotal = _calculateTotal(cartProvider);
    final total = subtotal + shippingFee - _discount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tổng thanh toán', style: AppTextStyles.bodySmall),
                  Text(
                    '${total.toStringAsFixed(0)}đ',
                    style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                  ),
                  if (_discount > 0)
                    Text(
                      'Tiết kiệm ${_discount.toStringAsFixed(0)}đ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Đặt hàng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ PLACE ORDER WITH VOUCHER
  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng chọn địa chỉ giao hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // ✅ FIX: Đổi createOrder → createOrderFromCart
      final order = await context.read<OrderProvider>().createOrderFromCart(
            paymentMethod: _paymentMethod,
            shippingAddress: _selectedAddress!.toJson(),
            voucherId: _selectedVoucher?.id,  // ✅ SEND VOUCHER ID
          );

      if (order != null && mounted) {
        await context.read<CartProvider>().clearCart();
        context.read<VoucherProvider>().removeVoucher();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrderSuccessPage(order: order)),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Đặt hàng thất bại. Vui lòng thử lại!'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('❌ Place order error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}