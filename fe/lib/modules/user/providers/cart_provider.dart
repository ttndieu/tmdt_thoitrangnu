// lib/modules/user/providers/cart_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/cart_model.dart';

class CartProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<CartItemModel> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  // Fetch cart from server
  Future<void> fetchCart() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.CART);

      if (response.statusCode == 200) {
        final cartData = response.data['cart'];
        if (cartData != null && cartData['items'] != null) {
          final List itemsJson = cartData['items'];
          _items = itemsJson.map((json) => CartItemModel.fromJson(json)).toList();
        } else {
          _items = [];
        }
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Error fetching cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to cart
  Future<bool> addToCart({
    required String productId,
    required String size,
    required String color,
    required int quantity,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.CART,
        data: {
          'productId': productId,
          'size': size,
          'color': color,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCart(); // Refresh cart
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error adding to cart: $e');
      return false;
    }
  }

  // Update quantity
  Future<bool> updateQuantity(String productId, String size, String color, int quantity) async {
    if (quantity <= 0) {
      return await removeItem(productId, size, color);
    }

    try {
      final response = await _apiClient.put(
        ApiConfig.CART,
        data: {
          'productId': productId,
          'size': size,
          'color': color,
          'quantity': quantity,
        },
      );

      if (response.statusCode == 200) {
        await fetchCart(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error updating quantity: $e');
      return false;
    }
  }

  // Remove item
  Future<bool> removeItem(String productId, String size, String color) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.CART}/item',
        data: {
          'productId': productId,
          'size': size,
          'color': color,
        },
      );

      if (response.statusCode == 200) {
        await fetchCart(); // Refresh
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error removing item: $e');
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    try {
      final response = await _apiClient.delete('${ApiConfig.CART}/clear');

      if (response.statusCode == 200) {
        _items.clear();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error clearing cart: $e');
      return false;
    }
  }

  // Clear local state (for logout)
  void clear() {
    _items.clear();
    _error = null;
    notifyListeners();
  }
}