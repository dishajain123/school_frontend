import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/audit/audit_log_model.dart';

class AuditRepository {
  const AuditRepository(this._dio);
  final Dio _dio;

  Future<List<AuditLogModel>> list({
    int page = 1,
    int pageSize = 50,
    String? action,
    String? entityType,
    String? q,
  }) async {
    final response = await _dio.get(
      ApiConstants.auditLogs,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (action != null && action.trim().isNotEmpty) 'action': action.trim(),
        if (entityType != null && entityType.trim().isNotEmpty)
          'entity_type': entityType.trim(),
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
      },
    );
    final items =
        (response.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
            const [];
    return items
        .map((e) => AuditLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  return AuditRepository(ref.read(dioClientProvider));
});
