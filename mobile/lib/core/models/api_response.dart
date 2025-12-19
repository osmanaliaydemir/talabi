class ApiResponse<T> {
  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errorCode,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      errorCode: json['errorCode'],
      errors: json['errors'] != null ? List<String>.from(json['errors']) : null,
    );
  }
  final bool success;
  final String? message;
  final T? data;
  final String? errorCode;
  final List<String>? errors;
}
