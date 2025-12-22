import 'package:freezed_annotation/freezed_annotation.dart';

part 'order_calculation_models.freezed.dart';
part 'order_calculation_models.g.dart';

@freezed
class CalculateOrderRequest with _$CalculateOrderRequest {
  const factory CalculateOrderRequest({
    required String vendorId,
    required List<OrderItemDto> items,
    String? deliveryAddressId,
    String? couponCode,
    String? campaignId,
  }) = _CalculateOrderRequest;

  factory CalculateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CalculateOrderRequestFromJson(json);
}

@freezed
class OrderItemDto with _$OrderItemDto {
  const factory OrderItemDto({
    required String productId,
    required int quantity,
  }) = _OrderItemDto;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemDtoFromJson(json);
}

@freezed
class OrderCalculationResult with _$OrderCalculationResult {
  const factory OrderCalculationResult({
    required double subtotal,
    required double deliveryFee,
    required double discountAmount,
    required double totalAmount,
    dynamic
    appliedCoupon, // Using dynamic or a specific CouponDto if we have one defined in mobile
    @Default([]) List<OrderItemCalculationDto> items,
  }) = _OrderCalculationResult;

  factory OrderCalculationResult.fromJson(Map<String, dynamic> json) =>
      _$OrderCalculationResultFromJson(json);
}

@freezed
class OrderItemCalculationDto with _$OrderItemCalculationDto {
  const factory OrderItemCalculationDto({
    required String productId,
    required String productName,
    required double unitPrice,
    required int quantity,
    required double totalPrice,
  }) = _OrderItemCalculationDto;

  factory OrderItemCalculationDto.fromJson(Map<String, dynamic> json) =>
      _$OrderItemCalculationDtoFromJson(json);
}
