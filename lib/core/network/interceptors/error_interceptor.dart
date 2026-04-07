import 'package:dio/dio.dart';
import '../../errors/app_exception.dart';

/// Maps HTTP status codes to typed [AppException] subclasses.
/// Extracts the `detail` field from backend JSON error bodies.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = _mapToAppException(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: appException,
        message: appException.message,
      ),
    );
  }

  AppException _mapToAppException(DioException err) {
    // Network / timeout errors (no HTTP response)
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      if (_isLocalApi(err.requestOptions.uri.host)) {
        final uri = err.requestOptions.uri;
        final target = '${uri.host}:${uri.port}';
        return NetworkException(
          message:
              'Cannot reach local backend at $target. Start backend server and try again.',
        );
      }
      return const NetworkException(
        message: 'Connection timed out. Please check your internet.',
      );
    }

    final response = err.response;
    if (response == null) {
      return const NetworkException();
    }

    final statusCode = response.statusCode ?? 0;
    final detail = _extractDetail(response.data);

    switch (statusCode) {
      case 400:
        return ValidationException(
          message: detail ?? 'Bad request.',
          statusCode: statusCode,
        );
      case 401:
        return UnauthorizedException(
          message: detail ?? 'Authentication required.',
          statusCode: statusCode,
        );
      case 403:
        return ForbiddenException(
          message: detail ?? 'Access denied.',
          statusCode: statusCode,
        );
      case 404:
        return NotFoundException(
          message: detail ?? 'Resource not found.',
          statusCode: statusCode,
        );
      case 409:
        return ConflictException(
          message: detail ?? 'Conflict: resource already exists.',
          statusCode: statusCode,
        );
      case 422:
        return ValidationException(
          message: detail ?? 'Validation failed.',
          statusCode: statusCode,
        );
      case 429:
        return NetworkException(
          message: 'Too many requests. Please wait and try again.',
          statusCode: statusCode,
        );
      default:
        if (statusCode >= 500) {
          return NetworkException(
            message: detail ?? 'Server error. Please try again later.',
            statusCode: statusCode,
          );
        }
        return UnknownException(
          message: detail ?? 'An unexpected error occurred.',
          statusCode: statusCode,
        );
    }
  }

  bool _isLocalApi(String host) => host == 'localhost' || host == '127.0.0.1';

  /// Extracts the human-readable message from backend error body.
  /// Backend sends: { "error": "...", "detail": "...", "request_id": "..." }
  String? _extractDetail(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      // 422 validation errors: detail is a list
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          return first['msg']?.toString() ?? first.toString();
        }
        return detail.first.toString();
      }
      return data['error']?.toString();
    }
    return data.toString();
  }
}
