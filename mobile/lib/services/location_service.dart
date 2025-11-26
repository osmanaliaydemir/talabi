import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/services/courier_service.dart';

class LocationService {
  final CourierService _courierService;
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _updateTimer;

  LocationService(this._courierService);

  // Check and request location permissions
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Start background location tracking
  Future<void> startLocationTracking() async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) async {
            // Update location to backend
            try {
              await _courierService.updateLocation(
                position.latitude,
                position.longitude,
              );
            } catch (e) {
              print('Error updating location: $e');
            }
          },
        );

    // Also set up periodic updates (every 30 seconds) even if position hasn't changed much
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
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
