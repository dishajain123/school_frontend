import 'app_exception.dart';

/// User-facing failure model used as the error side of [AsyncValue].
class Failure {
  const Failure({
    required this.message,
    this.statusCode,
    this.isUnauthorized = false,
  });

  final String message;
  final int? statusCode;
  final bool isUnauthorized;

  factory Failure.fromException(AppException e) => Failure(
        message: e.message,
        statusCode: e.statusCode,
        isUnauthorized: e is UnauthorizedException,
      );

  factory Failure.fromError(Object error) {
    if (error is AppException) return Failure.fromException(error);
    return Failure(message: error.toString());
  }

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';
}