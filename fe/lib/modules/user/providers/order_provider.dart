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

  // ✅ CREATE ORDER FROM CART WITH VOUCHER
  Future<OrderModel?> createOrderFromCart({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String? voucherId,
  }) async {
    try {
      print('\n📦 ========== CREATE ORDER (FLUTTER) ==========');
      print('💳 Payment method: $paymentMethod');
      print('🎫 Voucher ID: ${voucherId ?? "None"}');

      final requestData = {
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        if (voucherId != null && voucherId.isNotEmpty) 
          'voucherId': voucherId,
      };

      print('📤 Request data: $requestData');

      final response = await _apiClient.post(
        ApiConfig.ORDERS,
        data: requestData,
      );

      print('🔍 Create Order Response: ${response.statusCode}');
      print('🔍 Response data: ${response.data}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        notifyListeners();
        
        print('✅ Order created: ${order.id}');
        if (voucherId != null) {
          print('🎫 Voucher applied successfully');
        }
        print('📦 ========== CREATE ORDER END ==========\n');
        
        return order;
      } else {
        print('❌ Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      _error = e.toString();
    }
    return null;
  }

  // ✅ CANCEL ORDER - SỬA LẠI ĐỂ GỌI ĐÚNG ENDPOINT
  Future<bool> cancelOrder(String orderId) async {
    try {
      print('\n🚫 ========== CANCEL ORDER (FLUTTER) ==========');
      print('📦 Order ID: $orderId');

      // ✅ GỌI ĐÚNG ENDPOINT: /api/orders/:id/cancel
      final response = await _apiClient.put(
        '${ApiConfig.ORDERS}/$orderId/cancel',
        data: {}, // Không cần truyền data
      );

      print('🔍 Cancel Response: ${response.statusCode}');
      print('🔍 Response data: ${response.data}');

      if (response.statusCode == 200) {
        // ✅ Update order trong danh sách
        final index = _orders.indexWhere((o) => o.id == orderId);
        if (index != -1) {
          _orders[index] = OrderModel.fromJson(response.data['order']);
          notifyListeners();
          print('✅ Order cancelled successfully');
        }
        
        print('🚫 ========== CANCEL ORDER END ==========\n');
        return true;
      }
    } catch (e) {
      print('❌ Error canceling order: $e');
      _error = e.toString();
      
      // Throw error message để UI hiển thị
      if (e.toString().contains('Chỉ có thể hủy đơn hàng ở trạng thái chờ xác nhận')) {
        throw 'Chỉ có thể hủy đơn hàng ở trạng thái chờ xác nhận';
      } else if (e.toString().contains('không có quyền')) {
        throw 'Bạn không có quyền hủy đơn hàng này';
      }
      throw 'Không thể hủy đơn hàng. Vui lòng thử lại';
    }
    return false;
  }

  void clear() {
    _orders.clear();
    _error = null;
    notifyListeners();
  }
}