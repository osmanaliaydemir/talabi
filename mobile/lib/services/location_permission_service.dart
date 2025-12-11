import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/services/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling location permissions with explanation dialog
class LocationPermissionService {
  static const String _locationDialogShownKey =
      'location_permission_dialog_shown';

  /// Helper to get localized string dynamically
  static String _getLocalizedString(
    AppLocalizations? localizations,
    String key,
    String fallback,
  ) {
    if (localizations == null) return fallback;
    try {
      final value = (localizations as dynamic)[key];
      return value?.toString() ?? fallback;
    } catch (e) {
      return fallback;
    }
  }

  /// Check if location permission dialog has been shown before
  static Future<bool> _hasShownDialog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationDialogShownKey) ?? false;
  }

  /// Mark location permission dialog as shown
  static Future<void> _markDialogAsShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationDialogShownKey, true);
  }

  /// Show explanation dialog before requesting location permission
  static Future<bool> _showLocationExplanationDialog(
    BuildContext context,
  ) async {
    final localizations = AppLocalizations.of(context);

    // Try to get localized strings, fallback to defaults
    final title = _getLocalizedString(
      localizations,
      'locationPermissionTitle',
      'Konum İzni Gerekli',
    );
    final message = _getLocalizedString(
      localizations,
      'locationPermissionMessage',
      'Uygulamanın size yakın restoranları gösterebilmesi ve siparişlerinizi takip edebilmesi için konum iznine ihtiyacımız var.',
    );
    final allowButton = _getLocalizedString(localizations, 'allow', 'İzin Ver');
    final cancelButton = localizations?.cancel ?? 'İptal';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.teal, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: Text(
              cancelButton,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            child: Text(allowButton),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show dialog when location services are disabled
  static Future<bool> _showLocationServicesDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context);

    final title = _getLocalizedString(
      localizations,
      'locationServicesDisabledTitle',
      'Konum Servisleri Kapalı',
    );
    final message = _getLocalizedString(
      localizations,
      'locationServicesDisabledMessage',
      'Konum servisleri kapalı. Lütfen ayarlardan konum servislerini açın.',
    );
    final openSettingsButton = _getLocalizedString(
      localizations,
      'openSettings',
      'Ayarları Aç',
    );
    final cancelButton = localizations?.cancel ?? 'İptal';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.location_off, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelButton, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(true);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              openSettingsButton,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Check if location services are enabled, show dialog if not
  static Future<bool> checkLocationServices(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        await _showLocationServicesDialog(context);
        // Check again after user might have opened settings
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
      }
      return serviceEnabled;
    }
    return true;
  }

  /// Check and request location permissions with explanation dialog
  /// Returns true if permission is granted, false otherwise
  static Future<bool> checkAndRequestPermissions(BuildContext context) async {
    // Check if location services are enabled
    final serviceEnabled = await checkLocationServices(context);
    if (!serviceEnabled) {
      return false;
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    // If permission is already granted or while in use, return true
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    // If permission is denied forever, show error
    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        final localizations = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _getLocalizedString(
                localizations,
                'locationPermissionDeniedForever',
                'Konum izni kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.',
              ),
            ),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: localizations?.settings ?? 'Ayarlar',
              textColor: Colors.white,
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
          ),
        );
      }
      return false;
    }

    // If permission is denied, show explanation dialog first (only once)
    if (permission == LocationPermission.denied) {
      final hasShown = await _hasShownDialog();
      if (!hasShown) {
        if (!context.mounted) return false;
        final userAccepted = await _showLocationExplanationDialog(context);
        if (!userAccepted) {
          return false;
        }
        await _markDialogAsShown();
      }

      // Now request permission
      if (!context.mounted) return false;
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (context.mounted) {
          final localizations = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _getLocalizedString(
                  localizations,
                  'locationPermissionDenied',
                  'Konum izni reddedildi.',
                ),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false;
      }
    }

    // Final check
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    }

    return false;
  }

  /// Get current location with permission check
  static Future<Position?> getCurrentLocation(BuildContext context) async {
    try {
      // First check if location services are enabled
      final serviceEnabled = await checkLocationServices(context);
      if (!serviceEnabled) return null;

      // Then check permissions
      if (!context.mounted) return null;
      final hasPermission = await checkAndRequestPermissions(context);
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e, stackTrace) {
      LoggerService().error('Error getting location', e, stackTrace);
      return null;
    }
  }
}
