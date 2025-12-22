// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_calculation_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CalculateOrderRequest _$CalculateOrderRequestFromJson(
    Map<String, dynamic> json) {
  return _CalculateOrderRequest.fromJson(json);
}

/// @nodoc
mixin _$CalculateOrderRequest {
  String get vendorId => throw _privateConstructorUsedError;
  List<OrderItemDto> get items => throw _privateConstructorUsedError;
  String? get deliveryAddressId => throw _privateConstructorUsedError;
  String? get couponCode => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CalculateOrderRequestCopyWith<CalculateOrderRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CalculateOrderRequestCopyWith<$Res> {
  factory $CalculateOrderRequestCopyWith(CalculateOrderRequest value,
          $Res Function(CalculateOrderRequest) then) =
      _$CalculateOrderRequestCopyWithImpl<$Res, CalculateOrderRequest>;
  @useResult
  $Res call(
      {String vendorId,
      List<OrderItemDto> items,
      String? deliveryAddressId,
      String? couponCode});
}

/// @nodoc
class _$CalculateOrderRequestCopyWithImpl<$Res,
        $Val extends CalculateOrderRequest>
    implements $CalculateOrderRequestCopyWith<$Res> {
  _$CalculateOrderRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorId = null,
    Object? items = null,
    Object? deliveryAddressId = freezed,
    Object? couponCode = freezed,
  }) {
    return _then(_value.copyWith(
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItemDto>,
      deliveryAddressId: freezed == deliveryAddressId
          ? _value.deliveryAddressId
          : deliveryAddressId // ignore: cast_nullable_to_non_nullable
              as String?,
      couponCode: freezed == couponCode
          ? _value.couponCode
          : couponCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CalculateOrderRequestImplCopyWith<$Res>
    implements $CalculateOrderRequestCopyWith<$Res> {
  factory _$$CalculateOrderRequestImplCopyWith(
          _$CalculateOrderRequestImpl value,
          $Res Function(_$CalculateOrderRequestImpl) then) =
      __$$CalculateOrderRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String vendorId,
      List<OrderItemDto> items,
      String? deliveryAddressId,
      String? couponCode});
}

/// @nodoc
class __$$CalculateOrderRequestImplCopyWithImpl<$Res>
    extends _$CalculateOrderRequestCopyWithImpl<$Res,
        _$CalculateOrderRequestImpl>
    implements _$$CalculateOrderRequestImplCopyWith<$Res> {
  __$$CalculateOrderRequestImplCopyWithImpl(_$CalculateOrderRequestImpl _value,
      $Res Function(_$CalculateOrderRequestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vendorId = null,
    Object? items = null,
    Object? deliveryAddressId = freezed,
    Object? couponCode = freezed,
  }) {
    return _then(_$CalculateOrderRequestImpl(
      vendorId: null == vendorId
          ? _value.vendorId
          : vendorId // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItemDto>,
      deliveryAddressId: freezed == deliveryAddressId
          ? _value.deliveryAddressId
          : deliveryAddressId // ignore: cast_nullable_to_non_nullable
              as String?,
      couponCode: freezed == couponCode
          ? _value.couponCode
          : couponCode // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CalculateOrderRequestImpl implements _CalculateOrderRequest {
  const _$CalculateOrderRequestImpl(
      {required this.vendorId,
      required final List<OrderItemDto> items,
      this.deliveryAddressId,
      this.couponCode})
      : _items = items;

  factory _$CalculateOrderRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$CalculateOrderRequestImplFromJson(json);

  @override
  final String vendorId;
  final List<OrderItemDto> _items;
  @override
  List<OrderItemDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final String? deliveryAddressId;
  @override
  final String? couponCode;

  @override
  String toString() {
    return 'CalculateOrderRequest(vendorId: $vendorId, items: $items, deliveryAddressId: $deliveryAddressId, couponCode: $couponCode)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CalculateOrderRequestImpl &&
            (identical(other.vendorId, vendorId) ||
                other.vendorId == vendorId) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.deliveryAddressId, deliveryAddressId) ||
                other.deliveryAddressId == deliveryAddressId) &&
            (identical(other.couponCode, couponCode) ||
                other.couponCode == couponCode));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      vendorId,
      const DeepCollectionEquality().hash(_items),
      deliveryAddressId,
      couponCode);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CalculateOrderRequestImplCopyWith<_$CalculateOrderRequestImpl>
      get copyWith => __$$CalculateOrderRequestImplCopyWithImpl<
          _$CalculateOrderRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CalculateOrderRequestImplToJson(
      this,
    );
  }
}

abstract class _CalculateOrderRequest implements CalculateOrderRequest {
  const factory _CalculateOrderRequest(
      {required final String vendorId,
      required final List<OrderItemDto> items,
      final String? deliveryAddressId,
      final String? couponCode}) = _$CalculateOrderRequestImpl;

  factory _CalculateOrderRequest.fromJson(Map<String, dynamic> json) =
      _$CalculateOrderRequestImpl.fromJson;

  @override
  String get vendorId;
  @override
  List<OrderItemDto> get items;
  @override
  String? get deliveryAddressId;
  @override
  String? get couponCode;
  @override
  @JsonKey(ignore: true)
  _$$CalculateOrderRequestImplCopyWith<_$CalculateOrderRequestImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OrderItemDto _$OrderItemDtoFromJson(Map<String, dynamic> json) {
  return _OrderItemDto.fromJson(json);
}

/// @nodoc
mixin _$OrderItemDto {
  String get productId => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrderItemDtoCopyWith<OrderItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemDtoCopyWith<$Res> {
  factory $OrderItemDtoCopyWith(
          OrderItemDto value, $Res Function(OrderItemDto) then) =
      _$OrderItemDtoCopyWithImpl<$Res, OrderItemDto>;
  @useResult
  $Res call({String productId, int quantity});
}

/// @nodoc
class _$OrderItemDtoCopyWithImpl<$Res, $Val extends OrderItemDto>
    implements $OrderItemDtoCopyWith<$Res> {
  _$OrderItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? quantity = null,
  }) {
    return _then(_value.copyWith(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderItemDtoImplCopyWith<$Res>
    implements $OrderItemDtoCopyWith<$Res> {
  factory _$$OrderItemDtoImplCopyWith(
          _$OrderItemDtoImpl value, $Res Function(_$OrderItemDtoImpl) then) =
      __$$OrderItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String productId, int quantity});
}

/// @nodoc
class __$$OrderItemDtoImplCopyWithImpl<$Res>
    extends _$OrderItemDtoCopyWithImpl<$Res, _$OrderItemDtoImpl>
    implements _$$OrderItemDtoImplCopyWith<$Res> {
  __$$OrderItemDtoImplCopyWithImpl(
      _$OrderItemDtoImpl _value, $Res Function(_$OrderItemDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? quantity = null,
  }) {
    return _then(_$OrderItemDtoImpl(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemDtoImpl implements _OrderItemDto {
  const _$OrderItemDtoImpl({required this.productId, required this.quantity});

  factory _$OrderItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemDtoImplFromJson(json);

  @override
  final String productId;
  @override
  final int quantity;

  @override
  String toString() {
    return 'OrderItemDto(productId: $productId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemDtoImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, productId, quantity);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemDtoImplCopyWith<_$OrderItemDtoImpl> get copyWith =>
      __$$OrderItemDtoImplCopyWithImpl<_$OrderItemDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemDtoImplToJson(
      this,
    );
  }
}

abstract class _OrderItemDto implements OrderItemDto {
  const factory _OrderItemDto(
      {required final String productId,
      required final int quantity}) = _$OrderItemDtoImpl;

  factory _OrderItemDto.fromJson(Map<String, dynamic> json) =
      _$OrderItemDtoImpl.fromJson;

  @override
  String get productId;
  @override
  int get quantity;
  @override
  @JsonKey(ignore: true)
  _$$OrderItemDtoImplCopyWith<_$OrderItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderCalculationResult _$OrderCalculationResultFromJson(
    Map<String, dynamic> json) {
  return _OrderCalculationResult.fromJson(json);
}

/// @nodoc
mixin _$OrderCalculationResult {
  double get subtotal => throw _privateConstructorUsedError;
  double get deliveryFee => throw _privateConstructorUsedError;
  double get discountAmount => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  dynamic get appliedCoupon =>
      throw _privateConstructorUsedError; // Using dynamic or a specific CouponDto if we have one defined in mobile
  List<OrderItemCalculationDto> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrderCalculationResultCopyWith<OrderCalculationResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCalculationResultCopyWith<$Res> {
  factory $OrderCalculationResultCopyWith(OrderCalculationResult value,
          $Res Function(OrderCalculationResult) then) =
      _$OrderCalculationResultCopyWithImpl<$Res, OrderCalculationResult>;
  @useResult
  $Res call(
      {double subtotal,
      double deliveryFee,
      double discountAmount,
      double totalAmount,
      dynamic appliedCoupon,
      List<OrderItemCalculationDto> items});
}

/// @nodoc
class _$OrderCalculationResultCopyWithImpl<$Res,
        $Val extends OrderCalculationResult>
    implements $OrderCalculationResultCopyWith<$Res> {
  _$OrderCalculationResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? deliveryFee = null,
    Object? discountAmount = null,
    Object? totalAmount = null,
    Object? appliedCoupon = freezed,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      deliveryFee: null == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      appliedCoupon: freezed == appliedCoupon
          ? _value.appliedCoupon
          : appliedCoupon // ignore: cast_nullable_to_non_nullable
              as dynamic,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItemCalculationDto>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderCalculationResultImplCopyWith<$Res>
    implements $OrderCalculationResultCopyWith<$Res> {
  factory _$$OrderCalculationResultImplCopyWith(
          _$OrderCalculationResultImpl value,
          $Res Function(_$OrderCalculationResultImpl) then) =
      __$$OrderCalculationResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double subtotal,
      double deliveryFee,
      double discountAmount,
      double totalAmount,
      dynamic appliedCoupon,
      List<OrderItemCalculationDto> items});
}

/// @nodoc
class __$$OrderCalculationResultImplCopyWithImpl<$Res>
    extends _$OrderCalculationResultCopyWithImpl<$Res,
        _$OrderCalculationResultImpl>
    implements _$$OrderCalculationResultImplCopyWith<$Res> {
  __$$OrderCalculationResultImplCopyWithImpl(
      _$OrderCalculationResultImpl _value,
      $Res Function(_$OrderCalculationResultImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subtotal = null,
    Object? deliveryFee = null,
    Object? discountAmount = null,
    Object? totalAmount = null,
    Object? appliedCoupon = freezed,
    Object? items = null,
  }) {
    return _then(_$OrderCalculationResultImpl(
      subtotal: null == subtotal
          ? _value.subtotal
          : subtotal // ignore: cast_nullable_to_non_nullable
              as double,
      deliveryFee: null == deliveryFee
          ? _value.deliveryFee
          : deliveryFee // ignore: cast_nullable_to_non_nullable
              as double,
      discountAmount: null == discountAmount
          ? _value.discountAmount
          : discountAmount // ignore: cast_nullable_to_non_nullable
              as double,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      appliedCoupon: freezed == appliedCoupon
          ? _value.appliedCoupon
          : appliedCoupon // ignore: cast_nullable_to_non_nullable
              as dynamic,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<OrderItemCalculationDto>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderCalculationResultImpl implements _OrderCalculationResult {
  const _$OrderCalculationResultImpl(
      {required this.subtotal,
      required this.deliveryFee,
      required this.discountAmount,
      required this.totalAmount,
      this.appliedCoupon,
      final List<OrderItemCalculationDto> items = const []})
      : _items = items;

  factory _$OrderCalculationResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderCalculationResultImplFromJson(json);

  @override
  final double subtotal;
  @override
  final double deliveryFee;
  @override
  final double discountAmount;
  @override
  final double totalAmount;
  @override
  final dynamic appliedCoupon;
// Using dynamic or a specific CouponDto if we have one defined in mobile
  final List<OrderItemCalculationDto> _items;
// Using dynamic or a specific CouponDto if we have one defined in mobile
  @override
  @JsonKey()
  List<OrderItemCalculationDto> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'OrderCalculationResult(subtotal: $subtotal, deliveryFee: $deliveryFee, discountAmount: $discountAmount, totalAmount: $totalAmount, appliedCoupon: $appliedCoupon, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderCalculationResultImpl &&
            (identical(other.subtotal, subtotal) ||
                other.subtotal == subtotal) &&
            (identical(other.deliveryFee, deliveryFee) ||
                other.deliveryFee == deliveryFee) &&
            (identical(other.discountAmount, discountAmount) ||
                other.discountAmount == discountAmount) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            const DeepCollectionEquality()
                .equals(other.appliedCoupon, appliedCoupon) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      subtotal,
      deliveryFee,
      discountAmount,
      totalAmount,
      const DeepCollectionEquality().hash(appliedCoupon),
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderCalculationResultImplCopyWith<_$OrderCalculationResultImpl>
      get copyWith => __$$OrderCalculationResultImplCopyWithImpl<
          _$OrderCalculationResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderCalculationResultImplToJson(
      this,
    );
  }
}

abstract class _OrderCalculationResult implements OrderCalculationResult {
  const factory _OrderCalculationResult(
          {required final double subtotal,
          required final double deliveryFee,
          required final double discountAmount,
          required final double totalAmount,
          final dynamic appliedCoupon,
          final List<OrderItemCalculationDto> items}) =
      _$OrderCalculationResultImpl;

  factory _OrderCalculationResult.fromJson(Map<String, dynamic> json) =
      _$OrderCalculationResultImpl.fromJson;

  @override
  double get subtotal;
  @override
  double get deliveryFee;
  @override
  double get discountAmount;
  @override
  double get totalAmount;
  @override
  dynamic get appliedCoupon;
  @override // Using dynamic or a specific CouponDto if we have one defined in mobile
  List<OrderItemCalculationDto> get items;
  @override
  @JsonKey(ignore: true)
  _$$OrderCalculationResultImplCopyWith<_$OrderCalculationResultImpl>
      get copyWith => throw _privateConstructorUsedError;
}

OrderItemCalculationDto _$OrderItemCalculationDtoFromJson(
    Map<String, dynamic> json) {
  return _OrderItemCalculationDto.fromJson(json);
}

/// @nodoc
mixin _$OrderItemCalculationDto {
  String get productId => throw _privateConstructorUsedError;
  String get productName => throw _privateConstructorUsedError;
  double get unitPrice => throw _privateConstructorUsedError;
  int get quantity => throw _privateConstructorUsedError;
  double get totalPrice => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OrderItemCalculationDtoCopyWith<OrderItemCalculationDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCalculationDtoCopyWith<$Res> {
  factory $OrderItemCalculationDtoCopyWith(OrderItemCalculationDto value,
          $Res Function(OrderItemCalculationDto) then) =
      _$OrderItemCalculationDtoCopyWithImpl<$Res, OrderItemCalculationDto>;
  @useResult
  $Res call(
      {String productId,
      String productName,
      double unitPrice,
      int quantity,
      double totalPrice});
}

/// @nodoc
class _$OrderItemCalculationDtoCopyWithImpl<$Res,
        $Val extends OrderItemCalculationDto>
    implements $OrderItemCalculationDtoCopyWith<$Res> {
  _$OrderItemCalculationDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? totalPrice = null,
  }) {
    return _then(_value.copyWith(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productName: null == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderItemCalculationDtoImplCopyWith<$Res>
    implements $OrderItemCalculationDtoCopyWith<$Res> {
  factory _$$OrderItemCalculationDtoImplCopyWith(
          _$OrderItemCalculationDtoImpl value,
          $Res Function(_$OrderItemCalculationDtoImpl) then) =
      __$$OrderItemCalculationDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String productId,
      String productName,
      double unitPrice,
      int quantity,
      double totalPrice});
}

/// @nodoc
class __$$OrderItemCalculationDtoImplCopyWithImpl<$Res>
    extends _$OrderItemCalculationDtoCopyWithImpl<$Res,
        _$OrderItemCalculationDtoImpl>
    implements _$$OrderItemCalculationDtoImplCopyWith<$Res> {
  __$$OrderItemCalculationDtoImplCopyWithImpl(
      _$OrderItemCalculationDtoImpl _value,
      $Res Function(_$OrderItemCalculationDtoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? productId = null,
    Object? productName = null,
    Object? unitPrice = null,
    Object? quantity = null,
    Object? totalPrice = null,
  }) {
    return _then(_$OrderItemCalculationDtoImpl(
      productId: null == productId
          ? _value.productId
          : productId // ignore: cast_nullable_to_non_nullable
              as String,
      productName: null == productName
          ? _value.productName
          : productName // ignore: cast_nullable_to_non_nullable
              as String,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as int,
      totalPrice: null == totalPrice
          ? _value.totalPrice
          : totalPrice // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemCalculationDtoImpl implements _OrderItemCalculationDto {
  const _$OrderItemCalculationDtoImpl(
      {required this.productId,
      required this.productName,
      required this.unitPrice,
      required this.quantity,
      required this.totalPrice});

  factory _$OrderItemCalculationDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemCalculationDtoImplFromJson(json);

  @override
  final String productId;
  @override
  final String productName;
  @override
  final double unitPrice;
  @override
  final int quantity;
  @override
  final double totalPrice;

  @override
  String toString() {
    return 'OrderItemCalculationDto(productId: $productId, productName: $productName, unitPrice: $unitPrice, quantity: $quantity, totalPrice: $totalPrice)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemCalculationDtoImpl &&
            (identical(other.productId, productId) ||
                other.productId == productId) &&
            (identical(other.productName, productName) ||
                other.productName == productName) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.totalPrice, totalPrice) ||
                other.totalPrice == totalPrice));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, productId, productName, unitPrice, quantity, totalPrice);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemCalculationDtoImplCopyWith<_$OrderItemCalculationDtoImpl>
      get copyWith => __$$OrderItemCalculationDtoImplCopyWithImpl<
          _$OrderItemCalculationDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemCalculationDtoImplToJson(
      this,
    );
  }
}

abstract class _OrderItemCalculationDto implements OrderItemCalculationDto {
  const factory _OrderItemCalculationDto(
      {required final String productId,
      required final String productName,
      required final double unitPrice,
      required final int quantity,
      required final double totalPrice}) = _$OrderItemCalculationDtoImpl;

  factory _OrderItemCalculationDto.fromJson(Map<String, dynamic> json) =
      _$OrderItemCalculationDtoImpl.fromJson;

  @override
  String get productId;
  @override
  String get productName;
  @override
  double get unitPrice;
  @override
  int get quantity;
  @override
  double get totalPrice;
  @override
  @JsonKey(ignore: true)
  _$$OrderItemCalculationDtoImplCopyWith<_$OrderItemCalculationDtoImpl>
      get copyWith => throw _privateConstructorUsedError;
}
