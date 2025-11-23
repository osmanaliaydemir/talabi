class OrderDetail {
  final int id;
  final int vendorId;
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
      id: json['id'],
      vendorId: json['vendorId'],
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
  final int productId;
  final String productName;
  final String? productImageUrl;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  OrderItemDetail({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory OrderItemDetail.fromJson(Map<String, dynamic> json) {
    return OrderItemDetail(
      productId: json['productId'],
      productName: json['productName'],
      productImageUrl: json['productImageUrl'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
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
