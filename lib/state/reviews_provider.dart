import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ReviewsProvider with ChangeNotifier {
  List<ReviewModel> _reviews = [];
  Map<String, dynamic>? _reviewStats;
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get reviews => _reviews;
  Map<String, dynamic>? get reviewStats => _reviewStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get count => _reviews.length;

  double get averageRating {
    if (_reviewStats != null && _reviewStats!['average_rating'] != null) {
      return (_reviewStats!['average_rating'] as num).toDouble();
    }
    if (_reviews.isEmpty) return 0.0;
    final sum = _reviews.fold<int>(0, (sum, review) => sum + review.rating);
    return sum / _reviews.length;
  }

  Future<void> loadProductReviews(int productId, {int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviewsData = await ApiService.I.getProductReviews(productId, page: page);
      final reviewsList = reviewsData['data'] as List? ?? [];
      _reviews = reviewsList
          .map((data) => ReviewModel.fromApi(data as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVendorReviews(int vendorId, {int page = 1}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final reviewsData = await ApiService.I.getVendorReviews(vendorId, page: page);
      final reviewsList = reviewsData['data'] as List? ?? [];
      _reviews = reviewsList
          .map((data) => ReviewModel.fromApi(data as Map<String, dynamic>))
          .toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductReviewStats(int productId) async {
    try {
      _reviewStats = await ApiService.I.getProductReviewStats(productId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> addProductReview({
    required int productId,
    required int rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      await ApiService.I.storeProductReview(
        productId: productId,
        rating: rating,
        comment: comment,
        images: images,
      );
      // Reload reviews after adding
      await loadProductReviews(productId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addVendorReview({
    required int vendorId,
    required int rating,
    String? comment,
  }) async {
    try {
      await ApiService.I.storeVendorReview(
        vendorId: vendorId,
        rating: rating,
        comment: comment,
      );
      // Reload reviews after adding
      await loadVendorReviews(vendorId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReview(int reviewId, {int? rating, String? comment}) async {
    try {
      await ApiService.I.updateProductReview(reviewId, rating: rating, comment: comment);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReview(int reviewId) async {
    try {
      await ApiService.I.deleteProductReview(reviewId);
      _reviews.removeWhere((r) => r.id == reviewId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rateReview(int reviewId, bool isHelpful) async {
    try {
      await ApiService.I.rateProductReview(reviewId, isHelpful);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter methods
  List<ReviewModel> getReviewsByRating(int rating) {
    return _reviews.where((r) => r.rating == rating).toList();
  }

  List<ReviewModel> get fiveStarReviews => getReviewsByRating(5);
  List<ReviewModel> get fourStarReviews => getReviewsByRating(4);
  List<ReviewModel> get threeStarReviews => getReviewsByRating(3);
  List<ReviewModel> get twoStarReviews => getReviewsByRating(2);
  List<ReviewModel> get oneStarReviews => getReviewsByRating(1);
}

