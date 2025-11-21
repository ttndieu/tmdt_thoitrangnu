import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';
import '../models/voucher_model.dart';

class HomeProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<VoucherModel> _vouchers = [];
  
  bool _isLoadingCategories = false;
  bool _isLoadingProducts = false;
  bool _isLoadingVouchers = false;
  
  String? _error;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _products;
  List<VoucherModel> get vouchers => _vouchers;
  List<VoucherModel> get availableVouchers => 
      _vouchers.where((v) => v.isAvailable).toList();
  
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingVouchers => _isLoadingVouchers;
  bool get isLoading => _isLoadingCategories || _isLoadingProducts || _isLoadingVouchers;
  
  String? get error => _error;

  // ==================== CATEGORIES ====================
  Future<void> fetchCategories() async {
    _isLoadingCategories = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.CATEGORIES);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> categoriesJson = data['categories'] ?? [];
        
        _categories = categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();
            
        debugPrint('✅ Loaded ${_categories.length} categories');
        _error = null;
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, 'tải danh mục');
      debugPrint('❌ $_error');
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('❌ $e');
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  // ==================== PRODUCTS ====================
  Future<void> fetchProducts({
    String? keyword,
    String? categorySlug,
    String? size,
  }) async {
    _isLoadingProducts = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{};
      
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }
      if (categorySlug != null && categorySlug.isNotEmpty) {
        queryParams['category'] = categorySlug;
      }
      if (size != null && size.isNotEmpty) {
        queryParams['size'] = size;
      }

      final response = await _apiClient.get(
        ApiConfig.PRODUCTS,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> productsJson = data['products'] ?? [];
        
        _products = productsJson
            .map((json) => ProductModel.fromJson(json))
            .toList();
            
        debugPrint('✅ Loaded ${_products.length} products');
        _error = null;
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, 'tải sản phẩm');
      debugPrint('❌ $_error');
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('❌ $e');
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // ==================== VOUCHERS ====================
  Future<void> fetchVouchers() async {
    _isLoadingVouchers = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.VOUCHERS);

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> vouchersJson = data['vouchers'] ?? [];
        
        _vouchers = vouchersJson
            .map((json) => VoucherModel.fromJson(json))
            .toList();
            
        debugPrint('✅ Loaded ${_vouchers.length} vouchers');
        _error = null;
      }
    } on DioException catch (e) {
      _error = _handleDioError(e, 'tải voucher');
      debugPrint('❌ $_error');
    } catch (e) {
      _error = 'Lỗi: $e';
      debugPrint('❌ $e');
    } finally {
      _isLoadingVouchers = false;
      notifyListeners();
    }
  }

  // ==================== TOGGLE FAVORITE ====================
  void toggleFavorite(String productId) {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _products[index].isFavorite = !_products[index].isFavorite;
      notifyListeners();
    }
  }

  // ==================== LOAD ALL ====================
  Future<void> loadHomeData() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
      fetchVouchers(),
    ]);
  }

  Future<void> filterByCategory(String categorySlug) async {
    await fetchProducts(categorySlug: categorySlug);
  }

  Future<void> searchProducts(String keyword) async {
    await fetchProducts(keyword: keyword);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _handleDioError(DioException e, String action) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối timeout khi $action';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'];
        if (statusCode == 404) return message ?? 'Không tìm thấy dữ liệu';
        if (statusCode == 500) return 'Lỗi server';
        return message ?? 'Không thể $action';
      case DioExceptionType.connectionError:
        return 'Lỗi kết nối mạng';
      default:
        return 'Lỗi không xác định khi $action';
    }
  }
}