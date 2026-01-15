import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/utils/role_mismatch_exception.dart';
import 'package:mobile/services/analytics_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/services/social_auth_service.dart';
import 'package:mobile/services/signalr_service.dart';
import 'package:mobile/config/injection.dart';

class AuthProvider with ChangeNotifier {
  AuthProvider({
    ApiService? apiService,
    SecureStorageService? secureStorage,
    SignalRService? signalRService,
  }) : _apiService = apiService ?? ApiService(),
       _secureStorage = secureStorage ?? SecureStorageService.instance,
       _signalRService = signalRService ?? getIt<SignalRService>();

  final ApiService _apiService;
  final SecureStorageService _secureStorage;
  final SignalRService _signalRService;

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
  bool _isLoading = false;

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
  bool get isLoading => _isLoading;

  void updateHasDeliveryZones(bool value) {
    _hasDeliveryZones = value;
    notifyListeners();
  }

  /// Logs in the user with email and password.
  ///
  /// [email] and [password] are required.
  /// [requiredRole] ensures that the logged-in user has the expected role (e.g., 'Vendor').
  /// Throws [RoleMismatchException] if the role does not match.
  Future<void> login(
    String email,
    String password, {
    String? requiredRole,
  }) async {
    final response =
        await (_apiService..resetLogout()) // Ensure we can make requests
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
    await _secureStorage.setToken(_token!);
    if (_refreshToken != null) {
      await _secureStorage.setRefreshToken(_refreshToken!);
    }
    await _secureStorage.setUserId(_userId!);
    await _secureStorage.setEmail(_email!);
    await _secureStorage.setFullName(_fullName!);
    if (_role != null) {
      await _secureStorage.setRole(_role!);
    }

    // Analytics
    await AnalyticsService.setUserId(_userId!);
    await AnalyticsService.logLogin(method: 'email');

    // Start SignalR connection if user is a courier
    if (_role == 'Courier') {
      // Removed Driver check as we might specificy Courier only, or enable for both. Keeping strict 'Courier' for now based on context.
      // Delay slightly to ensure token is fully persisted/available if needed by other components
      Future.delayed(const Duration(seconds: 1), () {
        _signalRService.startConnection();
      });
    }

    notifyListeners();
  }

  /// Registers a new customer user.
  ///
  /// Takes [email], [password], and [fullName].
  /// If registration returns a token immediately (no verification flow), it logs the user in.
  Future<void> register(String email, String password, String fullName) async {
    try {
      final response =
          await (_apiService..resetLogout()) // Ensure we can make requests
              .register(email, password, fullName);

      // Note: Register usually doesn't return tokens if email verification is required
      // But if it does, we handle it.
      if (response.containsKey('token')) {
        _token = response['token'];
        _userId = response['userId'];
        _email = response['email'];
        _fullName = response['fullName'];
        _role = response['role'] ?? response['Role']; // Extract role
        _isActive = response['isActive'] ?? response['IsActive'] ?? true;
        _isProfileComplete =
            response['isProfileComplete'] ??
            response['IsProfileComplete'] ??
            true;

        if (response.containsKey('refreshToken')) {
          _refreshToken = response['refreshToken'];
        }

        // Save to secure storage
        await _secureStorage.setToken(_token!);
        if (_refreshToken != null) {
          await _secureStorage.setRefreshToken(_refreshToken!);
        }
        await _secureStorage.setUserId(_userId!);
        await _secureStorage.setEmail(_email!);
        await _secureStorage.setFullName(_fullName!);
        if (_role != null) {
          await _secureStorage.setRole(_role!);
        }

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

  /// Initiates Google Sign-In flow.
  ///
  /// Uses [SocialAuthService] to authenticate with Google.
  /// Updates auth state upon success.
  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final socialAuthService = SocialAuthService();
      final response = await socialAuthService.signInWithGoogle();

      if (response == null) {
        return;
      }

      await setAuthData(
        response['token'],
        response['refreshToken'],
        response['userId'],
        response['role'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates Facebook Sign-In flow.
  ///
  /// Uses [SocialAuthService] to authenticate with Facebook.
  /// Updates auth state upon success.
  Future<void> signInWithFacebook() async {
    _isLoading = true;
    notifyListeners();

    try {
      final socialAuthService = SocialAuthService();
      final response = await socialAuthService.signInWithFacebook();

      if (response == null) {
        return;
      }

      await setAuthData(
        response['token'],
        response['refreshToken'],
        response['userId'],
        response['role'],
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out the current user.
  ///
  /// Clears tokens, user data, and secure storage.
  /// Returns the role of the user before logout to facilitate navigation.
  Future<String?> logout() async {
    // Logout öncesi role bilgisini sakla
    final roleBeforeLogout = _role;

    // Notify ApiService to stop processing requests immediately
    _apiService.notifyLogout();

    _token = null;
    _refreshToken = null;
    _userId = null;
    _email = null;
    _fullName = null;
    _role = null;
    _isActive = true;
    _isProfileComplete = true;

    // Clear secure storage
    await _secureStorage.clearAll();

    // Clear SharedPreferences (ApiService interceptor reads from here)
    // Removed as part of secure storage migration
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('token');
    // await prefs.remove('refreshToken');

    // Stop SignalR connection
    await _signalRService.stopConnection();

    // Analytics - clear user id
    await AnalyticsService.setUserId('');

    notifyListeners();

    // Role bilgisini döndür ki logout sonrası doğru login sayfasına yönlendirilebilsin
    return roleBeforeLogout;
  }

  /// Attempts to auto-login using the stored token.
  ///
  /// Checks SecureStorage for a valid token. If found, restores user session.
  Future<void> tryAutoLogin() async {
    final storedToken = await _secureStorage.getToken();

    if (storedToken == null) {
      return; // Fast exit if no token
    }

    // Reset logout state for auto-login
    _apiService.resetLogout();

    // Load token and user data from secure storage
    _token = storedToken;
    _refreshToken = await _secureStorage.getRefreshToken();
    _userId = await _secureStorage.getUserId();
    _email = await _secureStorage.getEmail();
    _fullName = await _secureStorage.getFullName();
    _role = await _secureStorage.getRole();

    // Try to get IsActive from token as it's not currently stored in SecureStorage separately
    if (_token != null) {
      _isActive = _getIsActiveFromToken(_token!);
      _isProfileComplete = _getIsProfileCompleteFromToken(_token!);
    }

    // Token validation could be added here (JWT decode, expiry check)
    // For now, we trust the cached token and validate on first API call

    if (_userId != null) {
      await AnalyticsService.setUserId(_userId!);
    }

    // Start SignalR connection if user is a courier (Auto-login case)
    if (_role == 'Courier') {
      Future.delayed(const Duration(seconds: 1), () {
        _signalRService.startConnection();
      });
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
    await _secureStorage.setToken(token);
    await _secureStorage.setRefreshToken(refreshToken);
    await _secureStorage.setUserId(userId);
    await _secureStorage.setRole(role);

    // Start SignalR if courier
    if (_role == 'Courier') {
      Future.delayed(const Duration(seconds: 1), () {
        _signalRService.startConnection();
      });
    }

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
