// lib/modules/user/providers/order_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart'; 
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    if (status == 'all') return _orders;
    return _orders.where((order) => order.status == status).toList();
  }

  // Fetch all orders
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ✅ FIX: Dùng ApiConfig.ORDERS
      final response = await _apiClient.get(ApiConfig.ORDERS);

      print('🔍 Orders Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List ordersJson = response.data['orders'] ?? [];
        _orders = ordersJson.map((json) => OrderModel.fromJson(json)).toList();
        _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        print('✅ Loaded ${_orders.length} orders');
      }
    } catch (e) {
      _error = 'Không thể tải đơn hàng';
      print('❌ Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create order from cart
  Future<OrderModel?> createOrderFromCart({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
  }) async {
    try {
      // ✅ FIX: Dùng ApiConfig.ORDERS
      final response = await _apiClient.post(
        ApiConfig.ORDERS,
        data: {
          'paymentMethod': paymentMethod,
          'shippingAddress': shippingAddress,
        },
      );

      print('🔍 Create Order Response: ${response.statusCode}');
      print('🔍 Request URL: ${ApiConfig.ORDERS}');
      print('🔍 Full URL: ${_apiClient.dio.options.baseUrl}${ApiConfig.ORDERS}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        notifyListeners();
        print('✅ Order created: ${order.id}');
        return order;
      }
    } catch (e) {
      print('❌ Error creating order: $e');
    }
    return null;
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId) async {
    try {
      // ✅ FIX: Dùng ApiConfig.ORDERS
      final response = await _apiClient.put(
        '${ApiConfig.ORDERS}/$orderId/status',
        data: {
          'status': 'cancelled',
        },
      );

      if (response.statusCode == 200) {
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = OrderModel.fromJson(response.data['order']);
          notifyListeners();
        }
        return true;
      }
    } catch (e) {
      print('❌ Error canceling order: $e');
    }
    return false;
  }

  void clear() {
    _orders.clear();
    _error = null;
    notifyListeners();
  }
}