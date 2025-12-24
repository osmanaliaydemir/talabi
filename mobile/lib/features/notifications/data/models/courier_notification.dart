class CourierNotification {
  CourierNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.orderId,
  });

  factory CourierNotification.fromJson(Map<String, dynamic> json) {
    return CourierNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'general',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      orderId: json['orderId']?.toString(),
    );
  }
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? orderId;

  bool get isOrderRelated =>
      type.toLowerCase().contains('order') ||
      type.toLowerCase().contains('assignment') ||
      type.toLowerCase().contains('offer');

  bool get isSystemRelated => !isOrderRelated;
}

class CourierNotificationResponse {
  CourierNotificationResponse({required this.items, required this.unreadCount});

  factory CourierNotificationResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] ?? [];
    return CourierNotificationResponse(
      items: rawItems
          .map((notification) => CourierNotification.fromJson(notification))
          .toList(),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
  final List<CourierNotification> items;
  final int unreadCount;
}
