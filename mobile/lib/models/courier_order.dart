enum OrderCourierStatus {
  assigned(0),
  accepted(1),
  rejected(2),
  pickedUp(3),
  outForDelivery(4),
  delivered(5);

  final int value;
  const OrderCourierStatus(this.value);

  static OrderCourierStatus? fromValue(int? value) {
    if (value == null) return null;
    return OrderCourierStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OrderCourierStatus.assigned,
    );
  }

  static OrderCourierStatus? fromString(String? value) {
    if (value == null) return null;
    try {
      return OrderCourierStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

class CourierOrder {
  final String id;
  final String customerOrderId;
  final String vendorName;
  final String vendorAddress;
  final double vendorLatitude;
  final double vendorLongitude;
  final String customerName;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double totalAmount;
  final double deliveryFee;
  final String status;
  final DateTime createdAt;
  final List<CourierOrderItem> items;

  // OrderCourier bilgileri
  final OrderCourierStatus? courierStatus;
  final DateTime? courierAssignedAt;
  final DateTime? courierAcceptedAt;
  final DateTime? courierRejectedAt;
  final String? rejectReason;
  final DateTime? pickedUpAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final double? courierTip;

  CourierOrder({
    required this.id,
    required this.customerOrderId,
    required this.vendorName,
    required this.vendorAddress,
    required this.vendorLatitude,
    required this.vendorLongitude,
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.totalAmount,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    required this.items,
    this.courierStatus,
    this.courierAssignedAt,
    this.courierAcceptedAt,
    this.courierRejectedAt,
    this.rejectReason,
    this.pickedUpAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.courierTip,
  });

  factory CourierOrder.fromJson(Map<String, dynamic> json) {
    return CourierOrder(
      id: json['id'].toString(),
      customerOrderId: json['customerOrderId']?.toString() ?? '',
      vendorName: json['vendorName'] ?? '',
      vendorAddress: json['vendorAddress'] ?? '',
      vendorLatitude: (json['vendorLatitude'] as num?)?.toDouble() ?? 0.0,
      vendorLongitude: (json['vendorLongitude'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customerName'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? 0.0,
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CourierOrderItem.fromJson(item))
              .toList() ??
          [],
      // OrderCourier bilgileri
      courierStatus: json['courierStatus'] != null
          ? OrderCourierStatus.fromValue(json['courierStatus'] as int?)
          : null,
      courierAssignedAt: json['courierAssignedAt'] != null
          ? DateTime.parse(json['courierAssignedAt'])
          : null,
      courierAcceptedAt: json['courierAcceptedAt'] != null
          ? DateTime.parse(json['courierAcceptedAt'])
          : null,
      courierRejectedAt: json['courierRejectedAt'] != null
          ? DateTime.parse(json['courierRejectedAt'])
          : null,
      rejectReason: json['rejectReason']?.toString(),
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'])
          : null,
      outForDeliveryAt: json['outForDeliveryAt'] != null
          ? DateTime.parse(json['outForDeliveryAt'])
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'])
          : null,
      courierTip: (json['courierTip'] as num?)?.toDouble(),
    );
  }
}

class CourierOrderItem {
  final String productName;
  final int quantity;

  CourierOrderItem({required this.productName, required this.quantity});

  factory CourierOrderItem.fromJson(Map<String, dynamic> json) {
    return CourierOrderItem(
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }
}
