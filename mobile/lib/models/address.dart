class Address {
  Address({
    required this.id,
    required this.title,
    required this.fullAddress,
    this.cityId,
    this.cityName,
    this.districtId,
    this.districtName,
    this.localityId,
    this.localityName,
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
      cityId: json['cityId']?.toString(),
      cityName: json['cityName'],
      districtId: json['districtId']?.toString(),
      districtName: json['districtName'],
      localityId: json['localityId']?.toString(),
      localityName: json['localityName'],
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
      'cityId': cityId,
      'districtId': districtId,
      'localityId': localityId,
      'postalCode': postalCode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  final String id;
  final String title;
  final String fullAddress;
  final String? cityId;
  final String? cityName;
  final String? districtId;
  final String? districtName;
  final String? localityId;
  final String? localityName;
  final String? postalCode;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
}
