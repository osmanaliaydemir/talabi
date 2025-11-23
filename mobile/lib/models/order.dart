class Order {
  final int id;
  final int vendorId;
  final String vendorName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
