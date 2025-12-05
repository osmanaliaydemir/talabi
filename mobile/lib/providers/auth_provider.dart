import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/preferences_service.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _refreshToken;
  String? _userId;
  String? _email;
  String? _fullName;
  String? _role;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get role => _role;

  Future<void> login(String email, String password) async {
    final apiService = ApiService();
    final response = await apiService.login(email, password);

    _token = response['token'];
    _refreshToken = response['refreshToken'];
    _userId = response['userId'];
    _email = response['email'];
    _fullName = response['fullName'];
    _role = response['role'];

    // Save to shared preferences
    final prefs = await PreferencesService.instance;
    await prefs.setString('token', _token!);
    if (_refreshToken != null) {
      await prefs.setString('refreshToken', _refreshToken!);
    }
    await prefs.setString('userId', _userId!);
    await prefs.setString('email', _email!);
    await prefs.setString('fullName', _fullName!);
    if (_role != null) {
      await prefs.setString('role', _role!);
    }

    // Analytics
    await AnalyticsService.setUserId(_userId!);
    await AnalyticsService.logLogin(method: 'email');

    notifyListeners();
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      print('🟡 [AUTH_PROVIDER] Register called');
      print('🟡 [AUTH_PROVIDER] Email: $email');
      print('🟡 [AUTH_PROVIDER] FullName: $fullName');

      final apiService = ApiService();
      final response = await apiService.register(email, password, fullName);

      print('🟢 [AUTH_PROVIDER] Register response received');
      print('🟢 [AUTH_PROVIDER] Response keys: ${response.keys}');
      print('🟢 [AUTH_PROVIDER] Response: $response');

      // Note: Register usually doesn't return tokens if email verification is required
      // But if it does, we handle it.
      if (response.containsKey('token')) {
        _token = response['token'];
        _userId = response['userId'];
        _email = response['email'];
        _fullName = response['fullName'];

        if (response.containsKey('refreshToken')) {
          _refreshToken = response['refreshToken'];
        }

        print('🟢 [AUTH_PROVIDER] Token: ${_token != null ? "Set" : "Null"}');
        print('🟢 [AUTH_PROVIDER] UserId: $_userId');
        print('🟢 [AUTH_PROVIDER] Email: $_email');
        print('🟢 [AUTH_PROVIDER] FullName: $_fullName');

        // Save to shared preferences
        final prefs = await PreferencesService.instance;
        await prefs.setString('token', _token!);
        if (_refreshToken != null) {
          await prefs.setString('refreshToken', _refreshToken!);
        }
        await prefs.setString('userId', _userId!);
        await prefs.setString('email', _email!);
        await prefs.setString('fullName', _fullName!);

        print('🟢 [AUTH_PROVIDER] Data saved to SharedPreferences');

        // Analytics
        await AnalyticsService.setUserId(_userId!);
        await AnalyticsService.logSignUp(method: 'email');

        notifyListeners();
      }
    } catch (e, stackTrace) {
      print('🔴 [AUTH_PROVIDER] Register failed: $e');
      print('🔴 [AUTH_PROVIDER] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<String?> logout() async {
    // Logout öncesi role bilgisini sakla
    final roleBeforeLogout = _role;

    _token = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _fullName = null;
    _role = null;

    final prefs = await PreferencesService.instance;
    await prefs.clear();

    // Analytics - clear user id (pass empty string or handle in service, usually null is not allowed in setUserId but we can just not set it or set to empty)
    // Firebase setUserId accepts nullable String?
    await AnalyticsService.setUserId('');

    notifyListeners();

    // Role bilgisini döndür ki logout sonrası doğru login sayfasına yönlendirilebilsin
    return roleBeforeLogout;
  }

  Future<void> tryAutoLogin() async {
    // Use cached instance if available for faster startup
    final prefs =
        PreferencesService.cachedInstance ?? await PreferencesService.instance;

    if (!prefs.containsKey('token')) {
      return; // Fast exit if no token
    }

    // Load token and user data from cache (no network request)
    _token = prefs.getString('token');
    _refreshToken = prefs.getString('refreshToken');
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _fullName = prefs.getString('fullName');
    _role = prefs.getString('role');

    // Token validation could be added here (JWT decode, expiry check)
    // For now, we trust the cached token and validate on first API call

    if (_userId != null) {
      await AnalyticsService.setUserId(_userId!);
    }

    notifyListeners();
  }

  Future<void> setAuthData(
    String token,
    String refreshToken,
    String userId,
    String role,
  ) async {
    _token = token;
    _refreshToken = refreshToken;
    _userId = userId;
    _role = role;

    await AnalyticsService.setUserId(userId);

    notifyListeners();
  }
}
