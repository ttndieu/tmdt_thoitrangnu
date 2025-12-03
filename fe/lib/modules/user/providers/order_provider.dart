// lib/modules/user/providers/order_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/order_model.dart';
import '../models/payment_model.dart';
import '../models/payment_intent_model.dart';
import 'package:dio/dio.dart';

class OrderProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  PaymentIntentModel? _currentIntent;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  PaymentIntentModel? get currentIntent => _currentIntent;

  // ================== ORDER MANAGEMENT ==================

  /// Fetch all orders
  Future<void> fetchOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.ORDERS);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['orders'];
        _orders = data.map((json) => OrderModel.fromJson(json)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    // THÊM CASE 'all'
    if (status == 'all') {
      return List.from(_orders);  // Return all orders
    }
    
    final filtered = _orders.where((order) => order.status == status).toList();
    return filtered;
  }

  /// Cancel order by ID
  Future<bool> cancelOrder(String orderId) async {
    try {
      final response = await _apiClient.put(ApiConfig.cancelOrder(orderId));
      if (response.statusCode == 200) {
        await fetchOrders();
        return true;
      }
    } catch (e) {
      _error = e.toString();
    }
    return false;
  }

  // ================== CREATE ORDER ==================

  /// Create order from cart (COD)
  Future<OrderModel?> createOrderFromCart({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String? voucherId,
    required List<String> selectedItemIds,
  }) async {
    try {
      final requestData = {
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        'selectedItemIds': selectedItemIds,
        if (voucherId != null && voucherId.isNotEmpty) 'voucherId': voucherId,
      };

      final response = await _apiClient.post(
        ApiConfig.ORDERS,
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        notifyListeners();
        return order;
      }
    } catch (e) {
      print('Error creating order: $e');
      _error = e.toString();

      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Create order from payment intent
  Future<OrderModel?> createOrderFromIntent({
    required String intentId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.ORDERS_FROM_INTENT,
        data: {'intentId': intentId},
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        _currentIntent = null;
        notifyListeners();
        return order;
      }
    } catch (e) {
      print('Error creating order from intent: $e');
      _error = e.toString();
      
      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
    return null;
  }

  // ================== PAYMENT INTENT ==================

  /// Create payment intent for VNPay
  Future<PaymentIntentModel?> createPaymentIntent({
    required String paymentMethod,
    required Map<String, dynamic> shippingAddress,
    String? voucherId,
    required List<String> selectedItemIds,
  }) async {
    try {
      final requestData = {
        'paymentMethod': paymentMethod,
        'shippingAddress': shippingAddress,
        'selectedItemIds': selectedItemIds,
        if (voucherId != null && voucherId.isNotEmpty) 'voucherId': voucherId,
      };

      final response = await _apiClient.post(
        ApiConfig.PAYMENT_INTENT_CREATE,
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();
        return intent;
      }
    } catch (e) {
      print('Error creating intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Get payment intent by ID
  Future<PaymentIntentModel?> getPaymentIntent(String intentId) async {
    try {
      final response = await _apiClient.get(ApiConfig.paymentIntent(intentId));
      if (response.statusCode == 200) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();
        return intent;
      }
    } catch (e) {
      print('Error getting intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Cancel payment intent
  Future<bool> cancelIntent(String intentId) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.cancelPaymentIntent(intentId),
      );

      if (response.statusCode == 200) {
        final requiresRefund = response.data['requiresRefund'] ?? false;
        
        if (requiresRefund) {
          print('Refund required');
        }
        _currentIntent = null;
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error cancelling intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }
    }
    return false;
  }

  // ================== VNPAY PAYMENT ==================

  /// Create VNPay payment URL from intent
  Future<PaymentResponse> createVNPayPaymentFromIntent({
    required String intentId,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.PAYMENT_VNPAY_CREATE,
        data: {'intentId': intentId},
      );
      if (response.statusCode == 200) {
        final result = PaymentResponse.fromJson(response.data);
        return result;
      } else {
        return PaymentResponse(
          success: false,
          message: response.data['message'] ?? 'Không thể tạo link thanh toán',
        );
      }
    } catch (e) {
      print('Error: $e');
      
      if (e is DioException) {
        print('Status: ${e.response?.statusCode}');
        print('Data: ${e.response?.data}');
      }

      return PaymentResponse(
        success: false,
        message: 'Lỗi kết nối: ${e.toString()}',
      );
    }
  }

  /// Check pending paid intent (đã thanh toán nhưng chưa có order)
Future<PaymentIntentModel?> checkPendingPaidIntent() async {
  try {
    final response = await _apiClient.get(
      ApiConfig.PAYMENT_INTENT_PENDING_PAID,
    );
    if (response.statusCode == 200) {
      final hasPending = response.data['hasPendingIntent'] ?? false;
      
      if (hasPending) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();
        return intent;
      } else {
        return null;
      }
    }
  } catch (e) {
    print('Error checking pending intent: $e');
    
    if (e is DioException) {
      print('Status: ${e.response?.statusCode}');
      print('Data: ${e.response?.data}');
    }
  }
  return null;
}

  // ================== UTILITIES ==================

  /// Clear current intent
  void clearIntent() {
    print('Clearing current intent');
    _currentIntent = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    print('Clearing all order data');
    _orders.clear();
    _currentIntent = null;
    _error = null;
    notifyListeners();
  }
}