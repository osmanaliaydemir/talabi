class Vendor {
  Vendor({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.address,
    this.city,
    this.rating,
    this.ratingCount = 0,
    this.latitude,
    this.longitude,
    this.distanceInKm,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'].toString(),
      name: json['name'],
      imageUrl: json['imageUrl'],
      address: json['address'],
      city: json['city'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      ratingCount: json['ratingCount'] ?? 0,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      distanceInKm: json['distanceInKm'] != null
          ? (json['distanceInKm'] as num).toDouble()
          : null,
    );
  }

  final String id;
  final String name;
  final String? imageUrl;
  final String address;
  final String? city;
  final double? rating;
  final int ratingCount;
  final double? latitude;
  final double? longitude;
  final double? distanceInKm;
}
