class VendorProfile {
  VendorProfile({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.phoneNumber,
    this.description,
    this.rating,
    this.ratingCount = 0,
    this.busyStatus = 0,
    this.shamCashAccountNumber,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      address: json['address'],
      city: json['city'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      phoneNumber: json['phoneNumber'],
      description: json['description'],
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : null,
      ratingCount: json['ratingCount'] ?? 0,
      busyStatus: json['busyStatus'] ?? 0,
      shamCashAccountNumber: json['shamCashAccountNumber'],
    );
  }
  final int id;
  final String name;
  final String? imageUrl;
  final String address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? phoneNumber;
  final String? description;
  final double? rating;
  final int ratingCount;
  final int busyStatus;
  final String? shamCashAccountNumber;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'phoneNumber': phoneNumber,
      'description': description,
      'rating': rating,
      'ratingCount': ratingCount,
      'busyStatus': busyStatus,
      'shamCashAccountNumber': shamCashAccountNumber,
    };
  }
}
