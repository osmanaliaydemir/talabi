class CourierEarning {
  CourierEarning({
    required this.id,
    required this.orderId,
    required this.baseDeliveryFee,
    required this.distanceBonus,
    required this.tipAmount,
    required this.totalEarning,
    required this.earnedAt,
    required this.isPaid,
  });

  factory CourierEarning.fromJson(Map<String, dynamic> json) {
    return CourierEarning(
      id: json['id'],
      orderId: json['orderId'].toString(),
      baseDeliveryFee: (json['baseDeliveryFee'] as num).toDouble(),
      distanceBonus: (json['distanceBonus'] as num).toDouble(),
      tipAmount: (json['tipAmount'] as num).toDouble(),
      totalEarning: (json['totalEarning'] as num).toDouble(),
      earnedAt: DateTime.parse(json['earnedAt']),
      isPaid: json['isPaid'],
    );
  }
  final int id;
  final String orderId;
  final double baseDeliveryFee;
  final double distanceBonus;
  final double tipAmount;
  final double totalEarning;
  final DateTime earnedAt;
  final bool isPaid;
}

class EarningsSummary {
  EarningsSummary({
    required this.totalEarnings,
    required this.totalDeliveries,
    required this.averageEarningPerDelivery,
    required this.earnings,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['totalEarnings'] as num).toDouble(),
      totalDeliveries: json['totalDeliveries'],
      averageEarningPerDelivery: (json['averageEarningPerDelivery'] as num)
          .toDouble(),
      earnings: (json['earnings'] as List)
          .map((e) => CourierEarning.fromJson(e))
          .toList(),
    );
  }
  final double totalEarnings;
  final int totalDeliveries;
  final double averageEarningPerDelivery;
  final List<CourierEarning> earnings;
}
