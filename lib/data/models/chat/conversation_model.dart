import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum ConversationType {
  oneToOne,
  group,
}

extension ConversationTypeX on ConversationType {
  static ConversationType fromString(String? value) {
    switch ((value ?? '').toUpperCase().replaceAll('-', '_')) {
      case 'GROUP':
        return ConversationType.group;
      default:
        return ConversationType.oneToOne;
    }
  }

  String get backendValue {
    switch (this) {
      case ConversationType.oneToOne:
        return 'ONE_TO_ONE';
      case ConversationType.group:
        return 'GROUP';
    }
  }

  String get label {
    switch (this) {
      case ConversationType.oneToOne:
        return 'Direct Message';
      case ConversationType.group:
        return 'Group Chat';
    }
  }

  IconData get icon {
    switch (this) {
      case ConversationType.oneToOne:
        return Icons.person_outline_rounded;
      case ConversationType.group:
        return Icons.group_outlined;
    }
  }
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.type,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.name,
    this.displayNameOverride,
    this.standardId,
    this.createdBy,
    this.academicYearId,
  });

  final String id;
  final ConversationType type;
  final String? name;
  final String? displayNameOverride;
  final String? standardId;
  final String? createdBy;
  final String? academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: ConversationTypeX.fromString(json['type'] as String?),
      name: json['name'] as String?,
      displayNameOverride: json['display_name'] as String?,
      standardId: json['standard_id'] as String?,
      createdBy: json['created_by'] as String?,
      academicYearId: json['academic_year_id'] as String?,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Derive a sensible display name from available fields.
  String get displayName {
    if (displayNameOverride != null && displayNameOverride!.isNotEmpty) {
      return displayNameOverride!;
    }
    if (name != null && name!.isNotEmpty) return name!;
    return type.label;
  }

  String get initials {
    final dn = displayName;
    final parts = dn.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'C';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color get avatarColor {
    final hash = id.codeUnits.fold(0, (a, b) => a + b);
    return AppColors.avatarPalette[hash % AppColors.avatarPalette.length];
  }

  ConversationModel copyWith({
    String? name,
    String? displayNameOverride,
    String? standardId,
    String? academicYearId,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      name: name ?? this.name,
      displayNameOverride: displayNameOverride ?? this.displayNameOverride,
      standardId: standardId ?? this.standardId,
      createdBy: createdBy,
      academicYearId: academicYearId ?? this.academicYearId,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ConversationModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
