class PromotionalBanner {
  final String id;
  final String title;
  final String subtitle;
  final String? buttonText;
  final String? buttonAction;
  final String? imageUrl;
  final int displayOrder;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? languageCode;
  final int? vendorType;

  PromotionalBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    this.buttonText,
    this.buttonAction,
    this.imageUrl,
    required this.displayOrder,
    required this.isActive,
    this.startDate,
    this.endDate,
    this.languageCode,
    this.vendorType,
  });

  factory PromotionalBanner.fromJson(Map<String, dynamic> json) {
    return PromotionalBanner(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      buttonText: json['buttonText'],
      buttonAction: json['buttonAction'],
      imageUrl: json['imageUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      languageCode: json['languageCode'],
      vendorType: json['vendorType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'buttonText': buttonText,
      'buttonAction': buttonAction,
      'imageUrl': imageUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'languageCode': languageCode,
      'vendorType': vendorType,
    };
  }
}
