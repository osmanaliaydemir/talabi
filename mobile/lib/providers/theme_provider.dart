import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isHighContrast = false;
  double _textScaleFactor = 0.8;

  ThemeMode get themeMode => _themeMode;
  bool get isHighContrast => _isHighContrast;
  double get textScaleFactor => _textScaleFactor;

  // Renk Tanımları
  static const Color primaryOrange = Color(0xFFFF9800);
  static const Color darkOrange = Color(0xFFF57C00);
  static const Color lightOrange = Color(0xFFFFB74D);

  ThemeProvider() {
    _loadSettings();
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
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: darkOrange,
        brightness: Brightness.light,
      ),

      // 🎨 GOOGLE FONTS - Poppins
      textTheme: GoogleFonts.poppinsTextTheme(),

      scaffoldBackgroundColor: const Color(0xFFF5F5F5),

      appBarTheme: AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 14),
      ),
    );
  }

  ThemeData get darkTheme {
    // iOS 16+ Dark Mode Renkleri
    const Color darkBackground = Color(0xFF000000); // iOS tam siyah
    const Color darkSurface = Color(0xFF1C1C1E); // iOS surface
    const Color darkCard = Color(0xFF2C2C2E); // iOS secondary surface
    const Color darkTertiary = Color(0xFF3A3A3C); // iOS tertiary surface
    const Color darkDivider = Color(0xFF38383A); // iOS separator
    const Color darkBorder = Color(0xFF545458); // iOS divider
    const Color darkTextPrimary = Color(0xFFFFFFFF);
    const Color darkTextSecondary = Color(0xFFEBEBF5); // 60% opacity
    const Color darkTextTertiary = Color(0xFFEBEBF5); // 30% opacity

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: lightOrange, // Dark mode'da daha açık turuncu
        surface: darkSurface,
        background: darkBackground,
        brightness: Brightness.dark,
      ),

      // 🎨 GOOGLE FONTS - Poppins (Dark Mode)
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme)
          .copyWith(
            displayLarge: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkTextPrimary,
            ),
            displayMedium: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkTextPrimary,
            ),
            displaySmall: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            headlineLarge: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            headlineMedium: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            headlineSmall: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            bodyLarge: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: darkTextPrimary,
            ),
            bodyMedium: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: darkTextPrimary,
            ),
            bodySmall: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: darkTextSecondary,
            ),
            labelLarge: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            labelMedium: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkTextPrimary,
            ),
            labelSmall: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: darkTextSecondary,
            ),
          ),

      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkBackground,

      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          side: const BorderSide(color: primaryOrange, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryOrange,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorder.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF44336), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.poppins(color: darkTextTertiary, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: darkTextSecondary, fontSize: 14),
      ),

      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: Colors.transparent,
      ),

      dividerTheme: DividerThemeData(
        color: darkDivider,
        thickness: 0.5,
        space: 1,
      ),

      iconTheme: IconThemeData(color: darkTextPrimary),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: primaryOrange,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: darkTertiary,
        labelStyle: GoogleFonts.poppins(color: darkTextPrimary, fontSize: 12),
        selectedColor: primaryOrange.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return darkTextTertiary;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange.withOpacity(0.5);
          }
          return darkTertiary;
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(color: darkBorder, width: 2),
      ),

      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return darkBorder;
        }),
      ),

      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: darkTextPrimary,
        iconColor: darkTextPrimary,
        selectedTileColor: darkTertiary,
      ),

      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.highContrastLight(
        primary: Colors.blue,
        secondary: Colors.yellow,
      ),

      // 🎨 GOOGLE FONTS - High Contrast
      textTheme: GoogleFonts.poppinsTextTheme(),

      scaffoldBackgroundColor: Colors.white,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
