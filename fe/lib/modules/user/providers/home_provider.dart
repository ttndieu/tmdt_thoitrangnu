// lib/modules/user/providers/home_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

class HomeProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // State
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> _categories = [];
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];

  String? _selectedCategorySlug;
  String _searchQuery = '';

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _filteredProducts;
  String? get selectedCategorySlug => _selectedCategorySlug;
  String get searchQuery => _searchQuery;

  // Featured products (3 đầu tiên)
  List<ProductModel> get featuredProducts =>
      _products.take(3).toList();

  // Fetch categories
  Future<void> fetchCategories() async {
    try {
      final response = await _apiClient.get(ApiConfig.CATEGORIES);

      if (response.statusCode == 200) {
        final data = response.data;
        _categories = (data['data'] as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Fetch products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.PRODUCTS);

      if (response.statusCode == 200) {
        final data = response.data;
        _products = (data['products'] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();

        _applyFilters();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter by category
  void filterByCategory(String? slug) {
    _selectedCategorySlug = slug;
    _applyFilters();
    notifyListeners();
  }

  // Search
  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Apply all filters
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Filter by category
      if (_selectedCategorySlug != null &&
          product.category?.slug != _selectedCategorySlug) {
        return false;
      }

      // Filter by search
      if (_searchQuery.isNotEmpty &&
          !product.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }

      return true;
    }).toList();
  }

  // Refresh
  Future<void> refresh() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
    ]);
  }

  // Clear filters
  void clearFilters() {
    _selectedCategorySlug = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }
}