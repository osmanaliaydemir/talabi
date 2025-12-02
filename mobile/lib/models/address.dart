class Address {
  final String id;
  final String title;
  final String fullAddress;
  final String city;
  final String district;
  final String? postalCode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  Address({
    required this.id,
    required this.title,
    required this.fullAddress,
    required this.city,
    required this.district,
    this.postalCode,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'].toString(),
      title: json['title'],
      fullAddress: json['fullAddress'],
      city: json['city'],
      district: json['district'],
      postalCode: json['postalCode'],
      isDefault: json['isDefault'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'fullAddress': fullAddress,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
