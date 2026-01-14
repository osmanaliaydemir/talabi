import 'package:flutter/foundation.dart';
import 'package:mobile/features/vendors/data/models/vendor.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/location_extractor.dart';

/// Provider for vendor list screen with pagination state.
class VendorListProvider with ChangeNotifier {
  VendorListProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  final List<Vendor> _vendors = [];
  int _currentPage = 1;
  static const int pageSize = 6;
  bool _isFirstLoad = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;

  List<Vendor> get vendors => List.unmodifiable(_vendors);
  bool get isFirstLoad => _isFirstLoad;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreData => _hasMoreData;
  int get currentPage => _currentPage;

  void reset() {
    _vendors.clear();
    _currentPage = 1;
    _isFirstLoad = true;
    _isLoadingMore = false;
    _hasMoreData = true;
    notifyListeners();
  }

  Future<void> loadVendors({
    required int vendorType,
    required Map<String, dynamic>? selectedAddress,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _vendors.clear();
      _currentPage = 1;
      _hasMoreData = true;
      _isFirstLoad = true;
      _isLoadingMore = false;
      notifyListeners();
    } else {
      if (_isLoadingMore || !_hasMoreData) return;
      _isLoadingMore = true;
      _currentPage++;
      notifyListeners();
    }

    final location = LocationExtractor.fromAddress(selectedAddress);
    final userLatitude = location.latitude;
    final userLongitude = location.longitude;

    try {
      final pageVendors = await _apiService.getVendors(
        vendorType: vendorType,
        page: _currentPage,
        pageSize: pageSize,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      if (isRefresh) {
        _vendors
          ..clear()
          ..addAll(pageVendors);
      } else {
        _vendors.addAll(pageVendors);
      }

      _isFirstLoad = false;
      _isLoadingMore = false;
      if (pageVendors.length < pageSize) {
        _hasMoreData = false;
      }
      notifyListeners();
    } catch (_) {
      _isFirstLoad = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }
}
