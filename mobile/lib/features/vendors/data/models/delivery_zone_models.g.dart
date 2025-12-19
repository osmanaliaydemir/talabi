// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_zone_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$DeliveryZoneSyncDtoToJson(
        DeliveryZoneSyncDto instance) =>
    <String, dynamic>{
      'cityId': instance.cityId,
      'localityIds': instance.localityIds,
      'deliveryFee': instance.deliveryFee,
      'minimumOrderAmount': instance.minimumOrderAmount,
    };

CityZoneDto _$CityZoneDtoFromJson(Map<String, dynamic> json) => CityZoneDto(
      id: json['id'] as String,
      name: json['name'] as String,
      districts: (json['districts'] as List<dynamic>)
          .map((e) => DistrictZoneDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

DistrictZoneDto _$DistrictZoneDtoFromJson(Map<String, dynamic> json) =>
    DistrictZoneDto(
      id: json['id'] as String,
      name: json['name'] as String,
      localities: (json['localities'] as List<dynamic>)
          .map((e) => LocalityZoneDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

LocalityZoneDto _$LocalityZoneDtoFromJson(Map<String, dynamic> json) =>
    LocalityZoneDto(
      id: json['id'] as String,
      name: json['name'] as String,
      isSelected: json['isSelected'] as bool,
    );
