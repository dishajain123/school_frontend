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
    super.message = 'Authentication required. Please log in.',
    super.statusCode = 401,
  });
}

/// 403 — Authenticated but lacks permission.
class ForbiddenException extends AppException {
  const ForbiddenException({
    super.message = 'You do not have permission to perform this action.',
    super.statusCode = 403,
  });
}

/// 404 — Resource not found.
class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'The requested resource was not found.',
    super.statusCode = 404,
  });
}

/// 409 — Conflict (duplicate resource).
class ConflictException extends AppException {
  const ConflictException({
    super.message = 'A conflict occurred. The resource may already exist.',
    super.statusCode = 409,
  });
}

/// 410 — Resource has been permanently removed.
class GoneException extends AppException {
  const GoneException({
    super.message = 'This feature is no longer available. Please update the app.',
    super.statusCode = 410,
  });
}


/// 422 — Validation error from the server.
class ValidationException extends AppException {
  const ValidationException({
    super.message = 'Validation failed. Please check your input.',
    super.statusCode = 422,
  });
}

/// 5xx / network / timeout errors.
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'A network error occurred. Please check your connection.',
    super.statusCode,
  });
}

/// Unknown / unclassified error.
class UnknownException extends AppException {
  const UnknownException({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
  });
}

/// Helper to extract a readable message from any exception.
String extractMessage(Object error) {
  if (error is AppException) return error.message;
  return error.toString();
}