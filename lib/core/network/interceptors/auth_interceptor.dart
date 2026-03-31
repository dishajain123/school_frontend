import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../storage/secure_storage.dart';

/// Attaches Bearer token to every request.
/// On 401, attempts a silent token refresh and retries.
/// On refresh failure, clears tokens and triggers logout.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.onLogout,
  });

  final SecureStorage secureStorage;
  final void Function() onLogout;

  // Used to prevent infinite refresh loops.
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for auth endpoints that don't need it.
    final path = options.path;
    if (path == ApiConstants.login ||
        path == ApiConstants.forgotPassword ||
        path == ApiConstants.verifyOtp ||
        path == ApiConstants.resetPassword) {
      return handler.next(options);
    }

    final token = await secureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshToken = await secureStorage.readRefreshToken();
        if (refreshToken == null || refreshToken.isEmpty) {
          _handleLogout();
          return handler.next(err);
        }

        // Attempt refresh
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl + ApiConstants.apiPrefix,
            connectTimeout: const Duration(milliseconds: 10000),
            receiveTimeout: const Duration(milliseconds: 10000),
          ),
        );

        final response = await refreshDio.post(
          ApiConstants.refresh,
          data: {'refresh_token': refreshToken},
        );

        final newAccessToken = response.data['access_token'] as String?;
        if (newAccessToken == null) {
          _handleLogout();
          return handler.next(err);
        }

        // Persist new token
        await secureStorage.writeToken(newAccessToken);

        // Retry original request
        final retryOptions = err.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await refreshDio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        _handleLogout();
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }

  void _handleLogout() {
    secureStorage.clearAll();
    onLogout();
  }
}