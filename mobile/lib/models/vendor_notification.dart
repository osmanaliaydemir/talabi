class VendorNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final int? relatedEntityId;
  final DateTime createdAt;

  VendorNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.isRead = false,
    this.relatedEntityId,
    required this.createdAt,
  });

  factory VendorNotification.fromJson(Map<String, dynamic> json) {
    return VendorNotification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      relatedEntityId: json['relatedEntityId'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
