import 'package:dio/dio.dart';
import '../../errors/app_exception.dart';

/// Maps HTTP status codes to typed [AppException] subclasses.
/// Handles both legacy and envelope-shaped error responses.
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor({Dio Function()? dioProvider}) : _dioProvider = dioProvider;

  final Dio Function()? _dioProvider;

  static const String _localRetryKey = '_local_retry_attempted';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    var effectiveErr = err;
    if (_isRetryableConnectionError(err) &&
        !_didAttemptLocalRetry(err.requestOptions)) {
      try {
        final retried = await _retryWithAlternateLocalHosts(err.requestOptions);
        if (retried != null) {
          handler.resolve(retried);
          return;
        }
      } on DioException catch (retryErr) {
        effectiveErr = retryErr;
      }
    }

    final appException = _mapToAppException(effectiveErr);
    handler.next(
      DioException(
        requestOptions: effectiveErr.requestOptions,
        response: effectiveErr.response,
        type: effectiveErr.type,
        error: appException,
        message: appException.message,
      ),
    );
  }

  bool _isRetryableConnectionError(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.type == DioExceptionType.sendTimeout ||
      err.type == DioExceptionType.connectionError;

  bool _didAttemptLocalRetry(RequestOptions requestOptions) =>
      requestOptions.extra[_localRetryKey] == true;

  Future<Response<dynamic>?> _retryWithAlternateLocalHosts(
    RequestOptions requestOptions,
  ) async {
    final dio = _dioProvider?.call();
    if (dio == null) return null;

    final baseUri = Uri.tryParse(requestOptions.baseUrl);
    final currentHost = baseUri?.host.toLowerCase();
    if (currentHost == null || !_isLocalApi(currentHost)) return null;

    final fallbackHosts = _localHostFallbacks(currentHost);
    if (fallbackHosts.isEmpty) return null;

    for (final host in fallbackHosts) {
      final retryBaseUrl = baseUri!.replace(host: host).toString();
      final retryOptions = requestOptions.copyWith(
        baseUrl: retryBaseUrl,
        extra: {
          ...requestOptions.extra,
          _localRetryKey: true,
          'local_retry_host': host,
        },
      );
      try {
        return await dio.fetch<dynamic>(retryOptions);
      } on DioException catch (retryErr) {
        if (_isRetryableConnectionError(retryErr)) {
          continue;
        }
        rethrow;
      }
    }
    return null;
  }

  List<String> _localHostFallbacks(String currentHost) {
    const order = <String>[
      'localhost',
      '127.0.0.1',
      '10.0.2.2',
      'host.docker.internal',
    ];
    return order.where((h) => h != currentHost).toList();
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
              'Cannot reach local backend at $target. '
              'If backend is running, verify API_BASE_URL/device host mapping and try again.',
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
      case 410:
        return GoneException(
          message:
              detail ?? 'This API is no longer available. Please update the app.',
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

  bool _isLocalApi(String host) =>
      host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '10.0.2.2' ||
      host == 'host.docker.internal';

  /// Extracts the best human-readable error message from possible backend shapes.
  String? _extractDetail(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }

      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map) {
          return first['msg']?.toString() ?? first.toString();
        }
        return first.toString();
      }

      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final details = error['details'];
        if (details is String && details.isNotEmpty) {
          return details;
        }
        if (details is List && details.isNotEmpty) {
          return details.first.toString();
        }
        final code = error['code'];
        if (code is String && code.isNotEmpty) {
          return code;
        }
      }

      final legacyError = data['error'];
      if (legacyError is String && legacyError.isNotEmpty) return legacyError;
    }

    return data.toString();
  }
}
