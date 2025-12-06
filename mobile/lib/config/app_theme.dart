import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/providers/bottom_nav_provider.dart';

class AppTheme {
  // 🎨 ANA RENKLER
  static const Color primaryOrange = Color(0xFFCE181B); // Updated to Red
  static const Color darkOrange = Color(0xFFB71518); // Updated to Dark Red
  static const Color lightOrange = Color(0xFFEF5350); // Updated to Light Red
  static const Color deepOrange = Color(0xFFC62828); // Updated to Deep Red
  static const Color primaryOrangeShade50 = Color(
    0xFFFFEBEE,
  ); // Updated to Red Shade 50

  // 🟢 BAŞARI RENKLERİ
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  // 🔴 HATA RENKLERİ
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  // ⚠️ UYARI RENKLERİ
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color warningDark = Color(0xFFFFA000);

  // ℹ️ BİLGİ RENKLERİ
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // 🏪 VENDOR (SATICI) RENKLERİ - Mor/Purple
  static const Color vendorPrimary = Color(0xFF673AB7); // Deep Purple
  static const Color vendorLight = Color(0xFF9575CD);
  static const Color vendorDark = Color(0xFF512DA8);

  // 🚚 COURIER (KURYE) RENKLERİ - Turkuaz/Teal
  static const Color courierPrimary = Color(0xFF009688); // Teal
  static const Color courierLight = Color(0xFF4DB6AC);
  static const Color courierDark = Color(0xFF00796B);

  // 🎭 ARKA PLAN RENKLERİ (Light Mode)
  static const Color backgroundColor = Color.fromARGB(255, 255, 255, 255);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E0E0);

  // 🌙 ARKA PLAN RENKLERİ (Dark Mode - iOS 16+ Standartları)
  static const Color darkBackgroundColor = Color(0xFF000000); // iOS tam siyah
  static const Color darkSurfaceColor = Color(0xFF1C1C1E); // iOS surface
  static const Color darkCardColor = Color(0xFF2C2C2E); // iOS secondary surface
  static const Color darkTertiarySurface = Color(
    0xFF3A3A3C,
  ); // iOS tertiary surface
  static const Color darkDividerColor = Color(0xFF38383A); // iOS separator
  static const Color darkBorderColor = Color(
    0xFF545458,
  ); // iOS divider (30% opacity)

  // 📝 METİN RENKLERİ (Light Mode)
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textDisabled = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // 📝 METİN RENKLERİ (Dark Mode - iOS 16+ Standartları)
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // iOS label (100%)
  static const Color darkTextSecondary = Color(
    0xFFEBEBF5,
  ); // iOS label (60% opacity)
  static const Color darkTextTertiary = Color(
    0xFFEBEBF5,
  ); // iOS label (30% opacity)
  static const Color darkTextDisabled = Color(0xFF8E8E93); // iOS placeholder
  static const Color darkTextOnPrimary = Colors.white;

  // 🔘 BUTON RENKLERİ
  static const Color buttonPrimary = primaryOrange;
  static const Color buttonSecondary = Color(0xFF424242);
  static const Color buttonDisabled = Color(0xFFE0E0E0);

  // 📦 DİĞER UI ELEMENTLERİ
  static const Color borderColor = Color(0xFFE0E0E0);
  static const Color shadowColor = Color(0x1A000000);
  static const Color overlayColor = Color(0x80000000);

  // 🎯 ÖZEL RENKLER (Sipariş Durumları)
  static const Color statusPending = Color(0xFFFFC107); // Beklemede
  static const Color statusProcessing = Color(0xFF2196F3); // İşleniyor
  static const Color statusShipping = Color(0xFF9C27B0); // Kargoda
  static const Color statusDelivered = Color(0xFF4CAF50); // Teslim Edildi
  static const Color statusCancelled = Color(0xFFF44336); // İptal Edildi

  // 📏 BOYUTLAR & SPACING
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  static const double spacing1DotZero = 1.0;
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  static const double buttonHeightSmall = 40.0;
  static const double buttonHeightMedium = 48.0;
  static const double buttonHeightLarge = 56.0;

  // 🎭 ELEVATION (Gölge Seviyeleri)
  static const double elevationNone = 0.0;
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;

  // Ana Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: darkOrange,
        surface: cardColor,
        background: backgroundColor,
      ),

      // Font Tanımları
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        // Büyük Başlıklar
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // Başlıklar
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),

        // Body Metinler
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),

        // Label/Button Metinler
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(color: textHint, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Diğer
      scaffoldBackgroundColor: backgroundColor,
    );
  }

  // Dark Theme (iOS 16+ Standartları)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        primary: primaryOrange,
        secondary: lightOrange, // Dark mode'da daha açık turuncu
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        brightness: Brightness.dark,
      ),

      // Font Tanımları (Dark Mode)
      textTheme:
          GoogleFonts.plusJakartaSansTextTheme(
            ThemeData.dark().textTheme,
          ).copyWith(
            // Büyük Başlıklar
            displayLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkTextPrimary,
            ),
            displayMedium: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkTextPrimary,
            ),
            displaySmall: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),

            // Başlıklar
            headlineLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            headlineMedium: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            headlineSmall: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),

            // Body Metinler
            bodyLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: darkTextPrimary,
            ),
            bodyMedium: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: darkTextPrimary,
            ),
            bodySmall: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: darkTextSecondary,
            ),

            // Label/Button Metinler
            labelLarge: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkTextPrimary,
            ),
            labelMedium: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: darkTextPrimary,
            ),
            labelSmall: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: darkTextSecondary,
            ),
          ),

      // AppBar Theme (Dark Mode)
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurfaceColor,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),

      // Button Themes (Dark Mode)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration Theme (Dark Mode)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorderColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: darkBorderColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryOrange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: darkTextTertiary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: darkTextSecondary,
          fontSize: 14,
        ),
      ),

      // Card Theme (Dark Mode)
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        surfaceTintColor: Colors.transparent,
      ),

      // Divider Theme (Dark Mode)
      dividerTheme: DividerThemeData(
        color: darkDividerColor,
        thickness: 0.5,
        space: 1,
      ),

      // Icon Theme (Dark Mode)
      iconTheme: IconThemeData(color: darkTextPrimary),

      // Bottom Navigation Bar Theme (Dark Mode)
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurfaceColor,
        selectedItemColor: primaryOrange,
        unselectedItemColor: darkTextSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // Dialog Theme (Dark Mode)
      dialogTheme: DialogThemeData(
        backgroundColor: darkCardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Bottom Sheet Theme (Dark Mode)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: darkCardColor,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),

      // Chip Theme (Dark Mode)
      chipTheme: ChipThemeData(
        backgroundColor: darkTertiarySurface,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: darkTextPrimary,
          fontSize: 12,
        ),
        selectedColor: primaryOrange.withOpacity(0.2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Switch Theme (Dark Mode)
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
          return darkTertiarySurface;
        }),
      ),

      // Checkbox Theme (Dark Mode)
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return Colors.transparent;
        }),
        checkColor: MaterialStateProperty.all(Colors.white),
        side: BorderSide(color: darkBorderColor, width: 2),
      ),

      // Radio Theme (Dark Mode)
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryOrange;
          }
          return darkBorderColor;
        }),
      ),

      // ListTile Theme (Dark Mode)
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: darkTextPrimary,
        iconColor: darkTextPrimary,
        selectedTileColor: darkTertiarySurface,
      ),

      // Diğer
      scaffoldBackgroundColor: darkBackgroundColor,
      canvasColor: darkBackgroundColor,
      shadowColor: Colors.black.withOpacity(0.3),
    );
  }

  // ÖZEL BUTON STİLLERİ
  static final ButtonStyle primaryButtonVendor = ElevatedButton.styleFrom(
    backgroundColor: vendorPrimary,
    foregroundColor: Colors.white,
    textStyle: plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    padding: const EdgeInsets.symmetric(vertical: spacingMedium),
    elevation: elevationLow,
  );

  static final ButtonStyle primaryButtonCourier = ElevatedButton.styleFrom(
    backgroundColor: courierPrimary,
    foregroundColor: Colors.white,
    textStyle: plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
    padding: const EdgeInsets.symmetric(vertical: spacingMedium),
    elevation: elevationLow,
  );

  // Farklı fontlar için yardımcı metodlar
  static TextStyle plusJakartaSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  // Geriye dönük uyumluluk için poppins() metodu (plusJakartaSans'a yönlendirir)
  // Backward compatibility: poppins() now redirects to plusJakartaSans()
  static TextStyle poppins({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    return plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
    );
  }

  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  static TextStyle montserrat({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.montserrat(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // 🎨 YARDIMCI METODLAR

  /// Sipariş durumuna göre renk döndür (Dark mode desteği ile)
  static Color getStatusColor(String status, {BuildContext? context}) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'pending':
      case 'beklemede':
        statusColor = statusPending;
        break;
      case 'processing':
      case 'işleniyor':
        statusColor = statusProcessing;
        break;
      case 'shipping':
      case 'kargoda':
        statusColor = statusShipping;
        break;
      case 'delivered':
      case 'teslim edildi':
        statusColor = statusDelivered;
        break;
      case 'cancelled':
      case 'iptal':
        statusColor = statusCancelled;
        break;
      default:
        statusColor = isDark ? darkTextSecondary : textSecondary;
        break;
    }
    return statusColor;
  }

  /// SizedBox ile spacing oluştur
  static Widget verticalSpace(double multiplier) {
    return SizedBox(height: spacingMedium * multiplier);
  }

  static Widget horizontalSpace(double multiplier) {
    return SizedBox(width: spacingMedium * multiplier);
  }

  /// Divider oluştur (Dark mode desteği ile)
  static Widget divider({
    double? thickness,
    Color? color,
    BuildContext? context,
  }) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    return Divider(
      thickness: thickness ?? 1.0,
      color: color ?? (isDark ? darkDividerColor : dividerColor),
      height: spacingMedium,
    );
  }

  /// Kart stili BoxDecoration (Dark mode desteği ile)
  static BoxDecoration cardDecoration({
    Color? color,
    double? radius,
    bool withShadow = true,
    BuildContext? context,
  }) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    final defaultColor = isDark ? darkCardColor : cardColor;
    final defaultShadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : shadowColor;

    return BoxDecoration(
      color: color ?? defaultColor,
      borderRadius: BorderRadius.circular(radius ?? radiusMedium),
      boxShadow: withShadow && !isDark
          ? [
              BoxShadow(
                color: defaultShadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );
  }

  /// Input field için BoxDecoration (container'lar için, Dark mode desteği ile)
  static BoxDecoration inputBoxDecoration({
    Color? color,
    double? radius,
    BuildContext? context,
  }) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    final defaultColor = isDark ? darkCardColor : surfaceColor;

    return BoxDecoration(
      color: color ?? defaultColor,
      borderRadius: BorderRadius.circular(radius ?? radiusSmall),
    );
  }

  /// Input decoration oluştur (Dark mode desteği ile)
  static InputDecoration inputDecoration({
    required String hint,
    String? label,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    BuildContext? context,
  }) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : false;
    final defaultFillColor = fillColor ?? (isDark ? darkCardColor : cardColor);
    final defaultBorderColor = isDark
        ? darkBorderColor.withOpacity(0.3)
        : borderColor;

    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: defaultFillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: defaultBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: defaultBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: primaryOrange, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingMedium,
      ),
      hintStyle: GoogleFonts.plusJakartaSans(
        color: isDark ? darkTextTertiary : textHint,
        fontSize: 14,
      ),
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isDark ? darkTextSecondary : textSecondary,
        fontSize: 14,
      ),
    );
  }

  // 🎨 VENDOR TYPE BAZLI RENK PALETLERİ

  /// Restaurant için renk paleti (Kırmızı)
  static const Color restaurantPrimary = Color(0xFFCE181B);
  static const Color restaurantDark = Color(0xFFB71518);
  static const Color restaurantLight = Color(0xFFEF5350);
  static const Color restaurantShade50 = Color(0xFFFFEBEE);

  /// Market için renk paleti (Yeşil)
  static const Color marketPrimary = Color(0xFF4CAF50);
  static const Color marketDark = Color(0xFF388E3C);
  static const Color marketLight = Color(0xFF81C784);
  static const Color marketShade50 = Color(0xFFE8F5E9);

  /// VendorType'a göre primary color döndürür
  static Color getPrimaryColorForVendorType(MainCategory category) {
    return category == MainCategory.restaurant ? restaurantPrimary : marketPrimary;
  }

  /// VendorType'a göre dark color döndürür
  static Color getDarkColorForVendorType(MainCategory category) {
    return category == MainCategory.restaurant ? restaurantDark : marketDark;
  }

  /// VendorType'a göre light color döndürür
  static Color getLightColorForVendorType(MainCategory category) {
    return category == MainCategory.restaurant ? restaurantLight : marketLight;
  }

  /// VendorType'a göre shade50 color döndürür
  static Color getShade50ForVendorType(MainCategory category) {
    return category == MainCategory.restaurant ? restaurantShade50 : marketShade50;
  }

  /// VendorType'a göre ColorScheme döndürür
  static ColorScheme getColorsForVendorType(
    MainCategory category, {
    Brightness brightness = Brightness.light,
  }) {
    final primary = getPrimaryColorForVendorType(category);
    final dark = getDarkColorForVendorType(category);
    final light = getLightColorForVendorType(category);

    return ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      secondary: brightness == Brightness.dark ? light : dark,
      surface: brightness == Brightness.dark ? darkSurfaceColor : cardColor,
      background: brightness == Brightness.dark ? darkBackgroundColor : backgroundColor,
      brightness: brightness,
    );
  }

  /// VendorType'a göre ThemeData döndürür (Light Mode)
  static ThemeData getThemeForVendorType(
    MainCategory category, {
    bool isDark = false,
  }) {
    final primary = getPrimaryColorForVendorType(category);
    final dark = getDarkColorForVendorType(category);
    final light = getLightColorForVendorType(category);

    if (isDark) {
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: light,
          surface: darkSurfaceColor,
          background: darkBackgroundColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: darkTextPrimary,
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: darkTextPrimary,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: darkTextPrimary,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: darkTextSecondary,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkTextPrimary,
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: darkSurfaceColor,
          foregroundColor: darkTextPrimary,
          elevation: 0,
          centerTitle: true,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          ),
          iconTheme: IconThemeData(color: darkTextPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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
            foregroundColor: primary,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkCardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkBorderColor.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: darkBorderColor.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: GoogleFonts.plusJakartaSans(
            color: darkTextTertiary,
            fontSize: 14,
          ),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: darkTextSecondary,
            fontSize: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: darkCardColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: darkBackgroundColor,
        canvasColor: darkBackgroundColor,
        shadowColor: Colors.black.withOpacity(0.3),
      );
    } else {
      return ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: dark,
          surface: cardColor,
          background: backgroundColor,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
          displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          headlineSmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: textPrimary,
          ),
          bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: textPrimary,
          ),
          bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: textSecondary,
          ),
          labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          labelMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimary,
          ),
          labelSmall: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
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
            foregroundColor: primary,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: primary, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primary,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: error, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: GoogleFonts.plusJakartaSans(color: textHint, fontSize: 14),
          labelStyle: GoogleFonts.plusJakartaSans(
            color: textSecondary,
            fontSize: 14,
          ),
        ),
        cardTheme: CardThemeData(
          color: cardColor,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        scaffoldBackgroundColor: backgroundColor,
      );
    }
  }
}
