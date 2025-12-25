import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/courier_service.dart';
import 'package:mobile/services/location_permission_service.dart';
import 'package:mobile/services/logger_service.dart';

class LocationService {
  LocationService(this._courierService);

  final CourierService? _courierService;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;
  BuildContext? _context;
  DateTime? _lastUpdateTime;

  /// Set context for permission dialogs (should be called before using location)
  void setContext(BuildContext context) {
    _context = context;
  }

  // Check and request location permissions with explanation dialog
  Future<bool> checkAndRequestPermissions() async {
    if (_context == null) {
      LoggerService().warning(
        'Warning: Context not set for LocationService. Permission dialog cannot be shown.',
      );
      // Fallback to direct permission check
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      LoggerService().warning(
        'Warning: Context not set for LocationService. Using direct permission check.',
      );
      // Fallback
      try {
        final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
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
      } catch (e, stackTrace) {
        LoggerService().error('Error getting location', e, stackTrace);
        return null;
      }
    }

    return await LocationPermissionService.getCurrentLocation(_context!);
  }

  // Helper method to send location update with throttling
  Future<void> _sendUpdate(Position position) async {
    if (_courierService == null) return;

    final now = DateTime.now();
    // Throttle: Only update if 20 seconds have passed since last update
    if (_lastUpdateTime != null &&
        now.difference(_lastUpdateTime!) < const Duration(seconds: 20)) {
      return;
    }

    try {
      _lastUpdateTime = now;
      await _courierService.updateLocation(
        position.latitude,
        position.longitude,
      );
    } catch (e, stackTrace) {
      // Don't log 429 errors as error, maybe warning
      if (e is DioException && e.response?.statusCode == 429) {
        LoggerService().warning('Rate limit hit for location update');
      } else {
        LoggerService().error('Error updating location', e, stackTrace);
      }
    }
  }

  // Start background location tracking
  Future<void> startLocationTracking() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
        forceLocationManager: true,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Talabi Kurye',
          notificationText: 'Teslimat takibi için konumunuz kullanılıyor',
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
            await _sendUpdate(position);
          },
        );

    // Also set up periodic updates (every 60 seconds) as a fallback heartbeat
    _updateTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      try {
        final position = await getCurrentLocation();
        if (position != null) {
          await _sendUpdate(position);
        }
      } catch (e) {
        // Silent error for periodic update
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
