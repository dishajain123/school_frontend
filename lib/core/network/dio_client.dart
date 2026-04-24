import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_logout_bus.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/envelope_interceptor.dart';
import 'interceptors/error_interceptor.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  final resolvedBaseUrl = _buildApiBaseUrl(
    ApiConstants.resolvedBaseUrl,
    ApiConstants.apiPrefix,
  );

  final dio = Dio(
    BaseOptions(
      baseUrl: resolvedBaseUrl,
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
        secureStorage.clearAll();
        AuthLogoutBus.instance.notifyLogout();
      },
    ),
    EnvelopeInterceptor(),
    ErrorInterceptor(),
  ]);

  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (o) => debugPrint('$o'),
      ),
    );
  }

  return dio;
});

String _buildApiBaseUrl(String baseUrl, String apiPrefix) {
  final cleanBase = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl;
  final cleanPrefix = apiPrefix.startsWith('/') ? apiPrefix : '/$apiPrefix';
  if (cleanBase.endsWith(cleanPrefix)) {
    return cleanBase;
  }
  return '$cleanBase$cleanPrefix';
}
