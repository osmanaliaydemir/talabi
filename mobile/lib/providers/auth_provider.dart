import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Save to secure storage
    final secureStorage = SecureStorageService.instance;
    await secureStorage.setToken(_token!);
    if (_refreshToken != null) {
      await secureStorage.setRefreshToken(_refreshToken!);
    }
    await secureStorage.setUserId(_userId!);
    await secureStorage.setEmail(_email!);
    await secureStorage.setFullName(_fullName!);
    if (_role != null) {
      await secureStorage.setRole(_role!);
    }

    // Also save to SharedPreferences for ApiService interceptor
    // ApiService interceptor reads from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    if (_refreshToken != null) {
      await prefs.setString('refreshToken', _refreshToken!);
    }

    // Analytics
    await AnalyticsService.setUserId(_userId!);
    await AnalyticsService.logLogin(method: 'email');

    notifyListeners();
  }

  Future<void> register(String email, String password, String fullName) async {
    try {
      LoggerService().debug('🟡 [AUTH_PROVIDER] Register called');
      LoggerService().debug('🟡 [AUTH_PROVIDER] Email: $email');
      LoggerService().debug('🟡 [AUTH_PROVIDER] FullName: $fullName');

      final apiService = ApiService();
      final response = await apiService.register(email, password, fullName);

      LoggerService().debug('🟢 [AUTH_PROVIDER] Register response received');
      LoggerService().debug(
        '🟢 [AUTH_PROVIDER] Response keys: ${response.keys}',
      );
      LoggerService().debug('🟢 [AUTH_PROVIDER] Response: $response');

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

        LoggerService().debug(
          '🟢 [AUTH_PROVIDER] Token: ${_token != null ? "Set" : "Null"}',
        );
        LoggerService().debug('🟢 [AUTH_PROVIDER] UserId: $_userId');
        LoggerService().debug('🟢 [AUTH_PROVIDER] Email: $_email');
        LoggerService().debug('🟢 [AUTH_PROVIDER] FullName: $_fullName');

        // Save to secure storage
        final secureStorage = SecureStorageService.instance;
        await secureStorage.setToken(_token!);
        if (_refreshToken != null) {
          await secureStorage.setRefreshToken(_refreshToken!);
        }
        await secureStorage.setUserId(_userId!);
        await secureStorage.setEmail(_email!);
        await secureStorage.setFullName(_fullName!);

        // Also save to SharedPreferences for ApiService interceptor
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        if (_refreshToken != null) {
          await prefs.setString('refreshToken', _refreshToken!);
        }

        LoggerService().debug(
          '🟢 [AUTH_PROVIDER] Data saved to Secure Storage',
        );

        // Analytics
        await AnalyticsService.setUserId(_userId!);
        await AnalyticsService.logSignUp(method: 'email');

        notifyListeners();
      }
    } catch (e, stackTrace) {
      LoggerService().error(
        '🔴 [AUTH_PROVIDER] Register failed',
        e,
        stackTrace,
      );
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

    // Clear secure storage
    final secureStorage = SecureStorageService.instance;
    await secureStorage.clearAll();

    // Clear SharedPreferences (ApiService interceptor reads from here)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('refreshToken');

    // Analytics - clear user id
    await AnalyticsService.setUserId('');

    notifyListeners();

    // Role bilgisini döndür ki logout sonrası doğru login sayfasına yönlendirilebilsin
    return roleBeforeLogout;
  }

  Future<void> tryAutoLogin() async {
    final secureStorage = SecureStorageService.instance;
    final storedToken = await secureStorage.getToken();

    if (storedToken == null) {
      return; // Fast exit if no token
    }

    // Load token and user data from secure storage
    _token = storedToken;
    _refreshToken = await secureStorage.getRefreshToken();
    _userId = await secureStorage.getUserId();
    _email = await secureStorage.getEmail();
    _fullName = await secureStorage.getFullName();
    _role = await secureStorage.getRole();

    // Also save to SharedPreferences for ApiService interceptor
    // ApiService interceptor reads from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    if (_refreshToken != null) {
      await prefs.setString('refreshToken', _refreshToken!);
    }

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

    // Also likely update storage here if this method is used to persist external auth updates
    final secureStorage = SecureStorageService.instance;
    await secureStorage.setToken(token);
    await secureStorage.setRefreshToken(refreshToken);
    await secureStorage.setUserId(userId);
    await secureStorage.setRole(role);

    // Also save to SharedPreferences for ApiService interceptor
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('refreshToken', refreshToken);

    notifyListeners();
  }
}
