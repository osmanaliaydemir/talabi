import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mobile/features/campaigns/data/models/campaign.dart';
import 'package:mobile/features/products/data/models/product.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/utils/location_extractor.dart';

/// State container for HomeScreen.
class HomeProvider with ChangeNotifier {
  HomeProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  // State
  bool _isLoading = true;
  bool _isAddressesLoading = true;
  String? _error;

  // Data
  List<Vendor> _vendors = [];
  List<Product> _popularProducts = [];
  List<Map<String, dynamic>> _categories = [];
  List<Campaign> _banners = [];
  List<dynamic> _addresses = [];
  Map<String, dynamic>? _selectedAddress;

  // Favorite status map for products
  final Map<String, bool> _favoriteStatus = {};

  // Getters
  bool get isLoading => _isLoading;
  bool get isAddressesLoading => _isAddressesLoading;
  String? get error => _error;
  List<Vendor> get vendors => _vendors;
  List<Product> get popularProducts => _popularProducts;
  List<Map<String, dynamic>> get categories => _categories;
  List<Campaign> get banners => _banners;
  List<dynamic> get addresses => _addresses;
  Map<String, dynamic>? get selectedAddress => _selectedAddress;
  Map<String, bool> get favoriteStatus => Map.unmodifiable(_favoriteStatus);

  bool get hasVendors => _vendors.isNotEmpty;
  bool get hasProducts => _popularProducts.isNotEmpty;

  /// Initial load of detailed data
  Future<void> loadData({
    required int vendorType,
    bool refreshAddress = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (refreshAddress) {
        await _loadAddressesInternal();
      }

      await _loadHomeContent(vendorType);
      await _loadFavoriteStatus();
    } catch (e, stackTrace) {
      LoggerService().error('Error loading home data', e, stackTrace);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load content based on current location and vendor type
  Future<void> _loadHomeContent(int vendorType) async {
    final location = LocationExtractor.fromAddress(_selectedAddress);
    final userLatitude = location.latitude;
    final userLongitude = location.longitude;

    // Load main content in parallel
    final results = await Future.wait([
      _apiService.getVendors(
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
      _apiService.getPopularProducts(
        page: 1,
        pageSize: 8,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
      _apiService.getCategories(
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      ),
      _loadCampaignsInternal(vendorType),
    ]);

    _vendors = results[0] as List<Vendor>;
    _popularProducts = results[1] as List<Product>;
    _categories = results[2] as List<Map<String, dynamic>>;
    // Campaigns loaded internally
  }

  Future<List<Campaign>> _loadCampaignsInternal(int vendorType) async {
    String? cityId;
    String? districtId;

    if (_selectedAddress != null) {
      if (_selectedAddress!['cityId'] != null) {
        cityId = _selectedAddress!['cityId'].toString();
      }
      if (_selectedAddress!['districtId'] != null) {
        districtId = _selectedAddress!['districtId'].toString();
      }
    }

    final campaigns = await _apiService.getCampaigns(
      vendorType: vendorType,
      cityId: cityId,
      districtId: districtId,
    );
    _banners = campaigns;
    return campaigns;
  }

  /// Load addresses
  Future<void> loadAddresses() async {
    _isAddressesLoading = true;
    notifyListeners();
    try {
      await _loadAddressesInternal();
    } finally {
      _isAddressesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadAddressesInternal() async {
    try {
      final addresses = await _apiService.getAddresses();
      Map<String, dynamic>? selected;
      if (addresses.isNotEmpty) {
        try {
          selected = addresses.firstWhere((addr) => addr['isDefault'] == true);
        } catch (_) {
          selected = addresses.first;
        }
      }
      _addresses = addresses;
      _selectedAddress = selected;
    } catch (e, stackTrace) {
      LoggerService().error('Error loading addresses', e, stackTrace);
      // Don't rethrow, allow UI to show partial state or retry
    }
  }

  /// Load favorites
  Future<void> _loadFavoriteStatus() async {
    try {
      final favoritesResult = await _apiService.getFavorites();
      setFavoritesFromIds(favoritesResult.items.map((fav) => fav.id));
    } catch (e, stackTrace) {
      LoggerService().error('Error loading favorites', e, stackTrace);
    }
  }

  /// Update favorite status from ID list
  void setFavoritesFromIds(Iterable<String> productIds) {
    _favoriteStatus
      ..clear()
      ..addEntries(productIds.map((id) => MapEntry(id, true)));
    // No notifyListeners needed if called within loadData which notifies at end
  }

  /// Toggle favorite status for a single product
  Future<void> toggleFavorite(String productId) async {
    final isFavorite = _favoriteStatus[productId] ?? false;
    // Optimistic update
    _favoriteStatus[productId] = !isFavorite;
    notifyListeners();

    try {
      if (isFavorite) {
        await _apiService.removeFromFavorites(productId);
      } else {
        await _apiService.addToFavorites(productId);
      }
    } catch (e) {
      // Revert on error
      _favoriteStatus[productId] = isFavorite;
      notifyListeners();
      rethrow;
    }
  }

  /// Set selected address manually
  void setSelectedAddress(Map<String, dynamic> address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Set default address
  Future<void> setDefaultAddress(String addressId) async {
    await _apiService.setDefaultAddress(addressId);
    await _loadAddressesInternal();
    notifyListeners();
  }

  // Deprecated setters used by old code - keeping for compatibility during refactor
  // but pointing to internal state where possible
  void setBanners(List<Campaign> banners) {
    _banners = banners;
    notifyListeners();
  }

  void setHasVendors(bool value) {
    // No-op or update internal logic if needed
  }

  void setHasProducts(bool value) {
    // No-op
  }

  void setFavorite(String productId, bool isFavorite) {
    _favoriteStatus[productId] = isFavorite;
    notifyListeners();
  }
}
