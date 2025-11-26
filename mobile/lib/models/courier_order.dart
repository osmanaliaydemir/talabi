class CourierOrder {
  final int id;
  final String vendorName;
  final String vendorAddress;
  final double vendorLatitude;
  final double vendorLongitude;
  final String customerName;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final double deliveryFee;
  final String status;
  final DateTime createdAt;
  final List<CourierOrderItem> items;

  CourierOrder({
    required this.id,
    required this.vendorName,
    required this.vendorAddress,
    required this.vendorLatitude,
    required this.vendorLongitude,
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.deliveryFee,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory CourierOrder.fromJson(Map<String, dynamic> json) {
    return CourierOrder(
      id: json['id'],
      vendorName: json['vendorName'] ?? '',
      vendorAddress: json['vendorAddress'] ?? '',
      vendorLatitude: (json['vendorLatitude'] as num?)?.toDouble() ?? 0.0,
      vendorLongitude: (json['vendorLongitude'] as num?)?.toDouble() ?? 0.0,
      customerName: json['customerName'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      deliveryLatitude: (json['deliveryLatitude'] as num?)?.toDouble() ?? 0.0,
      deliveryLongitude: (json['deliveryLongitude'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => CourierOrderItem.fromJson(item))
              .toList() ??
          [],
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
