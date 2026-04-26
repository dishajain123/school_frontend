// lib/data/models/enrollment/enrollment_model.dart
// Phase 6 & 7 — enrollment and promotion data models.
import 'package:flutter/material.dart';

// ── AdmissionType ─────────────────────────────────────────────────────────────

enum AdmissionType {
  newAdmission,
  midYear,
  transferIn,
  readmission,
}

extension AdmissionTypeX on AdmissionType {
  String get backendValue {
    switch (this) {
      case AdmissionType.newAdmission:
        return 'NEW_ADMISSION';
      case AdmissionType.midYear:
        return 'MID_YEAR';
      case AdmissionType.transferIn:
        return 'TRANSFER_IN';
      case AdmissionType.readmission:
        return 'READMISSION';
    }
  }

  String get label {
    switch (this) {
      case AdmissionType.newAdmission:
        return 'New Admission';
      case AdmissionType.midYear:
        return 'Mid-Year Admission';
      case AdmissionType.transferIn:
        return 'Transfer In';
      case AdmissionType.readmission:
        return 'Re-admission';
    }
  }

  static AdmissionType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'MID_YEAR':
        return AdmissionType.midYear;
      case 'TRANSFER_IN':
        return AdmissionType.transferIn;
      case 'READMISSION':
        return AdmissionType.readmission;
      default:
        return AdmissionType.newAdmission;
    }
  }
}

// ── EnrollmentStatus ──────────────────────────────────────────────────────────

enum EnrollmentStatus {
  active,
  hold,
  completed,
  left,
  transferred,
  promoted,
  repeated,
}

extension EnrollmentStatusX on EnrollmentStatus {
  String get backendValue {
    switch (this) {
      case EnrollmentStatus.active:
        return 'ACTIVE';
      case EnrollmentStatus.hold:
        return 'HOLD';
      case EnrollmentStatus.completed:
        return 'COMPLETED';
      case EnrollmentStatus.left:
        return 'LEFT';
      case EnrollmentStatus.transferred:
        return 'TRANSFERRED';
      case EnrollmentStatus.promoted:
        return 'PROMOTED';
      case EnrollmentStatus.repeated:
        return 'REPEATED';
    }
  }

  String get label {
    switch (this) {
      case EnrollmentStatus.active:
        return 'Active';
      case EnrollmentStatus.hold:
        return 'On Hold';
      case EnrollmentStatus.completed:
        return 'Completed';
      case EnrollmentStatus.left:
        return 'Left';
      case EnrollmentStatus.transferred:
        return 'Transferred';
      case EnrollmentStatus.promoted:
        return 'Promoted';
      case EnrollmentStatus.repeated:
        return 'Repeated';
    }
  }

  Color get color {
    switch (this) {
      case EnrollmentStatus.active:
        return Colors.green;
      case EnrollmentStatus.hold:
        return Colors.orange;
      case EnrollmentStatus.completed:
        return Colors.blue;
      case EnrollmentStatus.left:
        return Colors.red;
      case EnrollmentStatus.transferred:
        return Colors.purple;
      case EnrollmentStatus.promoted:
        return Colors.teal;
      case EnrollmentStatus.repeated:
        return Colors.deepOrange;
    }
  }

  static EnrollmentStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'HOLD':
        return EnrollmentStatus.hold;
      case 'COMPLETED':
        return EnrollmentStatus.completed;
      case 'LEFT':
        return EnrollmentStatus.left;
      case 'TRANSFERRED':
        return EnrollmentStatus.transferred;
      case 'PROMOTED':
        return EnrollmentStatus.promoted;
      case 'REPEATED':
        return EnrollmentStatus.repeated;
      default:
        return EnrollmentStatus.active;
    }
  }
}

// ── PromotionDecision ─────────────────────────────────────────────────────────

enum PromotionDecision {
  promote,
  repeat,
  graduate,
  skip,
}

extension PromotionDecisionX on PromotionDecision {
  String get backendValue {
    switch (this) {
      case PromotionDecision.promote:
        return 'PROMOTE';
      case PromotionDecision.repeat:
        return 'REPEAT';
      case PromotionDecision.graduate:
        return 'GRADUATE';
      case PromotionDecision.skip:
        return 'SKIP';
    }
  }

  String get label {
    switch (this) {
      case PromotionDecision.promote:
        return 'Promote';
      case PromotionDecision.repeat:
        return 'Repeat Year';
      case PromotionDecision.graduate:
        return 'Graduate';
      case PromotionDecision.skip:
        return 'Skip (Manual)';
    }
  }

  Color get color {
    switch (this) {
      case PromotionDecision.promote:
        return Colors.green;
      case PromotionDecision.repeat:
        return Colors.orange;
      case PromotionDecision.graduate:
        return Colors.blue;
      case PromotionDecision.skip:
        return Colors.grey;
    }
  }

  static PromotionDecision fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'REPEAT':
        return PromotionDecision.repeat;
      case 'GRADUATE':
        return PromotionDecision.graduate;
      case 'SKIP':
        return PromotionDecision.skip;
      default:
        return PromotionDecision.promote;
    }
  }
}

// ── EnrollmentMappingModel ────────────────────────────────────────────────────

class EnrollmentMappingModel {
  const EnrollmentMappingModel({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.academicYearId,
    required this.standardId,
    this.sectionId,
    this.sectionName,
    this.rollNumber,
    required this.status,
    this.admissionType,
    this.joinedOn,
    this.leftOn,
    this.exitReason,
    this.studentName,
    this.admissionNumber,
    this.standardName,
    this.academicYearName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String academicYearId;
  final String standardId;
  final String? sectionId;
  final String? sectionName;
  final String? rollNumber;
  final EnrollmentStatus status;
  final AdmissionType? admissionType;
  final String? joinedOn;
  final String? leftOn;
  final String? exitReason;
  final String? studentName;
  final String? admissionNumber;
  final String? standardName;
  final String? academicYearName;
  final String createdAt;
  final String updatedAt;

  factory EnrollmentMappingModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentMappingModel(
      id: json['id'].toString(),
      studentId: json['student_id'].toString(),
      schoolId: json['school_id'].toString(),
      academicYearId: json['academic_year_id'].toString(),
      standardId: json['standard_id'].toString(),
      sectionId: json['section_id'] as String?,
      sectionName: json['section_name'] as String?,
      rollNumber: json['roll_number'] as String?,
      status: EnrollmentStatusX.fromString(json['status'] as String?),
      admissionType: AdmissionTypeX.fromString(json['admission_type'] as String?),
      joinedOn: json['joined_on'] as String?,
      leftOn: json['left_on'] as String?,
      exitReason: json['exit_reason'] as String?,
      studentName: json['student_name'] as String?,
      admissionNumber: json['admission_number'] as String?,
      standardName: json['standard_name'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}

// ── StudentAcademicHistoryModel ───────────────────────────────────────────────

class StudentAcademicHistoryModel {
  const StudentAcademicHistoryModel({
    required this.studentId,
    this.admissionNumber,
    this.studentName,
    required this.history,
  });

  final String studentId;
  final String? admissionNumber;
  final String? studentName;
  final List<EnrollmentMappingModel> history;

  factory StudentAcademicHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = (json['history'] as List?) ?? [];
    return StudentAcademicHistoryModel(
      studentId: json['student_id'].toString(),
      admissionNumber: json['admission_number'] as String?,
      studentName: json['student_name'] as String?,
      history: rawHistory
          .map((e) => EnrollmentMappingModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}

// ── PromotionPreviewItem ──────────────────────────────────────────────────────

class PromotionPreviewItem {
  PromotionPreviewItem({
    required this.studentId,
    required this.mappingId,
    this.admissionNumber,
    this.studentName,
    required this.currentStandardId,
    required this.currentStandardName,
    this.currentSectionName,
    required this.currentStatus,
    required this.suggestedDecision,
    this.suggestedNextStandardId,
    this.suggestedNextStandardName,
    this.hasWarning = false,
    this.warningMessage,
    // Mutable: admin can override
    PromotionDecision? overrideDecision,
    String? overrideStandardId,
    String? overrideSectionId,
  })  : _overrideDecision = overrideDecision,
        _overrideStandardId = overrideStandardId,
        _overrideSectionId = overrideSectionId;

  final String studentId;
  final String mappingId;
  final String? admissionNumber;
  final String? studentName;
  final String currentStandardId;
  final String currentStandardName;
  final String? currentSectionName;
  final EnrollmentStatus currentStatus;
  final PromotionDecision suggestedDecision;
  final String? suggestedNextStandardId;
  final String? suggestedNextStandardName;
  final bool hasWarning;
  final String? warningMessage;

  PromotionDecision? _overrideDecision;
  String? _overrideStandardId;
  String? _overrideSectionId;

  PromotionDecision get effectiveDecision =>
      _overrideDecision ?? suggestedDecision;
  String? get effectiveStandardId =>
      _overrideStandardId ?? suggestedNextStandardId;
  String? get effectiveSectionId => _overrideSectionId;

  void setOverride({
    PromotionDecision? decision,
    String? standardId,
    String? sectionId,
  }) {
    _overrideDecision = decision;
    _overrideStandardId = standardId;
    _overrideSectionId = sectionId;
  }

  factory PromotionPreviewItem.fromJson(Map<String, dynamic> json) {
    return PromotionPreviewItem(
      studentId: json['student_id'].toString(),
      mappingId: json['mapping_id'].toString(),
      admissionNumber: json['admission_number'] as String?,
      studentName: json['student_name'] as String?,
      currentStandardId: json['current_standard_id'].toString(),
      currentStandardName: json['current_standard_name'].toString(),
      currentSectionName: json['current_section_name'] as String?,
      currentStatus: EnrollmentStatusX.fromString(
          json['current_status'] as String?),
      suggestedDecision: PromotionDecisionX.fromString(
          json['suggested_decision'] as String?),
      suggestedNextStandardId:
          json['suggested_next_standard_id'] as String?,
      suggestedNextStandardName:
          json['suggested_next_standard_name'] as String?,
      hasWarning: json['has_warning'] as bool? ?? false,
      warningMessage: json['warning_message'] as String?,
    );
  }
}

// ── PromotionPreviewResponse ──────────────────────────────────────────────────

class PromotionPreviewResponse {
  const PromotionPreviewResponse({
    required this.sourceYearId,
    required this.sourceYearName,
    required this.targetYearId,
    required this.targetYearName,
    required this.totalStudents,
    required this.promotableCount,
    required this.warningCount,
    required this.items,
  });

  final String sourceYearId;
  final String sourceYearName;
  final String targetYearId;
  final String targetYearName;
  final int totalStudents;
  final int promotableCount;
  final int warningCount;
  final List<PromotionPreviewItem> items;

  factory PromotionPreviewResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? [];
    return PromotionPreviewResponse(
      sourceYearId: json['source_year_id'].toString(),
      sourceYearName: json['source_year_name'].toString(),
      targetYearId: json['target_year_id'].toString(),
      targetYearName: json['target_year_name'].toString(),
      totalStudents: json['total_students'] as int? ?? 0,
      promotableCount: json['promotable_count'] as int? ?? 0,
      warningCount: json['warning_count'] as int? ?? 0,
      items: rawItems
          .map((e) => PromotionPreviewItem.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
    );
  }
}