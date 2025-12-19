import 'package:json_annotation/json_annotation.dart';

part 'delivery_zone_models.g.dart';

@JsonSerializable(createFactory: false)
class DeliveryZoneSyncDto {
  DeliveryZoneSyncDto({
    required this.cityId,
    required this.localityIds,
    this.deliveryFee,
    this.minimumOrderAmount,
  });

  final String cityId;
  final List<String> localityIds;
  final double? deliveryFee;
  final double? minimumOrderAmount;

  Map<String, dynamic> toJson() => _$DeliveryZoneSyncDtoToJson(this);
}

@JsonSerializable(createToJson: false)
class CityZoneDto {
  CityZoneDto({required this.id, required this.name, required this.districts});

  factory CityZoneDto.fromJson(Map<String, dynamic> json) =>
      _$CityZoneDtoFromJson(json);

  final String id;
  final String name;
  final List<DistrictZoneDto> districts;
}

@JsonSerializable(createToJson: false)
class DistrictZoneDto {
  DistrictZoneDto({
    required this.id,
    required this.name,
    required this.localities,
    this.isExpanded = false,
  });

  factory DistrictZoneDto.fromJson(Map<String, dynamic> json) =>
      _$DistrictZoneDtoFromJson(json);

  final String id;
  final String name;
  final List<LocalityZoneDto> localities;

  // Helper for UI expansion state
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isExpanded;
}

@JsonSerializable(createToJson: false)
class LocalityZoneDto {
  LocalityZoneDto({
    required this.id,
    required this.name,
    required this.isSelected,
  });

  factory LocalityZoneDto.fromJson(Map<String, dynamic> json) =>
      _$LocalityZoneDtoFromJson(json);

  final String id;
  final String name;
  bool isSelected;
}
