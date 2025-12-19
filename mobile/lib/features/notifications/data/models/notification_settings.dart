class NotificationSettings {
  NotificationSettings({
    required this.orderUpdates,
    required this.promotions,
    required this.newProducts,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      orderUpdates: json['orderUpdates'],
      promotions: json['promotions'],
      newProducts: json['newProducts'],
    );
  }

  bool orderUpdates;
  bool promotions;
  bool newProducts;

  Map<String, dynamic> toJson() {
    return {
      'orderUpdates': orderUpdates,
      'promotions': promotions,
      'newProducts': newProducts,
    };
  }
}
