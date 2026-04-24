import 'package:dio/dio.dart';

/// Normalizes API envelope responses to keep repositories simple.
///
/// Supported envelope:
/// {
///   "success": true|false,
///   "data": ...,
///   "message": "...",
///   "error": {...}|null
/// }
class EnvelopeInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;
    if (body is! Map<String, dynamic>) {
      handler.next(response);
      return;
    }

    final hasEnvelopeKeys = body.containsKey('success') &&
        body.containsKey('data') &&
        body.containsKey('message') &&
        body.containsKey('error');
    if (!hasEnvelopeKeys) {
      handler.next(response);
      return;
    }

    final success = body['success'] == true;
    if (success) {
      response.data = body['data'];
      handler.next(response);
      return;
    }

    final message = _extractMessage(body) ?? 'Request failed.';
    handler.reject(
      DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        error: body,
        message: message,
      ),
    );
  }

  String? _extractMessage(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;

    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final details = error['details'];
      if (details is String && details.isNotEmpty) return details;
      final code = error['code'];
      if (code is String && code.isNotEmpty) return code;
    }

    return null;
  }
}
