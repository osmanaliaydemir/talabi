// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_calculation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CalculateOrderRequestImpl _$$CalculateOrderRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$CalculateOrderRequestImpl(
      vendorId: json['vendorId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddressId: json['deliveryAddressId'] as String?,
      couponCode: json['couponCode'] as String?,
      campaignId: json['campaignId'] as String?,
    );

Map<String, dynamic> _$$CalculateOrderRequestImplToJson(
        _$CalculateOrderRequestImpl instance) =>
    <String, dynamic>{
      'vendorId': instance.vendorId,
      'items': instance.items,
      'deliveryAddressId': instance.deliveryAddressId,
      'couponCode': instance.couponCode,
      'campaignId': instance.campaignId,
    };

_$OrderItemDtoImpl _$$OrderItemDtoImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemDtoImpl(
      productId: json['productId'] as String,
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$$OrderItemDtoImplToJson(_$OrderItemDtoImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'quantity': instance.quantity,
    };

_$OrderCalculationResultImpl _$$OrderCalculationResultImplFromJson(
        Map<String, dynamic> json) =>
    _$OrderCalculationResultImpl(
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      discountAmount: (json['discountAmount'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      appliedCoupon: json['appliedCoupon'],
      items: (json['items'] as List<dynamic>?)
              ?.map((e) =>
                  OrderItemCalculationDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$OrderCalculationResultImplToJson(
        _$OrderCalculationResultImpl instance) =>
    <String, dynamic>{
      'subtotal': instance.subtotal,
      'deliveryFee': instance.deliveryFee,
      'discountAmount': instance.discountAmount,
      'totalAmount': instance.totalAmount,
      'appliedCoupon': instance.appliedCoupon,
      'items': instance.items,
    };

_$OrderItemCalculationDtoImpl _$$OrderItemCalculationDtoImplFromJson(
        Map<String, dynamic> json) =>
    _$OrderItemCalculationDtoImpl(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
    );

Map<String, dynamic> _$$OrderItemCalculationDtoImplToJson(
        _$OrderItemCalculationDtoImpl instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'productName': instance.productName,
      'unitPrice': instance.unitPrice,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
    };
