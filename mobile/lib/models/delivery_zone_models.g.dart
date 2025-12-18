// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_zone_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeliveryZoneSyncDto _$DeliveryZoneSyncDtoFromJson(Map<String, dynamic> json) =>
    DeliveryZoneSyncDto(
      cityId: json['cityId'] as String,
      localityIds: (json['localityIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      minimumOrderAmount: (json['minimumOrderAmount'] as num?)?.toDouble(),
    );

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

Map<String, dynamic> _$CityZoneDtoToJson(CityZoneDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'districts': instance.districts,
    };

DistrictZoneDto _$DistrictZoneDtoFromJson(Map<String, dynamic> json) =>
    DistrictZoneDto(
      id: json['id'] as String,
      name: json['name'] as String,
      localities: (json['localities'] as List<dynamic>)
          .map((e) => LocalityZoneDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DistrictZoneDtoToJson(DistrictZoneDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'localities': instance.localities,
    };

LocalityZoneDto _$LocalityZoneDtoFromJson(Map<String, dynamic> json) =>
    LocalityZoneDto(
      id: json['id'] as String,
      name: json['name'] as String,
      isSelected: json['isSelected'] as bool,
    );

Map<String, dynamic> _$LocalityZoneDtoToJson(LocalityZoneDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'isSelected': instance.isSelected,
    };
