class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    required this.description,
    required this.occurredAt,
    this.actorName,
  });

  final String id;
  final String action;
  final String entityType;
  final String description;
  final DateTime occurredAt;
  final String? actorName;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      entityType: (json['entity_type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      occurredAt: DateTime.tryParse((json['occurred_at'] ?? '').toString()) ??
          DateTime.now(),
      actorName: json['actor_name'] as String?,
    );
  }
}
