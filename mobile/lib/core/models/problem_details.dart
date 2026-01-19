class ProblemDetails {
  const ProblemDetails({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.errors,
  });

  factory ProblemDetails.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? errorsMap;
    final rawErrors = json['errors'];
    if (rawErrors is Map<String, dynamic>) {
      errorsMap = rawErrors;
    }

    return ProblemDetails(
      type: json['type']?.toString(),
      title: json['title']?.toString(),
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse('${json['status']}'),
      detail: json['detail']?.toString(),
      instance: json['instance']?.toString(),
      errors: errorsMap,
    );
  }

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final Map<String, dynamic>? errors;

  /// Best-effort conversion to a user-facing message.
  String toUserMessage() {
    // Prefer detail if present
    final d = detail?.trim();
    if (d != null && d.isNotEmpty) return d;

    // Flatten validation errors: { field: [msg1, msg2], ... }
    final e = errors;
    if (e != null && e.isNotEmpty) {
      final messages = <String>[];
      e.forEach((_, value) {
        if (value is List) {
          messages.addAll(value.map((v) => v.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      });
      final joined = messages.where((m) => m.trim().isNotEmpty).join('\n');
      if (joined.isNotEmpty) return joined;
    }

    final t = title?.trim();
    if (t != null && t.isNotEmpty) return t;

    return 'İşlem gerçekleştirilemedi';
  }
}
