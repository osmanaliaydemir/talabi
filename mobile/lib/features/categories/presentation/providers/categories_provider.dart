import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/location_extractor.dart';

/// Provider for managing categories state and loading logic.
class CategoriesProvider with ChangeNotifier {
  CategoriesProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load categories based on vendorType, locale and optional address.
  Future<void> loadCategories({
    required int vendorType,
    required String? locale,
    Map<String, dynamic>? selectedAddress,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final location = LocationExtractor.fromAddress(selectedAddress);
      final userLatitude = location.latitude;
      final userLongitude = location.longitude;

      final result = await _apiService.getCategories(
        language: locale,
        vendorType: vendorType,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );

      _categories = List<Map<String, dynamic>>.from(result);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _categories = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
