class OrderDetail {
  final String id;
  final String customerOrderId;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final List<OrderItemDetail> items;
  final List<OrderStatusHistory> statusHistory;

  OrderDetail({
    required this.id,
    required this.customerOrderId,
    required this.vendorId,
    required this.vendorName,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
    this.cancelReason,
    required this.items,
    required this.statusHistory,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'].toString(),
      customerOrderId: json['customerOrderId']?.toString() ?? '',
      vendorId: json['vendorId'].toString(),
      vendorName: json['vendorName'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancelReason: json['cancelReason'],
      items: (json['items'] as List)
          .map((item) => OrderItemDetail.fromJson(item))
          .toList(),
      statusHistory: (json['statusHistory'] as List)
          .map((history) => OrderStatusHistory.fromJson(history))
          .toList(),
    );
  }
}

class OrderItemDetail {
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
      productId: json['productId'].toString(),
      customerOrderItemId: json['customerOrderItemId']?.toString() ?? '',
      productName: json['productName'],
      productImageUrl: json['productImageUrl'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      isCancelled: json['isCancelled'] ?? false,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'])
          : null,
      cancelReason: json['cancelReason'],
    );
  }
}

class OrderStatusHistory {
  final String status;
  final String? note;
  final DateTime createdAt;
  final String createdBy;

  OrderStatusHistory({
    required this.status,
    this.note,
    required this.createdAt,
    required this.createdBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      status: json['status'],
      note: json['note'],
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
    );
  }
}
