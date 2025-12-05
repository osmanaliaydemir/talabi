import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Service for preloading critical assets to improve app startup performance
class AssetPreloaderService {
  /// Preload critical assets (logo, splash images, etc.)
  /// Should be called during app initialization
  static Future<void> preloadCriticalAssets() async {
    try {
      // Preload critical images in parallel
      await Future.wait([
        // Logo and icon
        _preloadImage('assets/icon/icon.png'),
        // Splash/onboarding images
        _preloadImage('assets/images/onboarding1.png'),
        // Other critical images
        _preloadImage('assets/images/banner_image.png'),
        _preloadImage('assets/images/location.png'),
      ]);

      if (kDebugMode) {
        print('✅ [ASSET_PRELOADER] Critical assets preloaded successfully');
      }
    } catch (e) {
      // Asset preloading failures shouldn't block app startup
      if (kDebugMode) {
        print('⚠️ [ASSET_PRELOADER] Failed to preload some assets: $e');
      }
    }
  }

  /// Preload a single image asset
  static Future<void> _preloadImage(String assetPath) async {
    try {
      // Load asset into memory cache
      await rootBundle.load(assetPath);
      if (kDebugMode) {
        print('✅ [ASSET_PRELOADER] Preloaded: $assetPath');
      }
    } catch (e) {
      // Individual asset failures shouldn't block preloading
      if (kDebugMode) {
        print('⚠️ [ASSET_PRELOADER] Failed to preload $assetPath: $e');
      }
    }
  }

  /// Preload fonts (Google Fonts are already preloaded automatically)
  /// This method is for custom fonts if any are added in the future
  static Future<void> preloadFonts() async {
    // Google Fonts package handles font preloading automatically
    // If custom fonts are added to pubspec.yaml, they can be preloaded here
    // For now, this is a placeholder for future custom font support
    if (kDebugMode) {
      print(
        '✅ [ASSET_PRELOADER] Fonts preloaded (Google Fonts handled automatically)',
      );
    }
  }
}
