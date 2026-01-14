/// Utility class for extracting location coordinates from address data.
///
/// This class centralizes the logic for extracting latitude and longitude
/// from address maps, eliminating code duplication across the codebase.
class LocationExtractor {
  /// Extracts latitude and longitude from an address map.
  ///
  /// Returns a record with nullable latitude and longitude values.
  /// If the address is null or coordinates are invalid, returns null values.
  ///
  /// Example:
  /// ```dart
  /// final address = {'latitude': '41.0082', 'longitude': '28.9784'};
  /// final location = LocationExtractor.fromAddress(address);
  /// final lat = location.latitude;
  /// final lon = location.longitude;
  /// ```
  static ({double? latitude, double? longitude}) fromAddress(
    Map<String, dynamic>? address,
  ) {
    if (address == null) {
      return (latitude: null, longitude: null);
    }

    final lat = address['latitude'];
    final lon = address['longitude'];

    return (
      latitude: lat != null ? double.tryParse(lat.toString()) : null,
      longitude: lon != null ? double.tryParse(lon.toString()) : null,
    );
  }

  /// Extracts latitude from an address map.
  ///
  /// Returns null if address is null or latitude is invalid.
  static double? getLatitude(Map<String, dynamic>? address) {
    if (address == null) return null;
    final lat = address['latitude'];
    return lat != null ? double.tryParse(lat.toString()) : null;
  }

  /// Extracts longitude from an address map.
  ///
  /// Returns null if address is null or longitude is invalid.
  static double? getLongitude(Map<String, dynamic>? address) {
    if (address == null) return null;
    final lon = address['longitude'];
    return lon != null ? double.tryParse(lon.toString()) : null;
  }
}
