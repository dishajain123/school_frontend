import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth/current_user.dart';
import '../../../providers/audit_provider.dart';
import '../../../providers/auth_provider.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final allowed = user != null &&
        (user.role == UserRole.principal ||
            user.role == UserRole.superadmin ||
            user.role == UserRole.trustee);
    if (!allowed) {
      return const Scaffold(
        body: Center(child: Text('You do not have access to audit logs.')),
      );
    }

    final logs = ref.watch(auditLogsProvider((
      action: null,
      entityType: null,
      q: _searchCtrl.text.trim(),
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(auditLogsProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                labelText: 'Search description',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: logs.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('No audit logs found.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.description),
                      subtitle: Text(
                        '${item.action} • ${item.entityType} • ${item.occurredAt.toLocal()}',
                      ),
                      trailing: Text(item.actorName ?? '-'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
