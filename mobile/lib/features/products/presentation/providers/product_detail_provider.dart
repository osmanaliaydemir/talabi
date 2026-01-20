import 'package:flutter/foundation.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/reviews/data/models/review.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/analytics_service.dart';

class ProductDetailProvider with ChangeNotifier {
  ProductDetailProvider({
    required this.productId,
    Product? initialProduct,
    ApiService? apiService,
  }) : _apiService = apiService ?? ApiService() {
    if (initialProduct != null) {
      _product = initialProduct;
      _isLoading = false;
    }
  }

  final String productId;
  final ApiService _apiService;

  Product? _product;
  bool _isLoading = true;
  bool _isFavorite = false;
  ProductReviewsSummary? _reviewsSummary;
  bool _isLoadingReviews = false;
  List<Product> _similarProducts = [];
  bool _isLoadingSimilarProducts = false;

  // Option selection state
  final Map<String, Set<String>> _selectedOptions = {};

  // Getters
  Product? get product => _product;
  bool get isLoading => _isLoading;
  bool get isFavorite => _isFavorite;
  ProductReviewsSummary? get reviewsSummary => _reviewsSummary;
  bool get isLoadingReviews => _isLoadingReviews;
  List<Product> get similarProducts => List.unmodifiable(_similarProducts);
  bool get isLoadingSimilarProducts => _isLoadingSimilarProducts;
  Map<String, Set<String>> get selectedOptions =>
      Map.unmodifiable(_selectedOptions);

  // Computed properties
  double get effectivePrice {
    if (_product == null) return 0.0;
    double totalPrice = _product!.price;

    for (final group in _product!.optionGroups) {
      final selectedIds = _selectedOptions[group.id];
      if (selectedIds != null) {
        for (final option in group.options) {
          if (selectedIds.contains(option.id)) {
            totalPrice += option.priceAdjustment;
          }
        }
      }
    }

    return totalPrice;
  }

  // Methods
  Future<void> loadProduct({bool refreshOnly = false}) async {
    try {
      if (!refreshOnly) {
        _isLoading = true;
        notifyListeners();
      }

      final product = await _apiService.getProduct(productId);
      _product = product;
      _isLoading = false;

      // Initialize options if changed?
      // Keep existing selection if product ID matches?
      // For now, simpler:
      if (!refreshOnly) {
        _initOptions();
      }

      notifyListeners();

      if (!refreshOnly) {
        AnalyticsService.logViewItem(product: product);
      }

      // Always check favorites and load reviews, effectively "refreshing" this data
      checkFavorite();
      loadReviews();

      if (!refreshOnly) {
        // Similar products should be called explicitly with location if needed
      }
    } catch (e) {
      LoggerService().error('Error loading product', e);
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void _initOptions() {
    _selectedOptions.clear();
    // Logic to select default options if any are mandatory?
    // Implementation depends on Product model details not fully seen,
    // but assuming empty start is fine or copying from existing logic.
    notifyListeners();
  }

  void toggleOption(String groupId, String optionId, bool isMultiSelect) {
    if (!_selectedOptions.containsKey(groupId)) {
      _selectedOptions[groupId] = {};
    }

    if (isMultiSelect) {
      if (_selectedOptions[groupId]!.contains(optionId)) {
        _selectedOptions[groupId]!.remove(optionId);
      } else {
        _selectedOptions[groupId]!.add(optionId);
      }
    } else {
      _selectedOptions[groupId]!.clear();
      _selectedOptions[groupId]!.add(optionId);
    }
    notifyListeners();
  }

  Future<void> checkFavorite() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      if (_product != null) {
        _isFavorite = favoritesResult.items.any((f) => f.id == _product!.id);
        notifyListeners();
      }
    } catch (e) {
      // Ignore
    }
  }

  Future<void> toggleFavorite() async {
    if (_product == null) return;

    try {
      if (_isFavorite) {
        await _apiService.removeFromFavorites(_product!.id);
        _isFavorite = false;
      } else {
        await _apiService.addToFavorites(_product!.id);
        _isFavorite = true;
      }
      notifyListeners();
    } catch (e) {
      // Revert if optimistic UI needed, but for now throwing to let UI handle
      rethrow;
    }
  }

  Future<void> loadReviews() async {
    if (_product == null) return;

    _isLoadingReviews = true;
    notifyListeners();

    try {
      final summary = await _apiService.getProductReviews(_product!.id);
      _reviewsSummary = summary;
      _isLoadingReviews = false;
      notifyListeners();
    } catch (e) {
      _isLoadingReviews = false;
      // Handle 404/Empty
      if (e.toString().contains('404')) {
        _reviewsSummary = ProductReviewsSummary(
          averageRating: _product?.rating ?? 0.0,
          totalRatings: _product?.reviewCount ?? 0,
          totalComments: 0,
          reviews: [],
        );
      }
      notifyListeners();
    }
  }

  Future<bool> canReview() async {
    if (_product == null) return false;
    return await _apiService.canReviewProduct(_product!.id);
  }

  Future<void> createReview(int rating, String comment) async {
    if (_product == null) return;
    await _apiService.createReview(_product!.id, 'Product', rating, comment);
    // Reload reviews to show new one
    await loadReviews();
  }

  Future<void> loadSimilarProducts({
    required double userLatitude,
    required double userLongitude,
  }) async {
    if (_product == null) return;

    _isLoadingSimilarProducts = true;
    notifyListeners();

    try {
      final similar = await _apiService.getSimilarProducts(
        _product!.id,
        pageSize: 5,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      _similarProducts = similar;
      _isLoadingSimilarProducts = false;
      notifyListeners();
    } catch (e) {
      LoggerService().error('Error loading similar products', e);
      _similarProducts = [];
      _isLoadingSimilarProducts = false;
      notifyListeners();
    }
  }
}
