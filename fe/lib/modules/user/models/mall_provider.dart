// lib/modules/user/providers/mall_provider.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

enum SortOption {
  newest,
  priceAsc,
  priceDesc,
  nameAZ,
  nameZA,
}

class MallProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // State
  bool _isLoading = false;
  String? _error;

  List<CategoryModel> _categories = [];
  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];

  // Filters
  String? _selectedCategorySlug;
  double _minPrice = 0;
  double _maxPrice = 10000000;
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  SortOption _sortOption = SortOption.newest;
  String _searchQuery = '';

  // Available options
  final List<String> _availableSizes = ['S', 'M', 'L', 'XL', 'XXL'];
  final List<String> _availableColors = [
    'Đen',
    'Trắng',
    'Đỏ',
    'Xanh',
    'Vàng',
    'Hồng',
    'Nâu',
    'Xám'
  ];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<CategoryModel> get categories => _categories;
  List<ProductModel> get products => _filteredProducts;
  List<String> get availableSizes => _availableSizes;
  List<String> get availableColors => _availableColors;

  String? get selectedCategorySlug => _selectedCategorySlug;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;
  List<String> get selectedSizes => _selectedSizes;
  List<String> get selectedColors => _selectedColors;
  SortOption get sortOption => _sortOption;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters =>
      _selectedCategorySlug != null ||
      _selectedSizes.isNotEmpty ||
      _selectedColors.isNotEmpty ||
      _minPrice > 0 ||
      _maxPrice < 10000000 ||
      _searchQuery.isNotEmpty;

  String get sortLabel {
    switch (_sortOption) {
      case SortOption.newest:
        return 'Mới nhất';
      case SortOption.priceAsc:
        return 'Giá: Thấp → Cao';
      case SortOption.priceDesc:
        return 'Giá: Cao → Thấp';
      case SortOption.nameAZ:
        return 'Tên: A → Z';
      case SortOption.nameZA:
        return 'Tên: Z → A';
    }
  }

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
        _allProducts = (data['products'] as List)
            .map((json) => ProductModel.fromJson(json))
            .toList();

        _applyFiltersAndSort();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Apply filters and sorting
  void _applyFiltersAndSort() {
    // Start with all products
    List<ProductModel> filtered = List.from(_allProducts);

    // Filter by category
    if (_selectedCategorySlug != null) {
      filtered = filtered
          .where((p) => p.category?.slug == _selectedCategorySlug)
          .toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Filter by size
    if (_selectedSizes.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.variants
            .any((v) => _selectedSizes.contains(v.size) && v.stock > 0);
      }).toList();
    }

    // Filter by color
    if (_selectedColors.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.variants
            .any((v) => _selectedColors.contains(v.color) && v.stock > 0);
      }).toList();
    }

    // Filter by price
    filtered = filtered.where((p) {
      return p.minPrice >= _minPrice && p.maxPrice <= _maxPrice;
    }).toList();

    // Apply sorting
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        break;
      case SortOption.priceAsc:
        filtered.sort((a, b) => a.minPrice.compareTo(b.minPrice));
        break;
      case SortOption.priceDesc:
        filtered.sort((a, b) => b.maxPrice.compareTo(a.maxPrice));
        break;
      case SortOption.nameAZ:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.nameZA:
        filtered.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    _filteredProducts = filtered;
  }

  // Update filters
  void setCategoryFilter(String? slug) {
    _selectedCategorySlug = slug;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void toggleSize(String size) {
    if (_selectedSizes.contains(size)) {
      _selectedSizes.remove(size);
    } else {
      _selectedSizes.add(size);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void toggleColor(String color) {
    if (_selectedColors.contains(color)) {
      _selectedColors.remove(color);
    } else {
      _selectedColors.add(color);
    }
    _applyFiltersAndSort();
    notifyListeners();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategorySlug = null;
    _minPrice = 0;
    _maxPrice = 10000000;
    _selectedSizes.clear();
    _selectedColors.clear();
    _searchQuery = '';
    _applyFiltersAndSort();
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([
      fetchCategories(),
      fetchProducts(),
    ]);
  }
}