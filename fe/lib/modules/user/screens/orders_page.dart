// lib/modules/user/screens/orders_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../providers/order_provider.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // ✅ Load orders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    await context.read<OrderProvider>().fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('Đơn hàng của tôi', style: AppTextStyles.h2),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Chờ xác nhận'),
            Tab(text: 'Đang giao'),
            Tab(text: 'Hoàn thành'),
            Tab(text: 'Đã hủy'),
          ],
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrderList(provider, 'all'),
              _buildOrderList(provider, 'pending'),
              _buildOrderList(provider, 'shipping'),
              _buildOrderList(provider, 'completed'),
              _buildOrderList(provider, 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOrderList(OrderProvider provider, String status) {
    final orders = provider.getOrdersByStatus(status);

    if (orders.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _OrderCard(
            orderNumber: order.orderNumber,
            date: order.formattedDate,
            status: order.status,
            itemCount: order.itemCount,
            total: order.totalAmount,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailPage(orderId: order.id),
                ),
              );
            },
            onCancel: order.status == 'pending'
                ? () => _cancelOrder(order.id)
                : null,
          );
        },
      ),
    );
  }

  Future<void> _cancelOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Hủy đơn',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await context.read<OrderProvider>().cancelOrder(orderId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '✅ Đã hủy đơn hàng' : '❌ Không thể hủy đơn hàng'),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'pending':
        message = 'Chưa có đơn hàng chờ xác nhận';
        icon = Icons.hourglass_empty;
        break;
      case 'shipping':
        message = 'Chưa có đơn hàng đang giao';
        icon = Icons.local_shipping_outlined;
        break;
      case 'completed':
        message = 'Chưa có đơn hàng hoàn thành';
        icon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        message = 'Chưa có đơn hàng bị hủy';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Bạn chưa có đơn hàng nào';
        icon = Icons.shopping_bag_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy bắt đầu mua sắm ngay!',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Mua sắm ngay'),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String orderNumber;
  final String date;
  final String status;
  final int itemCount;
  final double total;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.orderNumber,
    required this.date,
    required this.status,
    required this.itemCount,
    required this.total,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    orderNumber,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                date,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Divider(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số lượng',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount sản phẩm',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Tổng tiền',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${total.toStringAsFixed(0)}đ',
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (status == 'pending')
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (onCancel != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              foregroundColor: AppColors.error,
                            ),
                            child: const Text('Hủy đơn'),
                          ),
                        ),
                      if (onCancel != null) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Chi tiết'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        label = 'Chờ xác nhận';
        break;
      case 'confirmed':
        color = Colors.blue;
        label = 'Đã xác nhận';
        break;
      case 'shipping':
        color = Colors.purple;
        label = 'Đang giao';
        break;
      case 'completed':
        color = Colors.green;
        label = 'Hoàn thành';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Đã hủy';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Khác';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}