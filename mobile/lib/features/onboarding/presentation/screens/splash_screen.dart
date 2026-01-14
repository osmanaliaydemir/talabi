import 'package:flutter/material.dart';
import 'package:mobile/utils/custom_routes.dart';
import 'package:mobile/config/app_theme.dart';
import 'package:mobile/services/cache_service.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:mobile/services/notification_service.dart';
import 'package:mobile/services/preferences_service.dart';
import 'package:mobile/services/asset_preloader_service.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';
// import 'package:mobile/features/onboarding/presentation/screens/language_selection_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:mobile/features/onboarding/presentation/screens/main_navigation_screen.dart';
import 'package:mobile/features/dashboard/presentation/screens/courier_dashboard_screen.dart';
import 'package:mobile/features/dashboard/presentation/screens/vendor_dashboard_screen.dart';

import 'package:mobile/services/version_check_service.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/features/auth/presentation/screens/customer/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _cachedRole;

  @override
  void initState() {
    super.initState();
    _loadCachedRole();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  /// SecureStorage'dan role bilgisini yükler (hızlı erişim için)
  Future<void> _loadCachedRole() async {
    try {
      final role = await SecureStorageService.instance.getRole();
      if (mounted) {
        setState(() {
          _cachedRole = role;
        });
      }
    } catch (e) {
      // Silent fail - will use default colors
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Firebase is already initialized in main.dart, skip here
      // Parallel initialization for independent services
      await Future.wait([
        CacheService.init(), // Independent
        NotificationService().initialize(), // Independent
        AssetPreloaderService.preloadCriticalAssets(
          context,
        ), // Preload critical assets
      ]);

      // Check app state
      if (mounted) {
        await _checkAppState();
      }
    } catch (e) {
      LoggerService().error('Error initializing app: $e', e);
      // Even if initialization fails, try to proceed or show error
      if (mounted) {
        await _checkAppState();
      }
    }
  }

  Future<void> _checkAppState() async {
    // Artificial delay removed for faster startup
    // Minimum splash duration handled by initialization time

    if (!mounted) return;

    // Version Check
    await VersionCheckService().checkVersion(context);
    if (!mounted) return;

    final prefs = await PreferencesService.instance;
    // Language selection check removed as per new flow (Default AR, Selector in Onboarding)
    /*
    final languageSelected =
        prefs.getBool('language_selection_completed') ?? false;

    if (!languageSelected) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LanguageSelectionScreen(
              onLanguageSelected:
                  () {}, // Callback will be handled in main.dart if needed, but here we navigate
            ),
          ),
        );
      }
      return;
    }
    */

    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    if (!onboardingCompleted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
      return;
    }

    // Check Auth
    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.tryAutoLogin();

    // Role bilgisini güncelle (tryAutoLogin sonrası)
    if (mounted && authProvider.isAuthenticated) {
      final updatedRole = authProvider.role;
      if (updatedRole != null && updatedRole != _cachedRole) {
        setState(() {
          _cachedRole = updatedRole;
        });
      }
    }

    if (mounted) {
      if (authProvider.isAuthenticated) {
        final role = authProvider.role?.toLowerCase();
        if (role == 'courier') {
          Navigator.of(context).pushReplacement(
            NoSlidePageRoute(builder: (_) => const CourierDashboardScreen()),
          );
        } else if (role == 'vendor') {
          // Vendor dashboard will check profile completeness on its own
          // This avoids duplicate API calls and ensures real-time validation
          Navigator.of(context).pushReplacement(
            NoSlidePageRoute(builder: (_) => const VendorDashboardScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          );
        }
      } else {
        Navigator.of(context).pushReplacement(
          NoSlidePageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  /// Role göre splash screen gradient renklerini döndürür
  List<Color> _getGradientColors() {
    // Önce cached role'ü kontrol et, sonra AuthProvider'ı
    String? role = _cachedRole?.toLowerCase();

    if (role == null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          role = authProvider.role?.toLowerCase();
        }
      } catch (e) {
        // Provider henüz hazır değilse cached role kullan
      }
    }

    switch (role) {
      case 'vendor':
        // Vendor - Purple gradient
        return [
          AppTheme.vendorPrimary,
          AppTheme.vendorLight,
          AppTheme.vendorDark,
        ];
      case 'courier':
        // Courier - Teal gradient
        return [
          AppTheme.courierPrimary,
          AppTheme.courierLight,
          AppTheme.courierDark,
        ];
      default:
        // Customer - Red gradient (default)
        return [
          AppTheme.primaryOrange,
          AppTheme.darkOrange,
          AppTheme.deepOrange,
        ];
    }
  }

  /// Role göre icon rengini döndürür
  Color _getIconColor() {
    // Önce cached role'ü kontrol et, sonra AuthProvider'ı
    String? role = _cachedRole?.toLowerCase();

    if (role == null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          role = authProvider.role?.toLowerCase();
        }
      } catch (e) {
        // Provider henüz hazır değilse cached role kullan
      }
    }

    switch (role) {
      case 'vendor':
        return AppTheme.vendorPrimary;
      case 'courier':
        return AppTheme.courierPrimary;
      default:
        return AppTheme.primaryOrange; // Customer (default)
    }
  }

  /// Role göre shadow rengini döndürür
  Color _getShadowColor() {
    // Önce cached role'ü kontrol et, sonra AuthProvider'ı
    String? role = _cachedRole?.toLowerCase();

    if (role == null) {
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isAuthenticated) {
          role = authProvider.role?.toLowerCase();
        }
      } catch (e) {
        // Provider henüz hazır değilse cached role kullan
      }
    }

    switch (role) {
      case 'vendor':
        return AppTheme.vendorPrimary.withValues(alpha: 0.3);
      case 'courier':
        return AppTheme.courierPrimary.withValues(alpha: 0.3);
      default:
        return AppTheme.primaryOrange.withValues(
          alpha: 0.3,
        ); // Customer (default)
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();
    final iconColor = _getIconColor();
    final shadowColor = _getShadowColor();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 64,
                  color: iconColor,
                ),
              ),
              const SizedBox(height: 24),
              // App Name
              Text(
                'Talaby Go',
                style: AppTheme.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 48),
              // Loading Indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
