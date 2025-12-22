class VersionSettingsModel {
  VersionSettingsModel({
    required this.forceUpdate,
    required this.minVersionAndroid,
    required this.minVersionIOS,
    required this.titleTr,
    required this.titleEn,
    required this.titleAr,
    required this.bodyTr,
    required this.bodyEn,
    required this.bodyAr,
  });

  factory VersionSettingsModel.fromJson(Map<String, dynamic> json) {
    return VersionSettingsModel(
      forceUpdate: json['forceUpdate'] ?? false,
      minVersionAndroid: json['minVersionAndroid'] ?? '1.0.0',
      minVersionIOS: json['minVersionIOS'] ?? '1.0.0',
      titleTr: json['title_TR'] ?? '',
      titleEn: json['title_EN'] ?? '',
      titleAr: json['title_AR'] ?? '',
      bodyTr: json['body_TR'] ?? '',
      bodyEn: json['body_EN'] ?? '',
      bodyAr: json['body_AR'] ?? '',
    );
  }

  final bool forceUpdate;
  final String minVersionAndroid;
  final String minVersionIOS;
  final String titleTr;
  final String titleEn;
  final String titleAr;
  final String bodyTr;
  final String bodyEn;
  final String bodyAr;
}
