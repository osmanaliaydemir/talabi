class VendorSettings {
  VendorSettings({
    this.minimumOrderAmount,
    this.deliveryFee,
    this.estimatedDeliveryTime,
    this.isActive = true,
    this.openingHours,
  });

  factory VendorSettings.fromJson(Map<String, dynamic> json) {
    return VendorSettings(
      minimumOrderAmount: json['minimumOrderAmount'] != null
          ? (json['minimumOrderAmount'] as num).toDouble()
          : null,
      deliveryFee: json['deliveryFee'] != null
          ? (json['deliveryFee'] as num).toDouble()
          : null,
      estimatedDeliveryTime: json['estimatedDeliveryTime'],
      isActive: json['isActive'] ?? true,
      openingHours: json['openingHours'],
    );
  }
  final double? minimumOrderAmount;
  final double? deliveryFee;
  final int? estimatedDeliveryTime;
  final bool isActive;
  final String? openingHours;

  Map<String, dynamic> toJson() {
    return {
      'minimumOrderAmount': minimumOrderAmount,
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'isActive': isActive,
      'openingHours': openingHours,
    };
  }
}
