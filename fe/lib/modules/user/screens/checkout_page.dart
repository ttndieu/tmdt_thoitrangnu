// lib/modules/user/screens/checkout_page.dart

import 'package:fe/modules/user/models/payment_intent_model.dart';
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
import 'vnpay_webview_page.dart';
import 'package:fe/core/utils/currency_formatter.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _paymentMethod = 'cod';
  bool _isProcessing = false;
  AddressModel? _selectedAddress;
  VoucherModel? _selectedVoucher;
  double _discount = 0;
  String? _paidIntentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user?.defaultAddress != null) {
        setState(() {
          _selectedAddress = user!.defaultAddress;
        });
      }

      context.read<VoucherProvider>().fetchVouchers();
      _checkPendingIntent();
    });
  }

  Future<void> _checkPendingIntent() async {
  final orderProvider = context.read<OrderProvider>();
  
  // ƯU TIÊN: Lấy từ provider trước
  PaymentIntentModel? intent = orderProvider.currentIntent;

  // NẾU KHÔNG CÓ: Gọi API check từ server
  if (intent == null) {
    print('No intent in provider, checking from server...');
    intent = await orderProvider.checkPendingPaidIntent();
  }

  if (intent != null && intent.isPaid && intent.paymentMethod == 'vnpay') {
    print('Found paid intent: ${intent.id}');
    setState(() {
      _paidIntentId = intent!.id;
      _paymentMethod = 'vnpay';
    });
  }
}

  double _calculateTotal(CartProvider cartProvider) {
    return cartProvider.selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void _showVoucherSheet() async {
    final cartTotal = _calculateTotal(context.read<CartProvider>());

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
              if (_paidIntentId != null) _buildPaidBanner(),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildShippingAddress(),
                    const SizedBox(height: 16),
                    _buildOrderItems(cartProvider),
                    const SizedBox(height: 16),
                    _buildVoucherSection(),
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

  Widget _buildPaidBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✅ VNPay đã thanh toán',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhấn "Đặt hàng" để hoàn tất đơn hàng',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                'Sản phẩm (${cartProvider.selectedCount})',
                style: AppTextStyles.h3,
              ),
            ],
          ),
          const Divider(height: 20),
          ...cartProvider.selectedItems.map((item) {
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
                  Text(item.subtotal.toCurrency(),
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
                  const Icon(Icons.check_circle,
                      color: AppColors.primary, size: 20),
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
                        Text('Giảm ${_discount.toCurrency()}',
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
    final isDisabled = _paidIntentId != null;

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
            onChanged: isDisabled
                ? null
                : (value) => setState(() => _paymentMethod = value!),
            title: const Text('Thanh toán khi nhận hàng (COD)'),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'vnpay',
            groupValue: _paymentMethod,
            onChanged: isDisabled
                ? null
                : (value) => setState(() => _paymentMethod = value!),
            title: const Text('VNPAY'),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ORDER SUMMARY - HIỂN THỊ CHI TIẾT TỪ INTENT KHI ĐÃ THANH TOÁN
  Widget _buildOrderSummary(CartProvider cartProvider) {
    // NẾU ĐÃ THANH TOÁN - HIỂN THỊ CHI TIẾT TỪ INTENT
    if (_paidIntentId != null) {
      final intent = context.read<OrderProvider>().currentIntent;
      
      if (intent != null) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Tạm tính', intent.originalAmount),
              const SizedBox(height: 8),
              _buildSummaryRow('Phí vận chuyển', intent.shippingFee),
              if (intent.discount > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow('Giảm giá', -intent.discount, isDiscount: true),
              ],
              const Divider(height: 20),
              _buildSummaryRow('Tổng cộng', intent.totalAmount, isTotal: true),
              const SizedBox(height: 12),
              // BOX THÔNG BÁO ĐÃ THANH TOÁN
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Đã thanh toán ${intent.totalAmount.toStringAsFixed(0)}đ qua VNPay',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    // CHƯA THANH TOÁN - HIỂN THỊ BÌNH THƯỜNG
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

  Widget _buildSummaryRow(
    String label,
    double amount, {
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
                  color:
                      isDiscount ? AppColors.error : AppColors.textSecondary,
                ),
        ),
        Text(amount.abs().toCurrency(),
          style: isTotal
              ? AppTextStyles.h2.copyWith(color: AppColors.primary)
              : isDiscount
                  ? AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    )
                  : AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // BOTTOM BAR - HIỂN THỊ 0đ KHI ĐÃ THANH TOÁN
  Widget _buildBottomBar(CartProvider cartProvider) {
    // TÍNH TOTAL
    double displayTotal;
    double? paidAmount;
    
    if (_paidIntentId != null) {
      // ĐÃ THANH TOÁN - HIỂN THỊ 0đ
      final intent = context.read<OrderProvider>().currentIntent;
      displayTotal = 0.0;  // HIỂN THỊ 0đ
      paidAmount = intent?.totalAmount;  // LƯU SỐ TIỀN ĐÃ THANH TOÁN
    } else {
      // CHƯA THANH TOÁN - TÍNH BÌNH THƯỜNG
      const shippingFee = 15000.0;
      final subtotal = _calculateTotal(cartProvider);
      displayTotal = subtotal + shippingFee - _discount;
      paidAmount = null;
    }

    String buttonLabel;
    VoidCallback? buttonAction;
    Color buttonColor;

    if (_paidIntentId != null) {
      buttonLabel = 'Đặt hàng';
      buttonAction = _placeOrder;
      buttonColor = AppColors.primary;
    } else if (_paymentMethod == 'vnpay') {
      buttonLabel = 'Thanh toán VNPay';
      buttonAction = _payVNPay;
      buttonColor = Colors.blue;
    } else {
      buttonLabel = 'Đặt hàng';
      buttonAction = _placeOrder;
      buttonColor = AppColors.primary;
    }

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
                  Text(
                    _paidIntentId != null ? 'Đã thanh toán' : 'Tổng thanh toán',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(displayTotal.toCurrency(),  
                    style: AppTextStyles.h2.copyWith(
                      color: _paidIntentId != null ? Colors.green : AppColors.primary,
                    ),
                  ),
                  // HIỂN THỊ SỐ TIỀN ĐÃ THANH TOÁN
                  if (paidAmount != null)
                    Text(
                      'Đã thanh toán ${paidAmount.toCurrency()} qua VNPay',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (_discount > 0)
                    Text(
                      'Tiết kiệm ${_discount.toCurrency()}',
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
                onPressed: (_isProcessing || cartProvider.selectedCount == 0)
                    ? null
                    : buttonAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
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
                    : Text(
                        buttonLabel,
                        style: const TextStyle(
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

  Future<void> _payVNPay() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa chỉ giao hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final selectedItemIds =
          cartProvider.selectedItems.map((item) => item.id).toList();

      final intent = await context.read<OrderProvider>().createPaymentIntent(
            paymentMethod: 'vnpay',
            shippingAddress: _selectedAddress!.toJson(),
            voucherId: _selectedVoucher?.id,
            selectedItemIds: selectedItemIds,
          );

      if (intent == null) {
        throw Exception('Không thể tạo payment intent');
      }

      final paymentResponse = await context
          .read<OrderProvider>()
          .createVNPayPaymentFromIntent(intentId: intent.id);

      if (!paymentResponse.success || paymentResponse.paymentUrl == null) {
        throw Exception(
            paymentResponse.message ?? 'Không thể tạo link thanh toán');
      }
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VNPayWebViewPage(
              paymentUrl: paymentResponse.paymentUrl!,
              intentId: intent.id,
            ),
          ),
        );

        if (result == true && mounted) {

          final updatedIntent = await context
              .read<OrderProvider>()
              .getPaymentIntent(intent.id);

          if (updatedIntent != null && updatedIntent.isPaid) {
            setState(() {
              _paidIntentId = updatedIntent.id;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    '✅ Thanh toán thành công! Nhấn "Đặt hàng" để hoàn tất.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else if (result == false && mounted) {
          print('Payment failed');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Thanh toán thất bại. Vui lòng thử lại.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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

    final cartProvider = context.read<CartProvider>();
    if (cartProvider.selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vui lòng chọn ít nhất 1 sản phẩm'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final selectedItemIds =
          cartProvider.selectedItems.map((item) => item.id).toList();

      if (_paidIntentId != null) {

        final order = await context
            .read<OrderProvider>()
            .createOrderFromIntent(intentId: _paidIntentId!);

        if (order == null) {
          throw Exception('Không thể tạo đơn hàng');
        }

        if (mounted) {
          await context.read<CartProvider>().fetchCart();
          context.read<VoucherProvider>().removeVoucher();
          context.read<OrderProvider>().clearIntent();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(order: order),
            ),
          );
        }
        return;
      }

      if (_paymentMethod == 'cod') {

        final order = await context.read<OrderProvider>().createOrderFromCart(
              paymentMethod: 'cod',
              shippingAddress: _selectedAddress!.toJson(),
              voucherId: _selectedVoucher?.id,
              selectedItemIds: selectedItemIds,
            );

        if (order == null) {
          throw Exception('Không thể tạo đơn hàng');
        }

        if (mounted) {
          await context.read<CartProvider>().fetchCart();
          context.read<VoucherProvider>().removeVoucher();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(order: order),
            ),
          );
        }
        return;
      }

      throw Exception('Vui lòng thanh toán VNPay trước');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
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