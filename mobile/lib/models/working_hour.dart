class WorkingHour {
  const WorkingHour({
    required this.dayOfWeek,
    required this.dayName,
    this.startTime,
    this.endTime,
    this.isClosed = false,
  });

  factory WorkingHour.fromJson(Map<String, dynamic> json) {
    return WorkingHour(
      dayOfWeek: json['dayOfWeek'] as int,
      dayName: json['dayName'] as String,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      isClosed: json['isClosed'] as bool? ?? false,
    );
  }

  final int dayOfWeek;
  final String dayName;
  final String? startTime;
  final String? endTime;
  final bool isClosed;

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'dayName': dayName,
      'startTime': startTime,
      'endTime': endTime,
      'isClosed': isClosed,
    };
  }

  WorkingHour copyWith({
    int? dayOfWeek,
    String? dayName,
    String? startTime,
    String? endTime,
    bool? isClosed,
    bool allowNullTimes = false,
  }) {
    return WorkingHour(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayName: dayName ?? this.dayName,
      startTime: allowNullTimes && startTime == null
          ? null
          : (startTime ?? this.startTime),
      endTime: allowNullTimes && endTime == null
          ? null
          : (endTime ?? this.endTime),
      isClosed: isClosed ?? this.isClosed,
    );
  }
}
