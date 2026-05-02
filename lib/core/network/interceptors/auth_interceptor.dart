import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../constants/storage_keys.dart';
import '../../storage/local_storage.dart';
import '../../storage/secure_storage.dart';

/// Attaches Bearer token to every request.
/// On 401, attempts a silent token refresh and retries the original request.
/// Do not force logout automatically; logout is user-driven from Profile.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.secureStorage,
    required this.localStorage,
    required this.onLogout,
  });

  final SecureStorage secureStorage;
  final LocalStorage localStorage;
  final void Function() onLogout;

  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
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
          return handler.next(err);
        }

        // Use a fresh Dio instance scoped only for the refresh call
        final refreshDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.resolvedBaseUrl + ApiConstants.apiPrefix,
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
          return handler.next(err);
        }

        await secureStorage.writeToken(newAccessToken);
        await localStorage.setString(
          StorageKeys.accessTokenBackup,
          newAccessToken,
        );

        // Retry the original request with the new token
        // Build a new RequestOptions with the updated Authorization header
        final retryOptions = err.requestOptions.copyWith(
          headers: {
            ...err.requestOptions.headers,
            'Authorization': 'Bearer $newAccessToken',
          },
        );

        // Use a fresh Dio to retry — its baseUrl is the same so path works
        final retryDio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.resolvedBaseUrl + ApiConstants.apiPrefix,
            connectTimeout: const Duration(milliseconds: 15000),
            receiveTimeout: const Duration(milliseconds: 30000),
          ),
        );

        final retryResponse = await retryDio.fetch(retryOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        return handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(err);
  }
}
