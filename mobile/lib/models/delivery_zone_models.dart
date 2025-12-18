import 'package:json_annotation/json_annotation.dart';

part 'delivery_zone_models.g.dart';

@JsonSerializable()
class DeliveryZoneSyncDto {
  final String cityId;
  final List<String> localityIds;
  final double? deliveryFee;
  final double? minimumOrderAmount;

  DeliveryZoneSyncDto({
    required this.cityId,
    required this.localityIds,
    this.deliveryFee,
    this.minimumOrderAmount,
  });

  Map<String, dynamic> toJson() => _$DeliveryZoneSyncDtoToJson(this);
}

@JsonSerializable()
class CityZoneDto {
  final String id;
  final String name;
  final List<DistrictZoneDto> districts;

  CityZoneDto({required this.id, required this.name, required this.districts});

  factory CityZoneDto.fromJson(Map<String, dynamic> json) =>
      _$CityZoneDtoFromJson(json);
}

@JsonSerializable()
class DistrictZoneDto {
  final String id;
  final String name;
  final List<LocalityZoneDto> localities;

  // Helper for UI expansion state
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isExpanded;

  DistrictZoneDto({
    required this.id,
    required this.name,
    required this.localities,
    this.isExpanded = false,
  });

  factory DistrictZoneDto.fromJson(Map<String, dynamic> json) =>
      _$DistrictZoneDtoFromJson(json);
}

@JsonSerializable()
class LocalityZoneDto {
  final String id;
  final String name;
  bool isSelected;

  LocalityZoneDto({
    required this.id,
    required this.name,
    required this.isSelected,
  });

  factory LocalityZoneDto.fromJson(Map<String, dynamic> json) =>
      _$LocalityZoneDtoFromJson(json);
}
