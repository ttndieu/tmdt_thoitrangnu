// lib/modules/user/screens/order_detail_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';       
import '../providers/order_provider.dart';  
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrderDetail();
  }

  Future<void> _loadOrderDetail() async {
    final provider = context.read<OrderProvider>();
    final order = provider.orders.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => provider.orders.first,
    );

    setState(() {
      _order = order;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Chi tiết đơn hàng', style: AppTextStyles.h2),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _order == null
              ? _buildErrorState()
              : _buildOrderDetail(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          const Text('Không tìm thấy đơn hàng', style: AppTextStyles.h3),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Quay lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusSection(),
        const SizedBox(height: 16),
        _buildOrderInfo(),
        const SizedBox(height: 16),
        _buildShippingAddress(),
        const SizedBox(height: 16),
        _buildOrderItems(),
        const SizedBox(height: 16),
        _buildPaymentSummary(),
        
        // ✅ THÊM NÚT HỦY ĐƠN (CHỈ HIỆN KHI STATUS = PENDING)
        if (_order!.status == 'pending') ...[
          const SizedBox(height: 24),
          _buildCancelButton(),
        ],
      ],
    );
  }

  Widget _buildStatusSection() {
    Color statusColor;
    IconData statusIcon;

    switch (_order!.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'shipping':
        statusColor = Colors.purple;
        statusIcon = Icons.local_shipping;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withOpacity(0.1), statusColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _order!.statusText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatusDescription(_order!.status),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin đơn hàng', style: AppTextStyles.h3),
          const Divider(height: 20),
          _buildInfoRow('Mã đơn hàng', _order!.orderNumber),
          const SizedBox(height: 12),
          _buildInfoRow('Ngày đặt', _order!.formattedDate),
          const SizedBox(height: 12),
          _buildInfoRow('Phương thức thanh toán', _getPaymentMethodName(_order!.paymentMethod)),
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
          const Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Địa chỉ giao hàng', style: AppTextStyles.h3),
            ],
          ),
          const Divider(height: 20),
          if (_order!.shippingAddress.fullName.isNotEmpty) ...[
            Text(
              _order!.shippingAddress.fullName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (_order!.shippingAddress.phone.isNotEmpty) ...[
            Text(
              _order!.shippingAddress.phone,
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            _order!.shippingAddress.fullAddress,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sản phẩm (${_order!.items.length})',
            style: AppTextStyles.h3,
          ),
          const Divider(height: 20),
          ..._order!.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 80,
                                height: 80,
                                color: AppColors.background,
                                child: const Icon(Icons.image),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
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
                            item.productName,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 4),
                          if (item.size.isNotEmpty || item.color.isNotEmpty)
                            Text(
                              '${item.size} ${item.color}'.trim(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            'x${item.quantity}',
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
              )),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final originalAmount = _order!.originalAmount ?? _order!.totalAmount;
    final discount = _order!.discount ?? 0.0;
    const shippingFee = 15000.0;
    final finalTotal = _order!.totalAmount + shippingFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chi tiết thanh toán', style: AppTextStyles.h3),
          const Divider(height: 20),
          
          _buildSummaryRow('Tổng tiền hàng', originalAmount),
          
          if (_order!.hasVoucher) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.local_offer,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Mã giảm giá',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _order!.voucherCode!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '-${discount.toStringAsFixed(0)}đ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          _buildSummaryRow('Phí vận chuyển', shippingFee),
          
          const Divider(height: 20),
          
          _buildSummaryRow(
            'Tổng thanh toán',
            finalTotal,
            isTotal: true,
          ),
          
          if (_order!.hasVoucher) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Đã tiết kiệm ${discount.toStringAsFixed(0)}đ với mã ${_order!.voucherCode}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4CAF50),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ✅ NÚT HỦY ĐƠN HÀNG
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelConfirmDialog(),
        icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
        label: const Text(
          'Hủy đơn hàng',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: AppColors.error, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // ✅ DIALOG XÁC NHẬN HỦY
  Future<void> _showCancelConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Xác nhận hủy đơn hàng',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này không?',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            
            // ✅ HIỂN THỊ THÔNG BÁO HOÀN VOUCHER
            if (_order!.hasVoucher) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã giảm giá ${_order!.voucherCode} sẽ được hoàn lại và bạn có thể sử dụng lại',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Không',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelOrder();
    }
  }

  // ✅ FUNCTION GỌI API HỦY ĐƠN
  Future<void> _cancelOrder() async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );

      final provider = context.read<OrderProvider>();
      final success = await provider.cancelOrder(widget.orderId);

      // Đóng loading
      if (mounted) Navigator.pop(context);

      if (success) {
        // Reload order detail
        await _loadOrderDetail();

        // Hiển thị thông báo thành công
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _order!.hasVoucher
                          ? '✅ Đã hủy đơn hàng thành công. Mã ${_order!.voucherCode} đã được hoàn lại'
                          : '✅ Đã hủy đơn hàng thành công',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      // Đóng loading
      if (mounted) Navigator.pop(context);

      // Hiển thị lỗi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(e.toString()),
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.h3
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          '${amount.toStringAsFixed(0)}đ',
          style: isTotal
              ? AppTextStyles.h2.copyWith(color: AppColors.primary)
              : AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
        ),
      ],
    );
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'pending':
        return 'Đơn hàng đang chờ xác nhận';
      case 'confirmed':
        return 'Đơn hàng đã được xác nhận';
      case 'shipping':
        return 'Đơn hàng đang được giao';
      case 'completed':
        return 'Đơn hàng đã hoàn thành';
      case 'cancelled':
        return 'Đơn hàng đã bị hủy';
      default:
        return '';
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'cod':
        return 'Thanh toán khi nhận hàng';
      case 'momo':
        return 'Ví MoMo';
      case 'vnpay':
        return 'VNPAY';
      default:
        return method;
    }
  }
}