import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/location_permission_service.dart';

class LocationService {
  final CourierService? _courierService;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;
  BuildContext? _context;

  LocationService(this._courierService);

  /// Set context for permission dialogs (should be called before using location)
  void setContext(BuildContext context) {
    _context = context;
  }

  // Check and request location permissions with explanation dialog
  Future<bool> checkAndRequestPermissions() async {
    if (_context == null) {
      print(
        'Warning: Context not set for LocationService. Permission dialog cannot be shown.',
      );
      // Fallback to direct permission check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        return permission != LocationPermission.denied;
      }

      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }

    return await LocationPermissionService.checkAndRequestPermissions(
      _context!,
    );
  }

  // Get current location with permission check
  Future<Position?> getCurrentLocation() async {
    if (_context == null) {
      print(
        'Warning: Context not set for LocationService. Using direct permission check.',
      );
      // Fallback
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return null;

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return null;
        }

        if (permission == LocationPermission.deniedForever) return null;

        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (e) {
        print('Error getting location: $e');
        return null;
      }
    }

    return await LocationPermissionService.getCurrentLocation(_context!);
  }

  // Start background location tracking
  Future<void> startLocationTracking() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: "Talabi Kurye",
          notificationText: "Teslimat takibi için konumunuz kullanılıyor",
          enableWakeLock: true,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation,
        distanceFilter: 50,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      );
    }

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            // Update location to backend (only if courier service is available)
            if (_courierService != null) {
              try {
                await _courierService.updateLocation(
                  position.latitude,
                  position.longitude,
                );
              } catch (e) {
                print('Error updating location: $e');
              }
            }
          },
        );

    // Also set up periodic updates (every 30 seconds) even if position hasn't changed much
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_courierService != null) {
        try {
          final position = await getCurrentLocation();
          if (position != null) {
            await _courierService.updateLocation(
              position.latitude,
              position.longitude,
            );
          }
        } catch (e) {
          print('Error in periodic update: $e');
        }
      }
    });
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  // Calculate distance between two points in kilometers
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) /
        1000;
  }

  void dispose() {
    stopLocationTracking();
  }
}
