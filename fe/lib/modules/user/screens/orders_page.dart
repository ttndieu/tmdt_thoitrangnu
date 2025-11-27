// lib/modules/user/screens/orders_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_color.dart';
import '../constants/app_text_styles.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import 'order_detail_page.dart';
import 'package:fe/core/utils/currency_formatter.dart';

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
    // 6 tabs
    _tabController = TabController(length: 6, vsync: this);

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
            Tab(text: 'Chờ giao hàng'),  
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
              _buildOrderList(provider, 'confirmed'), 
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
            // XÓA orderNumber - KHÔNG TRUYỀN VÀO
            date: order.formattedDate,
            status: order.status,
            items: order.items,
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
            content: Text(
              success ? '✅ Đã hủy đơn hàng' : '❌ Không thể hủy đơn hàng',
            ),
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
      case 'confirmed': 
        message = 'Chưa có đơn hàng chờ giao hàng';
        icon = Icons.inventory_2_outlined;
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
          Icon(icon, size: 100, color: AppColors.textHint.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
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

// ORDER CARD - XÓA orderNumber
class _OrderCard extends StatelessWidget {
  // ✅ XÓA orderNumber parameter
  final String date;
  final String status;
  final List<OrderItem> items;
  final double total;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _OrderCard({
    required this.date,
    required this.status,
    required this.items,
    required this.total,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = items.take(2).toList();
    final remainingCount = items.length - displayItems.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
              // HEADER MỚI - CHỈ STATUS VÀ NGÀY
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(status),
                  Text(
                    date,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // DANH SÁCH SẢN PHẨM
              ...displayItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.background,
                                  child: const Icon(Icons.image, size: 30),
                                ),
                              )
                            : Container(
                                width: 60,
                                height: 60,
                                color: AppColors.background,
                                child: const Icon(Icons.image, size: 30),
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
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (item.size.isNotEmpty) ...[
                                  Text(
                                    item.size,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (item.color.isNotEmpty) const Text(' • '),
                                ],
                                if (item.color.isNotEmpty)
                                  Text(
                                    item.color,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                const Spacer(),
                                Text(
                                  'x${item.quantity}',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (remainingCount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '+ $remainingCount sản phẩm khác',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const Divider(height: 12),

              // TỔNG TIỀN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tổng tiền',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(total.toCurrency(),
                    style: AppTextStyles.h3.copyWith(color: AppColors.primary),
                  ),
                ],
              ),

              // BUTTONS
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
        label = 'Chờ giao hàng'; 
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