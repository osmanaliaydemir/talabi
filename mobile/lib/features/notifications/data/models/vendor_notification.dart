class VendorNotification {
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
      id: json['id'].toString(),
      type: json['type'],
      title: json['title'],
      message: json['message'],
      isRead: json['isRead'] ?? false,
      relatedEntityId: json['relatedEntityId']?.toString(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? relatedEntityId;
  final DateTime createdAt;
}
