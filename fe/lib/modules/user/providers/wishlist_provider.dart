// lib/modules/user/providers/wishlist_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/product_model.dart';

class WishlistProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ProductModel> _wishlist = [];
  Set<String> _wishlistIds = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProductModel> get wishlist => _wishlist;
  List<ProductModel> get items => _wishlist;
  Set<String> get wishlistIds => _wishlistIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _wishlist.length;

  bool isWishlisted(String productId) {
    return _wishlistIds.contains(productId);
  }

  // ✅ FIXED: Fetch wishlist with better error handling
  Future<void> fetchWishlist() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.WISHLIST);

      print('🔍 Wishlist Response: ${response.statusCode}');
      print('🔍 Wishlist Data Type: ${response.data.runtimeType}');
      print('🔍 Wishlist Data: ${response.data}');

      if (response.statusCode == 200) {
        // Check if response has wishlist field
        if (response.data is Map && response.data.containsKey('wishlist')) {
          final dynamic wishlistData = response.data['wishlist'];
          
          print('🔍 Wishlist Array Type: ${wishlistData.runtimeType}');
          
          if (wishlistData is List) {
            if (wishlistData.isEmpty) {
              print('✅ Wishlist is empty');
              _wishlist = [];
              _wishlistIds = {};
            } else {
              print('🔍 First item type: ${wishlistData.first.runtimeType}');
              
              // ✅ Parse products
              _wishlist = [];
              _wishlistIds = {};
              
              for (var item in wishlistData) {
                try {
                  if (item is Map<String, dynamic>) {
                    final product = ProductModel.fromJson(item);
                    _wishlist.add(product);
                    _wishlistIds.add(product.id);
                  } else if (item is Map) {
                    // Convert Map to Map<String, dynamic>
                    final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(item);
                    final product = ProductModel.fromJson(jsonMap);
                    _wishlist.add(product);
                    _wishlistIds.add(product.id);
                  } else if (item is String) {
                    // If only IDs, add to set
                    _wishlistIds.add(item);
                    print('⚠️ Wishlist contains only ID: $item');
                  }
                } catch (e) {
                  print('⚠️ Failed to parse product: $e');
                  print('⚠️ Item: $item');
                }
              }
              
              print('✅ Wishlist loaded: ${_wishlist.length} products');
            }
          } else {
            throw Exception('Wishlist is not a List');
          }
        } else {
          throw Exception('Response does not contain wishlist field');
        }
      } else {
        throw Exception('Failed to load wishlist: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      _error = 'Không thể tải danh sách yêu thích';
      print('❌ Error fetching wishlist: $e');
      print('❌ Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(String productId) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.WISHLIST}/$productId',
      );

      print('🔍 Add wishlist response: ${response.statusCode}');

      if (response.statusCode == 200) {
        _wishlistIds.add(productId);
        // Refresh to get full data
        await fetchWishlist();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error adding to wishlist: $e');
      return false;
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.WISHLIST}/$productId',
      );

      print('🔍 Remove wishlist response: ${response.statusCode}');

      if (response.statusCode == 200) {
        _wishlistIds.remove(productId);
        _wishlist.removeWhere((p) => p.id == productId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error removing from wishlist: $e');
      return false;
    }
  }

  // Toggle wishlist
  Future<bool> toggleWishlist(String productId) async {
    if (isWishlisted(productId)) {
      return await removeFromWishlist(productId);
    } else {
      return await addToWishlist(productId);
    }
  }

  // Clear wishlist
  void clear() {
    _wishlist.clear();
    _wishlistIds.clear();
    _error = null;
    notifyListeners();
  }

  // Refresh
  Future<void> refresh() async {
    await fetchWishlist();
  }
}