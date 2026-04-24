import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class MediaUrlResolver {
  MediaUrlResolver._();

  static String? resolveNullable(String? rawUrl) {
    final trimmed = rawUrl?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return resolve(trimmed);
  }

  static String resolve(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return value;

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    if (!uri.hasScheme) {
      if (value.startsWith('/')) {
        return '${ApiConstants.resolvedBaseUrl}$value';
      }
      return value;
    }

    if (kIsWeb) return value;
    if (!_isLoopback(uri.host)) return value;

    final apiBase = Uri.tryParse(ApiConstants.resolvedBaseUrl);
    if (apiBase == null || apiBase.host.isEmpty) return value;

    return uri
        .replace(
          scheme: apiBase.scheme.isEmpty ? uri.scheme : apiBase.scheme,
          host: apiBase.host,
          port: apiBase.hasPort ? apiBase.port : uri.port,
        )
        .toString();
  }

  static bool _isLoopback(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '0.0.0.0' ||
        normalized == '::1' ||
        normalized == '::';
  }
}
