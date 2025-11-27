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
        print('✅ Fetched ${_orders.length} orders');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get orders by status
  List<OrderModel> getOrdersByStatus(String status) {
    // ✅ THÊM CASE 'all'
    if (status == 'all') {
      print('📋 Returning all ${_orders.length} orders');
      return List.from(_orders);  // Return all orders
    }
    
    final filtered = _orders.where((order) => order.status == status).toList();
    print('📋 Filtered ${filtered.length} orders with status: $status');
    return filtered;
  }

  /// Cancel order by ID
  Future<bool> cancelOrder(String orderId) async {
    try {
      print('\n🚫 ========== CANCEL ORDER ==========');
      print('🎯 Order ID: $orderId');

      final response = await _apiClient.put(ApiConfig.cancelOrder(orderId));
      
      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        await fetchOrders();
        print('✅ Order cancelled successfully');
        print('🚫 ========== CANCEL ORDER END ==========\n');
        return true;
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error cancelling order: $e');
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
      print('\n📦 ========== CREATE ORDER FROM CART ==========');
      print('💳 Payment method: $paymentMethod');
      print('🎫 Voucher ID: ${voucherId ?? "None"}');
      print('🛒 Selected items: ${selectedItemIds.length}');

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

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        notifyListeners();

        print('✅ Order created: ${order.id}');
        print('📋 Order number: ${order.orderNumber}');
        print('📦 ========== CREATE ORDER FROM CART END ==========\n');

        return order;
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      _error = e.toString();

      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Create order from payment intent
  Future<OrderModel?> createOrderFromIntent({
    required String intentId,
  }) async {
    try {
      print('\n🎯 ========== CREATE ORDER FROM INTENT ==========');
      print('🎯 Intent ID: $intentId');

      final response = await _apiClient.post(
        ApiConfig.ORDERS_FROM_INTENT,
        data: {'intentId': intentId},
      );

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(response.data['order']);
        _orders.insert(0, order);
        _currentIntent = null;
        notifyListeners();

        print('✅ Order created: ${order.id}');
        print('📋 Order number: ${order.orderNumber}');
        print('🎯 ========== CREATE ORDER FROM INTENT END ==========\n');

        return order;
      }
    } catch (e) {
      print('❌ Error creating order from intent: $e');
      _error = e.toString();
      
      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
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
      print('\n💫 ========== CREATE INTENT ==========');
      print('💳 Payment method: $paymentMethod');
      print('🎫 Voucher ID: ${voucherId ?? "None"}');
      print('🛒 Selected items: ${selectedItemIds.length}');

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

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();

        print('✅ Intent created: ${intent.id}');
        print('💰 Total amount: ${intent.totalAmount}');
        print('📊 Status: ${intent.paymentStatus}');
        print('💫 ========== CREATE INTENT END ==========\n');

        return intent;
      }
    } catch (e) {
      print('❌ Error creating intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Get payment intent by ID
  Future<PaymentIntentModel?> getPaymentIntent(String intentId) async {
    try {
      print('\n🔍 ========== GET INTENT ==========');
      print('🎯 Intent ID: $intentId');

      final response = await _apiClient.get(ApiConfig.paymentIntent(intentId));

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();

        print('✅ Intent found');
        print('📊 Status: ${intent.paymentStatus}');
        print('💰 Total: ${intent.totalAmount}');
        print('🔍 ========== GET INTENT END ==========\n');

        return intent;
      }
    } catch (e) {
      print('❌ Error getting intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Cancel payment intent
  Future<bool> cancelIntent(String intentId) async {
    try {
      print('\n🚫 ========== CANCEL INTENT ==========');
      print('🎯 Intent ID: $intentId');

      final response = await _apiClient.put(
        ApiConfig.cancelPaymentIntent(intentId),
      );

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final requiresRefund = response.data['requiresRefund'] ?? false;
        
        if (requiresRefund) {
          print('⚠️ Refund required');
        }

        _currentIntent = null;
        notifyListeners();

        print('✅ Intent cancelled');
        print('🚫 ========== CANCEL INTENT END ==========\n');

        return true;
      }
    } catch (e) {
      print('❌ Error cancelling intent: $e');
      _error = e.toString();

      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
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
      print('\n💳 ========== CREATE VNPAY FROM INTENT ==========');
      print('🎯 Intent ID: $intentId');

      final response = await _apiClient.post(
        ApiConfig.PAYMENT_VNPAY_CREATE,
        data: {'intentId': intentId},
      );

      print('🔍 Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = PaymentResponse.fromJson(response.data);
        
        print('✅ Payment URL created');
        print('🔗 TxnRef: ${result.txnRef}');
        print('💳 ========== CREATE VNPAY FROM INTENT END ==========\n');
        
        return result;
      } else {
        print('❌ Failed to create payment URL');
        return PaymentResponse(
          success: false,
          message: response.data['message'] ?? 'Không thể tạo link thanh toán',
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      
      if (e is DioException) {
        print('❌ Status: ${e.response?.statusCode}');
        print('❌ Data: ${e.response?.data}');
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
    print('\n🔍 ========== CHECK PENDING PAID INTENT ==========');

    final response = await _apiClient.get(
      ApiConfig.PAYMENT_INTENT_PENDING_PAID,
    );

    print('🔍 Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final hasPending = response.data['hasPendingIntent'] ?? false;
      
      if (hasPending) {
        final intent = PaymentIntentModel.fromJson(response.data['intent']);
        _currentIntent = intent;
        notifyListeners();

        print('⚠️ Found pending paid intent!');
        print('🎯 Intent ID: ${intent.id}');
        print('💰 Amount: ${intent.totalAmount}');
        print('🔍 ========== CHECK PENDING PAID INTENT END ==========\n');

        return intent;
      } else {
        print('✅ No pending paid intent');
        print('🔍 ========== CHECK PENDING PAID INTENT END ==========\n');
        return null;
      }
    }
  } catch (e) {
    print('❌ Error checking pending intent: $e');
    
    if (e is DioException) {
      print('❌ Status: ${e.response?.statusCode}');
      print('❌ Data: ${e.response?.data}');
    }
  }
  return null;
}

  // ================== UTILITIES ==================

  /// Clear current intent
  void clearIntent() {
    print('🧹 Clearing current intent');
    _currentIntent = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    print('🧹 Clearing all order data');
    _orders.clear();
    _currentIntent = null;
    _error = null;
    notifyListeners();
  }
}