class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic raw)? parser,
  ) {
    final ok = json['success'] != false;
    dynamic payload = json['data'] ?? json['userData'] ?? json['user'] ?? json;
    if (parser != null && payload != null) {
      return ApiResponse(success: ok, message: json['message']?.toString(), data: parser(payload));
    }
    return ApiResponse(success: ok, message: json['message']?.toString(), data: payload as T?);
  }
}
