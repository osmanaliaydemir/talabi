import 'package:flutter/material.dart';
import 'package:mobile/features/profile/data/models/address.dart';
import 'package:mobile/services/api_service.dart';

class AddressProvider extends ChangeNotifier {
  AddressProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();
  final ApiService _apiService;
  List<Address> _addresses = [];
  bool _isLoading = false;
  String? _error;

  // Location Data State
  List<Map<String, dynamic>> _countries = [];
  List<Map<String, dynamic>> _cities = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _localities = [];
  bool _isLoadingLocations = false;

  List<Address> get addresses => _addresses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> get countries => _countries;
  List<Map<String, dynamic>> get cities => _cities;
  List<Map<String, dynamic>> get districts => _districts;
  List<Map<String, dynamic>> get localities => _localities;
  bool get isLoadingLocations => _isLoadingLocations;

  /// Loads the user's addresses from the backend.
  /// Sets [isLoading] to true while fetching and updates [_addresses].
  /// If an error occurs, [_error] is updated.
  Future<void> loadAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final addressesData = await _apiService.getAddresses();
      _addresses = addressesData.map((data) => Address.fromJson(data)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes an address by its [id].
  /// Reloads the address list upon success.
  Future<void> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.deleteAddress(id);
      await loadAddresses(); // Reload list
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sets an address as the default delivery address.
  /// [id] is the address identifier.
  /// Reloads the address list upon success.
  Future<void> setDefaultAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.setDefaultAddress(id);
      await loadAddresses(); // Reload list
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Creates or updates an address.
  /// If [id] is null, a new address is created with [data].
  /// If [id] is provided, the existing address is updated.
  /// [data] should contain address fields matched to the backend API.
  Future<void> saveAddress(Map<String, dynamic> data, {String? id}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (id == null) {
        await _apiService.createAddress(data);
      } else {
        await _apiService.updateAddress(id, data);
      }
      // We don't necessarily need to reload addresses here if we are going back to the list screen which reloads,
      // but it's good practice to keep state fresh.
      await loadAddresses();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Location Data Methods

  Future<void> loadCountries() async {
    _isLoadingLocations = true;
    notifyListeners();
    try {
      _countries = await _apiService.getCountries();
    } catch (e) {
      debugPrint('Error loading countries: $e');
    } finally {
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  Future<void> loadCities(String countryId) async {
    _isLoadingLocations = true;
    notifyListeners();
    try {
      _cities = await _apiService.getLocationCities(countryId);
    } catch (e) {
      debugPrint('Error loading cities: $e');
    } finally {
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  Future<void> loadDistricts(String cityId) async {
    _isLoadingLocations = true;
    notifyListeners();
    try {
      _districts = await _apiService.getLocationDistricts(cityId);
    } catch (e) {
      debugPrint('Error loading districts: $e');
    } finally {
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  Future<void> loadLocalities(String districtId) async {
    _isLoadingLocations = true;
    notifyListeners();
    try {
      _localities = await _apiService.getLocationLocalities(districtId);
    } catch (e) {
      debugPrint('Error loading localities: $e');
    } finally {
      _isLoadingLocations = false;
      notifyListeners();
    }
  }

  void clearLocationData() {
    _cities = [];
    _districts = [];
    _localities = [];
    notifyListeners();
  }
}
