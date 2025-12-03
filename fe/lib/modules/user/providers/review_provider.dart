import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/api.dart';
import '../models/review_model.dart';

class ReviewProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ReviewModel> _reviews = [];
  List<ReviewModel> _myReviews = [];
  bool _isLoading = false;
  String? _error;

  int _currentPage = 1;
  int _totalPages = 1;
  String _sortBy = 'newest';

  List<ReviewModel> get reviews => _reviews;
  List<ReviewModel> get myReviews => _myReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get sortBy => _sortBy;

  // FETCH REVIEWS BY PRODUCT
  Future<void> fetchProductReviews(
    String productId, {
    int page = 1,
    String sort = 'newest',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(
        ApiConfig.productReviews(productId),
        queryParameters: {
          'page': page,
          'limit': 10,
          'sort': sort,
        },
      );

      print('🔍 Reviews Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List reviewsJson = response.data['reviews'] ?? [];

        if (page == 1) {
          _reviews =
              reviewsJson.map((json) => ReviewModel.fromJson(json)).toList();
        } else {
          _reviews.addAll(
            reviewsJson.map((json) => ReviewModel.fromJson(json)).toList(),
          );
        }

        _currentPage =
            int.tryParse(response.data['currentPage'].toString()) ?? 1;
        _totalPages =
            int.tryParse(response.data['totalPages'].toString()) ?? 1;
        _sortBy = sort;

        print('Loaded ${_reviews.length} reviews (Page $page/$_totalPages)');
      }
    } catch (e) {
      _error = 'Không thể tải đánh giá';
      print('Error fetching reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // FETCH MY REVIEWS
  Future<void> fetchMyReviews() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.get(ApiConfig.MY_REVIEWS);

      if (response.statusCode == 200) {
        final List reviewsJson = response.data['reviews'] ?? [];
        _myReviews =
            reviewsJson.map((json) => ReviewModel.fromJson(json)).toList();
        print('Loaded ${_myReviews.length} my reviews');
      }
    } catch (e) {
      _error = 'Không thể tải đánh giá của bạn';
      print('Error fetching my reviews: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // CHECK CAN REVIEW
  Future<CanReviewResponse?> checkCanReview(String productId) async {
    try {
      print('\nChecking can review for product: $productId');

      final response = await _apiClient.get(
        ApiConfig.canReview(productId),
      );

      print('Can review response: ${response.data}');

      if (response.statusCode == 200) {
        return CanReviewResponse.fromJson(response.data);
      }
    } catch (e) {
      print('Error checking can review: $e');
      _error = e.toString();
    }
    return null;
  }

  // CREATE REVIEW
  Future<bool> createReview({
    required String productId,
    required String orderId,
    required int rating,
    required String comment,
    List<Map<String, String>>? images,
  }) async {
    try {
      print('\n========== CREATE REVIEW (FLUTTER) ==========');
      print('Product: $productId');
      print('Order: $orderId');
      print('Rating: $rating');
      print('Comment: $comment');

      final response = await _apiClient.post(
        ApiConfig.REVIEWS,
        data: {
          'productId': productId,
          'orderId': orderId,
          'rating': rating,
          'comment': comment,
          if (images != null && images.isNotEmpty) 'images': images,
        },
      );

      print('🔍 Create review response: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('Review created successfully');
        print('========== CREATE REVIEW END ==========\n');
        return true;
      }
    } catch (e) {
      print('Error creating review: $e');
      _error = e.toString();
    }
    return false;
  }

  // UPDATE REVIEW
  Future<bool> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<Map<String, String>>? images,
  }) async {
    try {
      print('\n Updating review: $reviewId');

      final response = await _apiClient.put(
        ApiConfig.updateReview(reviewId),
        data: {
          if (rating != null) 'rating': rating,
          if (comment != null) 'comment': comment,
          if (images != null) 'images': images,
        },
      );

      if (response.statusCode == 200) {
        print('Review updated successfully');
        return true;
      }
    } catch (e) {
      print('Error updating review: $e');
      _error = e.toString();
    }
    return false;
  }

  // DELETE REVIEW
  Future<bool> deleteReview(String reviewId) async {
    try {
      print('\n Deleting review: $reviewId');

      final response = await _apiClient.delete(
        ApiConfig.deleteReview(reviewId),
      );

      if (response.statusCode == 200) {
        _reviews.removeWhere((r) => r.id == reviewId);
        _myReviews.removeWhere((r) => r.id == reviewId);
        notifyListeners();
        print('Review deleted successfully');
        return true;
      }
    } catch (e) {
      print('Error deleting review: $e');
      _error = e.toString();
    }
    return false;
  }

  // CHANGE SORT
  Future<void> changeSortBy(String productId, String sort) async {
    _sortBy = sort;
    _currentPage = 1;
    await fetchProductReviews(productId, page: 1, sort: sort);
  }

  // LOAD MORE
  Future<void> loadMore(String productId) async {
    if (_currentPage < _totalPages && !_isLoading) {
      await fetchProductReviews(
        productId,
        page: _currentPage + 1,
        sort: _sortBy,
      );
    }
  }

  void clear() {
    _reviews.clear();
    _myReviews.clear();
    _currentPage = 1;
    _totalPages = 1;
    _sortBy = 'newest';
    _error = null;
    notifyListeners();
  }
}