import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/secure_storage_service.dart';

class LocalizationProvider with ChangeNotifier {
  LocalizationProvider() {
    _loadPreferences();
  }
  Locale _locale = const Locale('ar');
  String _currency = 'TRY';
  String? _timeZone;
  String? _dateFormat;
  String? _timeFormat;
  final ApiService _apiService = ApiService();

  Locale get locale => _locale;
  String get currency => _currency;
  String? get timeZone => _timeZone;
  String? get dateFormat => _dateFormat;
  String? get timeFormat => _timeFormat;

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language') ?? 'tr';
      final currencyCode = prefs.getString('currency') ?? 'TRY';

      _locale = Locale(languageCode);
      _currency = currencyCode;
      _timeZone = prefs.getString('timeZone');
      _dateFormat = prefs.getString('dateFormat') ?? 'dd/MM/yyyy';
      _timeFormat = prefs.getString('timeFormat') ?? '24h';

      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error('Error loading preferences', e, stackTrace);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    if (languageCode == _locale.languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);

      final token = await SecureStorageService.instance.getToken();
      if (token != null) {
        await _apiService.updateUserPreferences(language: languageCode);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error saving language', e, stackTrace);
    }
  }

  Future<void> setCurrency(String currencyCode) async {
    if (currencyCode == _currency) return;

    _currency = currencyCode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', currencyCode);

      final token = await SecureStorageService.instance.getToken();
      if (token != null) {
        await _apiService.updateUserPreferences(currency: currencyCode);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error saving currency', e, stackTrace);
    }
  }

  Future<void> setTimeZone(String? timeZone) async {
    _timeZone = timeZone;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (timeZone != null) {
        await prefs.setString('timeZone', timeZone);
      } else {
        await prefs.remove('timeZone');
      }

      final token = await SecureStorageService.instance.getToken();
      if (token != null) {
        await _apiService.updateUserPreferences(timeZone: timeZone);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error saving timezone', e, stackTrace);
    }
  }

  Future<void> setDateFormat(String? dateFormat) async {
    _dateFormat = dateFormat ?? 'dd/MM/yyyy';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dateFormat', _dateFormat!);

      final token = await SecureStorageService.instance.getToken();
      if (token != null) {
        await _apiService.updateUserPreferences(dateFormat: _dateFormat);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error saving date format', e, stackTrace);
    }
  }

  Future<void> setTimeFormat(String? timeFormat) async {
    _timeFormat = timeFormat ?? '24h';
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('timeFormat', _timeFormat!);

      final token = await SecureStorageService.instance.getToken();
      if (token != null) {
        await _apiService.updateUserPreferences(timeFormat: _timeFormat);
      }
    } catch (e, stackTrace) {
      LoggerService().error('Error saving time format', e, stackTrace);
    }
  }

  Future<void> loadFromServer() async {
    try {
      final preferences = await _apiService.getUserPreferences();

      _locale = Locale(preferences['language'] ?? 'tr');
      _currency = preferences['currency'] ?? 'TRY';
      _timeZone = preferences['timeZone'];
      _dateFormat = preferences['dateFormat'] ?? 'dd/MM/yyyy';
      _timeFormat = preferences['timeFormat'] ?? '24h';

      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _locale.languageCode);
      await prefs.setString('currency', _currency);
      if (_timeZone != null) {
        await prefs.setString('timeZone', _timeZone!);
      }
      await prefs.setString('dateFormat', _dateFormat ?? 'dd/MM/yyyy');
      await prefs.setString('timeFormat', _timeFormat ?? '24h');

      notifyListeners();
    } catch (e, stackTrace) {
      LoggerService().error(
        'Error loading preferences from server',
        e,
        stackTrace,
      );
    }
  }
}
