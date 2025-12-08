import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service wrapper for FlutterSecureStorage to manage sensitive data like auth tokens
class SecureStorageService {
  // Private constructor
  SecureStorageService._();

  // Singleton instance
  static final SecureStorageService instance = SecureStorageService._();

  // Storage instance
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';
  static const String _roleKey = 'auth_role';
  static const String _emailKey = 'auth_email';
  static const String _fullNameKey = 'auth_full_name';

  // Token Methods
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Refresh Token Methods
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // User details methods (Stored securely as well for consistency, though less critical)
  Future<void> setUserId(String id) async {
    await _storage.write(key: _userIdKey, value: id);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> setRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  Future<void> setEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<void> setFullName(String name) async {
    await _storage.write(key: _fullNameKey, value: name);
  }

  Future<String?> getFullName() async {
    return await _storage.read(key: _fullNameKey);
  }

  // Clear all auth data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
