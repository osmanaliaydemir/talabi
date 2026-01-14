import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';

class ProfileProvider with ChangeNotifier {
  ProfileProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;

  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await _apiService.getProfile();
      _profile = profile;
    } catch (e) {
      // Error handling can be enhanced here or in UI
      debugPrint('Error fetching profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    notifyListeners();
  }
}
