import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum AnnouncementType {
  exam,
  event,
  holiday,
  general,
}

extension AnnouncementTypeX on AnnouncementType {
  static AnnouncementType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'EXAM':
        return AnnouncementType.exam;
      case 'EVENT':
        return AnnouncementType.event;
      case 'HOLIDAY':
        return AnnouncementType.holiday;
      default:
        return AnnouncementType.general;
    }
  }

  String get backendValue {
    switch (this) {
      case AnnouncementType.exam:
        return 'EXAM';
      case AnnouncementType.event:
        return 'EVENT';
      case AnnouncementType.holiday:
        return 'HOLIDAY';
      case AnnouncementType.general:
        return 'GENERAL';
    }
  }

  String get label {
    switch (this) {
      case AnnouncementType.exam:
        return 'Exam';
      case AnnouncementType.event:
        return 'Event';
      case AnnouncementType.holiday:
        return 'Holiday';
      case AnnouncementType.general:
        return 'General';
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementType.exam:
        return Icons.quiz_outlined;
      case AnnouncementType.event:
        return Icons.event_outlined;
      case AnnouncementType.holiday:
        return Icons.beach_access_outlined;
      case AnnouncementType.general:
        return Icons.campaign_outlined;
    }
  }

  Color get color {
    switch (this) {
      case AnnouncementType.exam:
        return AppColors.subjectMath;
      case AnnouncementType.event:
        return AppColors.infoBlue;
      case AnnouncementType.holiday:
        return AppColors.successGreen;
      case AnnouncementType.general:
        return AppColors.navyMedium;
    }
  }
}

class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.publishedAt,
    required this.isActive,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.targetRole,
    this.targetStandardId,
    this.attachmentKey,
    this.attachmentUrl,
  });

  final String id;
  final String title;
  final String body;
  final AnnouncementType type;
  final DateTime publishedAt;
  final bool isActive;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? targetRole;
  final String? targetStandardId;
  final String? attachmentKey;
  final String? attachmentUrl;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: AnnouncementTypeX.fromString(json['type'] as String?),
      publishedAt: DateTime.parse(json['published_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      targetRole: json['target_role'] as String?,
      targetStandardId: json['target_standard_id'] as String?,
      attachmentKey: json['attachment_key'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.backendValue,
        'published_at': publishedAt.toIso8601String(),
        'is_active': isActive,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'target_role': targetRole,
        'target_standard_id': targetStandardId,
        'attachment_key': attachmentKey,
        'attachment_url': attachmentUrl,
      };
}