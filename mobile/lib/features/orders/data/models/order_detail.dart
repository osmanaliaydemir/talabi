class OrderDetail {
  OrderDetail({
    required this.id,
    required this.customerOrderId,
    required this.vendorId,
    required this.vendorName,
    this.vendorImageUrl,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.cancelReason,
    required this.items,
    required this.statusHistory,
    this.activeOrderCourier,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id']?.toString() ?? '',
      customerOrderId: json['customerOrderId']?.toString() ?? '',
      vendorId: json['vendorId']?.toString() ?? '',
      vendorName: json['vendorName']?.toString() ?? '',
      vendorImageUrl: json['vendorImageUrl']?.toString(),
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancelReason: json['cancelReason']?.toString(),
      items:
          (json['items'] as List?)
              ?.map(
                (item) =>
                    OrderItemDetail.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
      statusHistory:
          (json['statusHistory'] as List?)
              ?.map(
                (history) => OrderStatusHistory.fromJson(
                  history as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
      activeOrderCourier: json['activeOrderCourier'] != null
          ? OrderCourierDetail.fromJson(
              json['activeOrderCourier'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  final String id;
  final String customerOrderId;
  final String vendorId;
  final String vendorName;
  final String? vendorImageUrl;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final List<OrderItemDetail> items;
  final List<OrderStatusHistory> statusHistory;
  final OrderCourierDetail? activeOrderCourier;
}

class OrderCourierDetail {
  OrderCourierDetail({
    required this.courierId,
    required this.courierName,
    this.courierImageUrl,
    this.courierPhone,
  });

  factory OrderCourierDetail.fromJson(Map<String, dynamic> json) {
    return OrderCourierDetail(
      courierId: json['courierId']?.toString() ?? '',
      courierName: json['courierName']?.toString() ?? '',
      courierImageUrl: json['courierImageUrl']?.toString(),
      courierPhone: json['courierPhone']?.toString(),
    );
  }

  final String courierId;
  final String courierName;
  final String? courierImageUrl;
  final String? courierPhone;
}

class OrderItemDetail {
  // ... existing OrderItemDetail ...
  OrderItemDetail({
    required this.productId,
    required this.customerOrderItemId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelReason,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      productId: json['productId']?.toString() ?? '',
      customerOrderItemId: json['customerOrderItemId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      isCancelled: json['isCancelled'] as bool? ?? false,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancelReason: json['cancelReason']?.toString(),
    );
  }
  final String productId;
  final String customerOrderItemId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final String? cancelReason;
}

class OrderStatusHistory {
  OrderStatusHistory({
    required this.status,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      createdBy: json['createdBy']?.toString() ?? '',
    );
  }
  final String status;
  final String? note;
  final DateTime createdAt;
  final String createdBy;
}
