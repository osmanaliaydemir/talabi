import 'package:equatable/equatable.dart';

class SystemSettingModel extends Equatable {
  const SystemSettingModel({
    required this.key,
    required this.value,
    this.description,
    this.group,
  });

  factory SystemSettingModel.fromJson(Map<String, dynamic> json) {
    return SystemSettingModel(
      key: json['key'] as String,
      value: json['value'] as String,
      description: json['description'] as String?,
      group: json['group'] as String?,
    );
  }

  final String key;
  final String value;
  final String? description;
  final String? group;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'value': value,
      'description': description,
      'group': group,
    };
  }

  @override
  List<Object?> get props => [key, value, description, group];
}
