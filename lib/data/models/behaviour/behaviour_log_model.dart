import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum IncidentType {
  positive,
  negative,
  neutral,
}

extension IncidentTypeX on IncidentType {
  static IncidentType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'POSITIVE':
        return IncidentType.positive;
      case 'NEGATIVE':
        return IncidentType.negative;
      default:
        return IncidentType.neutral;
    }
  }

  String get backendValue {
    switch (this) {
      case IncidentType.positive:
        return 'POSITIVE';
      case IncidentType.negative:
        return 'NEGATIVE';
      case IncidentType.neutral:
        return 'NEUTRAL';
    }
  }

  String get label {
    switch (this) {
      case IncidentType.positive:
        return 'Positive';
      case IncidentType.negative:
        return 'Negative';
      case IncidentType.neutral:
        return 'Neutral';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.positive:
        return Icons.sentiment_very_satisfied_rounded;
      case IncidentType.negative:
        return Icons.report_problem_outlined;
      case IncidentType.neutral:
        return Icons.drag_handle_rounded;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.positive:
        return AppColors.successGreen;
      case IncidentType.negative:
        return AppColors.errorRed;
      case IncidentType.neutral:
        return AppColors.grey600;
    }
  }
}

enum IncidentSeverity {
  low,
  medium,
  high,
}

extension IncidentSeverityX on IncidentSeverity {
  static IncidentSeverity fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'LOW':
        return IncidentSeverity.low;
      case 'HIGH':
        return IncidentSeverity.high;
      default:
        return IncidentSeverity.medium;
    }
  }

  String get backendValue {
    switch (this) {
      case IncidentSeverity.low:
        return 'LOW';
      case IncidentSeverity.medium:
        return 'MEDIUM';
      case IncidentSeverity.high:
        return 'HIGH';
    }
  }

  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Low';
      case IncidentSeverity.medium:
        return 'Medium';
      case IncidentSeverity.high:
        return 'High';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.low:
        return AppColors.infoBlue;
      case IncidentSeverity.medium:
        return AppColors.warningAmber;
      case IncidentSeverity.high:
        return AppColors.errorRed;
    }
  }
}

class BehaviourLogModel {
  const BehaviourLogModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.incidentType,
    required this.description,
    required this.severity,
    required this.incidentDate,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final IncidentType incidentType;
  final String description;
  final IncidentSeverity severity;
  final DateTime incidentDate;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Color get incidentTypeColor => incidentType.color;

  factory BehaviourLogModel.fromJson(Map<String, dynamic> json) {
    return BehaviourLogModel(
      id: (json['id'] ?? '').toString(),
      studentId: (json['student_id'] ?? '').toString(),
      teacherId: (json['teacher_id'] ?? '').toString(),
      incidentType: IncidentTypeX.fromString(json['incident_type'] as String?),
      description: (json['description'] ?? '').toString(),
      severity: IncidentSeverityX.fromString(json['severity'] as String?),
      incidentDate:
          DateTime.tryParse((json['incident_date'] ?? '').toString()) ??
              DateTime.now(),
      academicYearId: (json['academic_year_id'] ?? '').toString(),
      schoolId: (json['school_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class BehaviourLogListResponse {
  const BehaviourLogListResponse({
    required this.items,
    required this.total,
  });

  final List<BehaviourLogModel> items;
  final int total;

  factory BehaviourLogListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return BehaviourLogListResponse(
      items: rawItems
          .map((item) =>
              BehaviourLogModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawItems.length,
    );
  }
}
