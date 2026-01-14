import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile/features/search/data/models/search_dtos.dart';

import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing search state and business logic.
class SearchProvider with ChangeNotifier {
  SearchProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // Search state
  String _currentQuery = '';
  List<AutocompleteResultDto> _autocompleteResults = [];
  bool _showAutocomplete = false;

  // Products search
  List<ProductDto> _productItems = [];
  int _productCurrentPage = 1;
  static const int _productPageSize = 20;
  bool _isLoadingProducts = false;
  bool _isLoadingMoreProducts = false;
  bool _hasMoreProducts = true;

  // Vendors search
  List<VendorDto> _vendorItems = [];
  int _vendorCurrentPage = 1;
  static const int _vendorPageSize = 20;
  bool _isLoadingVendors = false;
  bool _isLoadingMoreVendors = false;
  bool _hasMoreVendors = true;

  // Filters
  String? _selectedCategoryId;
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  double? _maxDistance;
  String? _sortBy;

  // Filter options
  List<Map<String, dynamic>> _categories = [];
  List<String> _cities = [];
  bool _hasLoadedFilterOptions = false;

  // Search history
  List<String> _searchHistory = [];

  // Getters
  String get currentQuery => _currentQuery;
  List<AutocompleteResultDto> get autocompleteResults => _autocompleteResults;
  bool get showAutocomplete => _showAutocomplete;
  List<ProductDto> get productItems => _productItems;
  List<VendorDto> get vendorItems => _vendorItems;
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingMoreProducts => _isLoadingMoreProducts;
  bool get isLoadingVendors => _isLoadingVendors;
  bool get isLoadingMoreVendors => _isLoadingMoreVendors;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get hasMoreVendors => _hasMoreVendors;
  String? get selectedCategoryId => _selectedCategoryId;
  String? get selectedCity => _selectedCity;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  double? get maxDistance => _maxDistance;
  String? get sortBy => _sortBy;
  List<Map<String, dynamic>> get categories => _categories;
  List<String> get cities => _cities;
  List<String> get searchHistory => _searchHistory;
  bool get hasLoadedFilterOptions => _hasLoadedFilterOptions;

  /// Check if any filters are active
  bool hasActiveFilters() {
    return _selectedCategoryId != null ||
        _selectedCity != null ||
        _minPrice != null ||
        _maxPrice != null ||
        _minRating != null ||
        _maxDistance != null ||
        _sortBy != null;
  }

  /// Load search history from SharedPreferences
  Future<void> loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? [];
      _searchHistory = history;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error loading search history', e, stackTrace);
    }
  }

  /// Save query to search history
  Future<void> saveToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('search_history') ?? []
        ..remove(query)
        ..insert(0, query);
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }

      await prefs.setStringList('search_history', history);
      _searchHistory = history;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error saving search history', e, stackTrace);
    }
  }

  /// Set current search query
  void setQuery(String query) {
    if (_currentQuery != query) {
      _currentQuery = query;
      notifyListeners();
    }
  }

  /// Set autocomplete visibility
  void setShowAutocomplete(bool show) {
    if (_showAutocomplete != show) {
      _showAutocomplete = show;
      notifyListeners();
    }
  }

  /// Set filter values
  void setFilters({
    String? categoryId,
    String? city,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    double? maxDistance,
    String? sortBy,
  }) {
    bool changed = false;

    if (_selectedCategoryId != categoryId) {
      _selectedCategoryId = categoryId;
      changed = true;
    }
    if (_selectedCity != city) {
      _selectedCity = city;
      changed = true;
    }
    if (_minPrice != minPrice) {
      _minPrice = minPrice;
      changed = true;
    }
    if (_maxPrice != maxPrice) {
      _maxPrice = maxPrice;
      changed = true;
    }
    if (_minRating != minRating) {
      _minRating = minRating;
      changed = true;
    }
    if (_maxDistance != maxDistance) {
      _maxDistance = maxDistance;
      changed = true;
    }
    if (_sortBy != sortBy) {
      _sortBy = sortBy;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Clear all filters
  void clearFilters() {
    bool changed = false;

    if (_selectedCategoryId != null) {
      _selectedCategoryId = null;
      changed = true;
    }
    if (_selectedCity != null) {
      _selectedCity = null;
      changed = true;
    }
    if (_minPrice != null) {
      _minPrice = null;
      changed = true;
    }
    if (_maxPrice != null) {
      _maxPrice = null;
      changed = true;
    }
    if (_minRating != null) {
      _minRating = null;
      changed = true;
    }
    if (_maxDistance != null) {
      _maxDistance = null;
      changed = true;
    }
    if (_sortBy != null) {
      _sortBy = null;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Clear search results
  void clearResults() {
    _productItems = [];
    _vendorItems = [];
    _productCurrentPage = 1;
    _vendorCurrentPage = 1;
    _hasMoreProducts = false;
    _hasMoreVendors = false;
    notifyListeners();
  }

  /// Load filter options (categories and cities)
  Future<void> loadFilterOptions({
    required String language,
    required int vendorType,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (_hasLoadedFilterOptions) return;

    try {
      final categories = await _apiService.getCategories(
        language: language,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      final cities = await _apiService.getCities();

      _categories = categories;
      _cities = cities;
      _hasLoadedFilterOptions = true;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error loading filter options', e, stackTrace);
    }
  }

  /// Perform autocomplete search
  Future<void> performAutocomplete(
    String query, {
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (query.isEmpty) {
      _autocompleteResults = [];
      _showAutocomplete = false;
      notifyListeners();
      return;
    }

    try {
      final results = await _apiService.autocomplete(
        query,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      _autocompleteResults = results;
      _showAutocomplete = true;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error performing autocomplete', e, stackTrace);
    }
  }

  /// Search products
  Future<void> searchProducts({
    required int vendorType,
    double? userLatitude,
    double? userLongitude,
    bool isRefresh = true,
  }) async {
    // Validate search criteria
    if (_currentQuery.isEmpty &&
        _selectedCategoryId == null &&
        _minPrice == null &&
        _maxPrice == null) {
      _productItems = [];
      _productCurrentPage = 1;
      _hasMoreProducts = false;
      _isLoadingProducts = false;
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _isLoadingProducts = true;
      _productCurrentPage = 1;
      _hasMoreProducts = true;
      _productItems = [];
    } else {
      _isLoadingMoreProducts = true;
    }
    notifyListeners();

    try {
      final request = ProductSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        categoryId: _selectedCategoryId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        vendorType: vendorType,
        sortBy: _sortBy,
        page: _productCurrentPage,
        pageSize: _productPageSize,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      final results = await _apiService.searchProducts(request);

      if (isRefresh) {
        _productItems = results.items;
      } else {
        _productItems.addAll(results.items);
      }
      _isLoadingProducts = false;
      _isLoadingMoreProducts = false;
      _hasMoreProducts =
          results.items.length >= _productPageSize &&
          _productItems.length < results.totalCount;

      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error searching products', e, stackTrace);
      _isLoadingProducts = false;
      _isLoadingMoreProducts = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts({
    required int vendorType,
    double? userLatitude,
    double? userLongitude,
  }) async {
    if (_isLoadingMoreProducts || !_hasMoreProducts || _isLoadingProducts) {
      return;
    }
    _productCurrentPage++;
    await searchProducts(
      vendorType: vendorType,
      userLatitude: userLatitude,
      userLongitude: userLongitude,
      isRefresh: false,
    );
  }

  /// Search vendors
  Future<void> searchVendors({bool isRefresh = true}) async {
    // Validate search criteria
    if (_currentQuery.isEmpty &&
        _selectedCity == null &&
        _minRating == null &&
        _maxDistance == null) {
      _vendorItems = [];
      _vendorCurrentPage = 1;
      _isLoadingVendors = false;
      _hasMoreVendors = false;
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _isLoadingVendors = true;
      _vendorCurrentPage = 1;
      _hasMoreVendors = true;
      _vendorItems = [];
    } else {
      _isLoadingMoreVendors = true;
    }
    notifyListeners();

    try {
      final request = VendorSearchRequestDto(
        query: _currentQuery.isEmpty ? null : _currentQuery,
        city: _selectedCity,
        minRating: _minRating,
        maxDistanceInKm: _maxDistance,
        sortBy: _sortBy,
        page: _vendorCurrentPage,
        pageSize: _vendorPageSize,
      );

      final results = await _apiService.searchVendors(request);

      if (isRefresh) {
        _vendorItems = results.items;
      } else {
        _vendorItems.addAll(results.items);
      }
      _isLoadingVendors = false;
      _isLoadingMoreVendors = false;
      _hasMoreVendors =
          results.items.length >= _vendorPageSize &&
          _vendorItems.length < results.totalCount;

      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error searching vendors', e, stackTrace);
      _isLoadingVendors = false;
      _isLoadingMoreVendors = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Load more vendors (pagination)
  Future<void> loadMoreVendors() async {
    if (_isLoadingMoreVendors || !_hasMoreVendors || _isLoadingVendors) {
      return;
    }
    _vendorCurrentPage++;
    await searchVendors(isRefresh: false);
  }

  /// Submit search query
  Future<void> submitSearch(
    String query, {
    required int vendorType,
    double? userLatitude,
    double? userLongitude,
  }) async {
    _currentQuery = query;
    _showAutocomplete = false;
    notifyListeners();

    await saveToSearchHistory(query);

    // Perform both searches
    await Future.wait([
      searchProducts(
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
      searchVendors(),
    ]);
  }
}
