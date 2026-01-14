import 'package:flutter/foundation.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/location_extractor.dart';

class CategoryProductsProvider with ChangeNotifier {
  CategoryProductsProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, bool> _favoriteStatus = {};
  int? _totalCount;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get totalCount => _totalCount;

  bool isFavorite(String productId) => _favoriteStatus[productId] ?? false;

  Future<void> loadProducts({
    required String categoryName,
    String? categoryId,
    required int vendorType,
    Map<String, dynamic>? selectedAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = LocationExtractor.fromAddress(selectedAddress);

      final request = ProductSearchRequestDto(
        category: categoryName,
        categoryId: categoryId,
        vendorType: vendorType,
        pageSize: 50,
        userLatitude: location.latitude,
        userLongitude: location.longitude,
      );

      final pagedResult = await _apiService.searchProducts(request);

      _products = pagedResult.items.map((e) => e.toProduct()).toList();
      _totalCount = _products.length;

      // Load favorites for these products
      await _loadFavoriteStatus();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _products = [];
      _totalCount = 0;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      _favoriteStatus.clear();
      for (final fav in favoritesResult.items) {
        _favoriteStatus[fav.id] = true;
      }
      notifyListeners();
    } catch (e) {
      // Ignore error for favorites
    }
  }

  Future<void> toggleFavorite(Product product) async {
    final currentStatus = _favoriteStatus[product.id] ?? false;

    // Optimistic update
    _favoriteStatus[product.id] = !currentStatus;
    notifyListeners();

    try {
      if (currentStatus) {
        await _apiService.removeFromFavorites(product.id);
      } else {
        await _apiService.addToFavorites(product.id);
      }
    } catch (e) {
      // Revert if failed
      _favoriteStatus[product.id] = currentStatus;
      notifyListeners();
      rethrow;
    }
  }
}
