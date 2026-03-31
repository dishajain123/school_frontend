/// Base class for all typed app exceptions.
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.statusCode,
  });

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppException(statusCode: $statusCode, message: $message)';
}

/// 401 — Not authenticated or token expired.
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Authentication required. Please log in.',
    int? statusCode = 401,
  }) : super(message: message, statusCode: statusCode);
}

/// 403 — Authenticated but lacks permission.
class ForbiddenException extends AppException {
  const ForbiddenException({
    String message = 'You do not have permission to perform this action.',
    int? statusCode = 403,
  }) : super(message: message, statusCode: statusCode);
}

/// 404 — Resource not found.
class NotFoundException extends AppException {
  const NotFoundException({
    String message = 'The requested resource was not found.',
    int? statusCode = 404,
  }) : super(message: message, statusCode: statusCode);
}

/// 409 — Conflict (duplicate resource).
class ConflictException extends AppException {
  const ConflictException({
    String message = 'A conflict occurred. The resource may already exist.',
    int? statusCode = 409,
  }) : super(message: message, statusCode: statusCode);
}

/// 422 — Validation error from the server.
class ValidationException extends AppException {
  const ValidationException({
    String message = 'Validation failed. Please check your input.',
    int? statusCode = 422,
  }) : super(message: message, statusCode: statusCode);
}

/// 5xx / network / timeout errors.
class NetworkException extends AppException {
  const NetworkException({
    String message = 'A network error occurred. Please check your connection.',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Unknown / unclassified error.
class UnknownException extends AppException {
  const UnknownException({
    String message = 'An unexpected error occurred.',
    int? statusCode,
  }) : super(message: message, statusCode: statusCode);
}

/// Helper to extract a readable message from any exception.
String extractMessage(Object error) {
  if (error is AppException) return error.message;
  return error.toString();
}