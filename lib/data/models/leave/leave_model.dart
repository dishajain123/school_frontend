import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

// ── LeaveType ─────────────────────────────────────────────────────────────────
// Mirrors app/utils/enums.LeaveType

enum LeaveType {
  casual,
  sick,
  earned,
  maternity,
  paternity,
  unpaid,
}

extension LeaveTypeX on LeaveType {
  static LeaveType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'CASUAL':
        return LeaveType.casual;
      case 'SICK':
        return LeaveType.sick;
      case 'EARNED':
        return LeaveType.earned;
      case 'MATERNITY':
        return LeaveType.maternity;
      case 'PATERNITY':
        return LeaveType.paternity;
      case 'UNPAID':
        return LeaveType.unpaid;
      default:
        return LeaveType.casual;
    }
  }

  String get backendValue {
    switch (this) {
      case LeaveType.casual:
        return 'CASUAL';
      case LeaveType.sick:
        return 'SICK';
      case LeaveType.earned:
        return 'EARNED';
      case LeaveType.maternity:
        return 'MATERNITY';
      case LeaveType.paternity:
        return 'PATERNITY';
      case LeaveType.unpaid:
        return 'UNPAID';
    }
  }

  String get label {
    switch (this) {
      case LeaveType.casual:
        return 'Casual Leave';
      case LeaveType.sick:
        return 'Sick Leave';
      case LeaveType.earned:
        return 'Earned Leave';
      case LeaveType.maternity:
        return 'Maternity Leave';
      case LeaveType.paternity:
        return 'Paternity Leave';
      case LeaveType.unpaid:
        return 'Unpaid Leave';
    }
  }

  String get shortLabel {
    switch (this) {
      case LeaveType.casual:
        return 'Casual';
      case LeaveType.sick:
        return 'Sick';
      case LeaveType.earned:
        return 'Earned';
      case LeaveType.maternity:
        return 'Maternity';
      case LeaveType.paternity:
        return 'Paternity';
      case LeaveType.unpaid:
        return 'Unpaid';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveType.casual:
        return Icons.beach_access_outlined;
      case LeaveType.sick:
        return Icons.local_hospital_outlined;
      case LeaveType.earned:
        return Icons.star_outline_rounded;
      case LeaveType.maternity:
        return Icons.child_care_outlined;
      case LeaveType.paternity:
        return Icons.family_restroom_outlined;
      case LeaveType.unpaid:
        return Icons.money_off_outlined;
    }
  }

  Color get color {
    switch (this) {
      case LeaveType.casual:
        return AppColors.infoBlue;
      case LeaveType.sick:
        return AppColors.errorRed;
      case LeaveType.earned:
        return AppColors.goldPrimary;
      case LeaveType.maternity:
        return AppColors.subjectHindi;
      case LeaveType.paternity:
        return AppColors.subjectMath;
      case LeaveType.unpaid:
        return AppColors.grey600;
    }
  }
}

// ── LeaveStatus ───────────────────────────────────────────────────────────────
// Mirrors app/utils/enums.LeaveStatus

enum LeaveStatus {
  pending,
  approved,
  rejected,
}

extension LeaveStatusX on LeaveStatus {
  static LeaveStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'APPROVED':
        return LeaveStatus.approved;
      case 'REJECTED':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case LeaveStatus.pending:
        return 'PENDING';
      case LeaveStatus.approved:
        return 'APPROVED';
      case LeaveStatus.rejected:
        return 'REJECTED';
    }
  }

  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  Color get color {
    switch (this) {
      case LeaveStatus.pending:
        return AppColors.warningAmber;
      case LeaveStatus.approved:
        return AppColors.successGreen;
      case LeaveStatus.rejected:
        return AppColors.errorRed;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LeaveStatus.pending:
        return AppColors.warningLight;
      case LeaveStatus.approved:
        return AppColors.successLight;
      case LeaveStatus.rejected:
        return AppColors.errorLight;
    }
  }

  IconData get icon {
    switch (this) {
      case LeaveStatus.pending:
        return Icons.hourglass_empty_rounded;
      case LeaveStatus.approved:
        return Icons.check_circle_outline_rounded;
      case LeaveStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}

// ── LeaveModel ────────────────────────────────────────────────────────────────
// Mirrors LeaveResponse from app/schemas/leave.py

class LeaveModel {
  const LeaveModel({
    required this.id,
    required this.teacherId,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.status,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.reason,
    this.approvedBy,
    this.remarks,
  });

  final String id;
  final String teacherId;
  final LeaveType leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final String? reason;
  final LeaveStatus status;
  final String? approvedBy;
  final String? remarks;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Number of calendar days including both from and to dates
  int get daysCount => toDate.difference(fromDate).inDays + 1;

  bool get isPending => status == LeaveStatus.pending;
  bool get isApproved => status == LeaveStatus.approved;
  bool get isRejected => status == LeaveStatus.rejected;

  factory LeaveModel.fromJson(Map<String, dynamic> json) {
    return LeaveModel(
      id: json['id'] as String,
      teacherId: json['teacher_id'] as String,
      leaveType: LeaveTypeX.fromString(json['leave_type'] as String?),
      fromDate: DateTime.parse(json['from_date'] as String),
      toDate: DateTime.parse(json['to_date'] as String),
      reason: json['reason'] as String?,
      status: LeaveStatusX.fromString(json['status'] as String?),
      approvedBy: json['approved_by'] as String?,
      remarks: json['remarks'] as String?,
      academicYearId: json['academic_year_id'] as String,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  LeaveModel copyWith({
    LeaveStatus? status,
    String? approvedBy,
    String? remarks,
  }) {
    return LeaveModel(
      id: id,
      teacherId: teacherId,
      leaveType: leaveType,
      fromDate: fromDate,
      toDate: toDate,
      reason: reason,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      remarks: remarks ?? this.remarks,
      academicYearId: academicYearId,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LeaveModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ── LeaveListResponse ─────────────────────────────────────────────────────────
// Mirrors LeaveListResponse from app/schemas/leave.py

class LeaveListResponse {
  const LeaveListResponse({
    required this.items,
    required this.total,
  });

  final List<LeaveModel> items;
  final int total;

  factory LeaveListResponse.fromJson(Map<String, dynamic> json) {
    return LeaveListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => LeaveModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}