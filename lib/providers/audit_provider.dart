import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/audit/audit_log_model.dart';
import '../data/repositories/audit_repository.dart';

typedef AuditQuery = ({String? action, String? entityType, String? q});

final auditLogsProvider =
    FutureProvider.family<List<AuditLogModel>, AuditQuery>((ref, query) async {
  return ref.read(auditRepositoryProvider).list(
        action: query.action,
        entityType: query.entityType,
        q: query.q,
      );
});
