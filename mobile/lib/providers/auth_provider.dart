import 'package:flutter/foundation.dart';
import 'package:mobile/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  String? _userId;
  String? _email;
  String? _fullName;

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  String? get email => _email;
  String? get fullName => _fullName;

  Future<void> login(String email, String password) async {
    final apiService = ApiService();
    final response = await apiService.login(email, password);

    _token = response['token'];
    _userId = response['userId'];
    _email = response['email'];
    _fullName = response['fullName'];

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('userId', _userId!);
    await prefs.setString('email', _email!);
    await prefs.setString('fullName', _fullName!);

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

      _token = response['token'];
      _userId = response['userId'];
      _email = response['email'];
      _fullName = response['fullName'];

      print('🟢 [AUTH_PROVIDER] Token: ${_token != null ? "Set" : "Null"}');
      print('🟢 [AUTH_PROVIDER] UserId: $_userId');
      print('🟢 [AUTH_PROVIDER] Email: $_email');
      print('🟢 [AUTH_PROVIDER] FullName: $_fullName');

      // Save to shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userId', _userId!);
      await prefs.setString('email', _email!);
      await prefs.setString('fullName', _fullName!);

      print('🟢 [AUTH_PROVIDER] Data saved to SharedPreferences');
      notifyListeners();
    } catch (e, stackTrace) {
      print('🔴 [AUTH_PROVIDER] Register failed: $e');
      print('🔴 [AUTH_PROVIDER] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _email = null;
    _fullName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) {
      return;
    }

    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _fullName = prefs.getString('fullName');

    notifyListeners();
  }
}
