import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';

class VendorProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _vendorProfile;
  int _currentStatus = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  int get currentStatus => _currentStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get vendorProfile => _vendorProfile;

  Future<void> loadVendorProfile({bool force = false}) async {
    // Return if already loaded and not forced
    if (_vendorProfile != null && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profile = await _apiService.getVendorProfile();
      _vendorProfile = profile;
      _currentStatus = profile['busyStatus'] as int? ?? 0;
      _isLoading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error(
        'VendorProvider: Error loading profile',
        e,
        stackTrace,
      );
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBusyStatus(int status) async {
    // Optimistic update
    final int previousStatus = _currentStatus;
    _currentStatus = status;
    notifyListeners();

    try {
      await _apiService.updateBusyStatus(status);
      // Update local profile copy if exists
      if (_vendorProfile != null) {
        _vendorProfile!['busyStatus'] = status;
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        'VendorProvider: Error updating busy status',
        e,
        stackTrace,
      );
      // Revert on error
      _currentStatus = previousStatus;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
