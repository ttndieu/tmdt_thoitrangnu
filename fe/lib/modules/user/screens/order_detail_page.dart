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
          // ✅ FIX: fullName là non-nullable String
          if (_order!.shippingAddress.fullName.isNotEmpty) ...[
            Text(
              _order!.shippingAddress.fullName,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          // ✅ FIX: phone là non-nullable String
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
                      // ✅ FIX: Dùng imageUrl thay vì productImage
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
                          // ✅ FIX: size và color là non-nullable String
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Tổng tiền hàng', _order!.totalAmount),
          const SizedBox(height: 8),
          _buildSummaryRow('Phí vận chuyển', 30000),
          const Divider(height: 20),
          _buildSummaryRow(
            'Tổng thanh toán',
            _order!.totalAmount + 30000,
            isTotal: true,
          ),
        ],
      ),
    );
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