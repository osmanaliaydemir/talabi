import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

class ThemeProvider with ChangeNotifier {
  ThemeProvider() {
    _loadSettings();
  }

  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  double _textScaleFactor = 0.8;
  MainCategory? _currentCategory;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  double get textScaleFactor => _textScaleFactor;
  MainCategory? get currentCategory => _currentCategory;

  // Renk Tanımları (Backward compatibility için)
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color darkOrange = Color(0xFFF57C00);
  static const Color lightOrange = Color(0xFFFFB74D);

  /// BottomNavProvider'dan kategori değişikliğini dinlemek için
  void setCategory(MainCategory category) {
    if (_currentCategory != category) {
      _currentCategory = category;
      notifyListeners();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('themeMode') ?? 0;
    _themeMode = ThemeMode.values[themeIndex];
    _isHighContrast = prefs.getBool('isHighContrast') ?? false;
    _textScaleFactor = prefs.getDouble('textScaleFactor') ?? 0.8;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
    notifyListeners();
  }

  Future<void> toggleHighContrast(bool value) async {
    _isHighContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isHighContrast', value);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double value) async {
    _textScaleFactor = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('textScaleFactor', value);
    notifyListeners();
  }

  ThemeData get lightTheme {
    // Eğer kategori seçilmişse, VendorType'a göre theme döndür
    if (_currentCategory != null) {
      return AppTheme.getThemeForVendorType(_currentCategory!);
    }

    // Backward compatibility: Eski theme (Restaurant varsayılan)
    return AppTheme.getThemeForVendorType(MainCategory.restaurant);
  }

  ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastLight(
        primary: Colors.blue,
        secondary: Colors.yellow,
      ),

      // 🎨 FONTS - High Contrast (Asset fontları kullan)
      textTheme: TextTheme(
        bodyLarge: AppTheme.poppins(),
        bodyMedium: AppTheme.poppins(),
        bodySmall: AppTheme.poppins(),
      ),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: AppTheme.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
