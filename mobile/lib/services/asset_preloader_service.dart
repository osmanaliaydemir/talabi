import 'package:flutter/services.dart';
import 'package:mobile/services/logger_service.dart';

/// Service for preloading critical assets to improve app startup performance
class AssetPreloaderService {
  /// Preload critical assets (logo, splash images, etc.)
  /// Should be called during app initialization
  static Future<void> preloadCriticalAssets() async {
    try {
      // Preload critical images in parallel
      // Using eagerError: false to continue loading even if one fails
      await Future.wait([
        // Logo and icon
        _preloadImage('assets/icon/icon.png'),
        // Splash/onboarding images
        _preloadImage('assets/images/onboarding1.png'),
        // Other critical images
        _preloadImage('assets/images/banner_image.png'),
        _preloadImage('assets/images/location.png'),
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
  static Future<void> _preloadImage(String assetPath) async {
    try {
      // Load asset into memory cache
      await rootBundle.load(assetPath);
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
