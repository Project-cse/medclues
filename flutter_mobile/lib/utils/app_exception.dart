enum AppExceptionType {
  network,
  auth,
  server,
  validation,
  unknown,
}

class AppException implements Exception {
  final String message;
  final AppExceptionType type;
  final int? statusCode;

  const AppException(this.message, {this.type = AppExceptionType.unknown, this.statusCode});

  factory AppException.network([String? message]) => AppException(
        message ?? 'No internet connection',
        type: AppExceptionType.network,
      );

  factory AppException.auth([String? message]) => AppException(
        message ?? 'Session expired. Please login again.',
        type: AppExceptionType.auth,
        statusCode: 401,
      );

  factory AppException.server([String? message]) => AppException(
        message ?? 'Server error, please try again',
        type: AppExceptionType.server,
        statusCode: 500,
      );

  factory AppException.validation(String message) =>
      AppException(message, type: AppExceptionType.validation);

  @override
  String toString() => message;
}
