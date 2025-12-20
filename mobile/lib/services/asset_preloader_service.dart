import 'package:flutter/material.dart';
import 'package:mobile/services/logger_service.dart';

/// Service for preloading critical assets to improve app startup performance
class AssetPreloaderService {
  /// Preload critical assets (logo, splash images, etc.)
  /// Should be called during app initialization
  static Future<void> preloadCriticalAssets(BuildContext context) async {
    try {
      // Preload critical images in parallel
      // Using eagerError: false to continue loading even if one fails
      await Future.wait([
        // Splash/onboarding images
        _preloadImage(context, 'assets/images/logo.png'),

        // Note: Assuming 'assets/images/logo.png' exists based on SplashScreen icon usage,
        // but if not, we should stick to known assets or generic ones.
        // The original code had:
        // _preloadImage('assets/images/onboarding1.png'),
        // _preloadImage('assets/images/banner_image.png'),
        // _preloadImage('assets/images/location.png'),
        _preloadImage(context, 'assets/images/onboarding1.png'),
        _preloadImage(context, 'assets/images/banner_image.png'),
        _preloadImage(context, 'assets/images/location.png'),
      ], eagerError: false);

      LoggerService().info(
        '✅ [ASSET_PRELOADER] Critical assets preload completed',
      );
    } catch (e, stackTrace) {
      // Asset preloading failures shouldn't block app startup
      LoggerService().warning(
        '⚠️ [ASSET_PRELOADER] Some assets failed to preload',
        e,
        stackTrace,
      );
    }
  }

  /// Preload a single image asset
  static Future<void> _preloadImage(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      // Load asset into Flutter's ImageCache (decoded)
      await precacheImage(AssetImage(assetPath), context);
      LoggerService().debug('✅ [ASSET_PRELOADER] Preloaded: $assetPath');
    } catch (e, stackTrace) {
      // Individual asset failures shouldn't block preloading
      LoggerService().warning(
        '⚠️ [ASSET_PRELOADER] Failed to preload $assetPath',
        e,
        stackTrace,
      );
    }
  }

  /// Preload fonts (Google Fonts are already preloaded automatically)
  /// This method is for custom fonts if any are added in the future
  static Future<void> preloadFonts() async {
    // Google Fonts package handles font preloading automatically
    // If custom fonts are added to pubspec.yaml, they can be preloaded here
    // For now, this is a placeholder for future custom font support
    LoggerService().debug(
      '✅ [ASSET_PRELOADER] Fonts preloaded (Google Fonts handled automatically)',
    );
  }
}
