import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_logout_bus.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';

/// Provider for the configured Dio HTTP client.
final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl + ApiConstants.apiPrefix,
      connectTimeout:
          const Duration(milliseconds: ApiConstants.connectTimeoutMs),
      receiveTimeout:
          const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(
      secureStorage: secureStorage,
      onLogout: () {
        // Clear tokens first, then notify the auth notifier via the bus.
        secureStorage.clearAll();
        AuthLogoutBus.instance.notifyLogout();
      },
    ),
    ErrorInterceptor(),
    LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (o) {
        assert(() {
          // ignore: avoid_print
          print('[Dio] $o');
          return true;
        }());
      },
    ),
  ]);

  return dio;
});