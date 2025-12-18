import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/role_mismatch_exception.dart';
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
  bool _isActive = true;
  bool _isProfileComplete = true;
  bool _hasDeliveryZones =
      false; // Default false until proven otherwise for vendors

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get userId => _userId;
  String? get email => _email;
  String? get fullName => _fullName;
  String? get role => _role;
  bool get isActive => _isActive;
  bool get isProfileComplete => _isProfileComplete;
  bool get hasDeliveryZones => _hasDeliveryZones;

  void updateHasDeliveryZones(bool value) {
    _hasDeliveryZones = value;
    notifyListeners();
  }

  Future<void> login(
    String email,
    String password, {
    String? requiredRole,
  }) async {
    final response =
        await (ApiService()..resetLogout()) // Ensure we can make requests
            .login(email, password);

    _token = response['token'];
    _refreshToken = response['refreshToken'];
    _userId = response['userId'];
    _email = response['email'];
    _fullName = response['fullName'];

    // Robust role extraction
    _role = response['role'] ?? response['Role'];

    // isActive extraction
    _isActive = response['isActive'] ?? response['IsActive'] ?? true;
    _isProfileComplete = _isProfileComplete =
        response['isProfileComplete'] ?? response['IsProfileComplete'] ?? true;
    _hasDeliveryZones =
        response['hasDeliveryZones'] ?? response['HasDeliveryZones'] ?? false;

    // Fallback: Extract from token if missing
    if ((_role == null || response['isActive'] == null) && _token != null) {
      try {
        _role ??= _getRoleFromToken(_token!);
        // If isActive wasn't in response, try to get from token
        if (response['isActive'] == null && response['IsActive'] == null) {
          _isActive = _getIsActiveFromToken(_token!);
        }
        if (response['isProfileComplete'] == null &&
            response['IsProfileComplete'] == null) {
          _isProfileComplete = _getIsProfileCompleteFromToken(_token!);
        }
        if (response['hasDeliveryZones'] == null &&
            response['HasDeliveryZones'] == null) {
          _hasDeliveryZones = _getHasDeliveryZonesFromToken(_token!);
        }
      } catch (e) {
        LoggerService().error('Error extracting data from token', e);
      }
    }

    // Check role requirement
    if (requiredRole != null && _role != requiredRole) {
      final detectedRole = _role;
      // Clean up potentially partial state
      await logout();
      throw RoleMismatchException(detectedRole ?? 'Unknown', requiredRole);
    }

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

      final response =
          await (ApiService()..resetLogout()) // Ensure we can make requests
              .register(email, password, fullName);

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
        _isActive = true; // Default for new registration if token is present
        _isProfileComplete = true; // Default

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

    // Notify ApiService to stop processing requests immediately
    ApiService().notifyLogout();

    _token = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _fullName = null;
    _role = null;
    _isActive = true;
    _isProfileComplete = true;

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

    // Reset logout state for auto-login
    ApiService().resetLogout();

    // Load token and user data from secure storage
    _token = storedToken;
    _refreshToken = await secureStorage.getRefreshToken();
    _userId = await secureStorage.getUserId();
    _email = await secureStorage.getEmail();
    _fullName = await secureStorage.getFullName();
    _role = await secureStorage.getRole();

    // Try to get IsActive from token as it's not currently stored in SecureStorage separately
    if (_token != null) {
      _isActive = _getIsActiveFromToken(_token!);
      _isProfileComplete = _getIsProfileCompleteFromToken(_token!);
    }

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
    _isActive = _getIsActiveFromToken(token); // Attempt to extract IsActive
    _isProfileComplete = _getIsProfileCompleteFromToken(token);

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

  String? _getRoleFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return null;
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is Map<String, dynamic>) {
        // Try standard role claim or Microsoft specific claim
        return payloadMap['role'] ??
            payloadMap['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      }
    } catch (e) {
      // Silent fail or log if needed
    }
    return null;
  }

  bool _getIsActiveFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Default to true on error
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is Map<String, dynamic>) {
        final isActiveClaim = payloadMap['isActive'];
        if (isActiveClaim != null) {
          if (isActiveClaim is bool) return isActiveClaim;
          if (isActiveClaim is String) {
            return isActiveClaim.toLowerCase() == 'true';
          }
        }
      }
    } catch (e) {
      LoggerService().error('Error extracting isActive from token', e);
    }
    return true; // Default to true
  }

  bool _getIsProfileCompleteFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return true; // Default to true on error
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is Map<String, dynamic>) {
        final claim = payloadMap['isProfileComplete'];
        if (claim != null) {
          if (claim is bool) return claim;
          if (claim is String) {
            return claim.toLowerCase() == 'true';
          }
        }
      }
    } catch (e) {
      LoggerService().error('Error extracting isProfileComplete from token', e);
    }
    return true; // Default to true
  }

  bool _getHasDeliveryZonesFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return false; // Default false
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      if (payloadMap is Map<String, dynamic>) {
        final claim = payloadMap['hasDeliveryZones'];
        if (claim != null) {
          if (claim is bool) return claim;
          if (claim is String) {
            return claim.toLowerCase() == 'true';
          }
        }
      }
    } catch (e) {
      LoggerService().error('Error extracting hasDeliveryZones from token', e);
    }
    return false; // Default false
  }
}
