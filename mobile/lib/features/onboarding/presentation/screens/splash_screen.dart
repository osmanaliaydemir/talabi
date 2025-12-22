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
import 'package:mobile/features/profile/presentation/screens/vendor/edit_profile_screen.dart';

import 'package:mobile/features/auth/presentation/screens/customer/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
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

    if (mounted) {
      if (authProvider.isAuthenticated) {
        final role = authProvider.role?.toLowerCase();
        if (role == 'courier') {
          Navigator.of(context).pushReplacement(
            NoSlidePageRoute(builder: (_) => const CourierDashboardScreen()),
          );
        } else if (role == 'vendor') {
          // Check if profile is complete
          if (!authProvider.isProfileComplete) {
            Navigator.of(context).pushReplacement(
              NoSlidePageRoute(
                builder: (_) =>
                    const VendorEditProfileScreen(isOnboarding: true),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              NoSlidePageRoute(builder: (_) => const VendorDashboardScreen()),
            );
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryOrange,
      body: Center(
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
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 64,
                color: AppTheme.primaryOrange,
              ),
            ),
            const SizedBox(height: 24),
            // App Name
            Text(
              'Talabi',
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
    );
  }
}
