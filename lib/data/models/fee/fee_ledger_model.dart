import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── FeeStatus ─────────────────────────────────────────────────────────────────
// Mirrors app/utils/enums.FeeStatus: PENDING | PARTIAL | PAID

enum FeeStatus {
  pending,
  partial,
  paid,
  overdue,
}

extension FeeStatusX on FeeStatus {
  static FeeStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'PAID':
        return FeeStatus.paid;
      case 'PARTIAL':
        return FeeStatus.partial;
      case 'OVERDUE':
        return FeeStatus.overdue;
      default:
        return FeeStatus.pending;
    }
  }

  String get backendValue {
    switch (this) {
      case FeeStatus.pending:
        return 'PENDING';
      case FeeStatus.partial:
        return 'PARTIAL';
      case FeeStatus.paid:
        return 'PAID';
      case FeeStatus.overdue:
        return 'OVERDUE';
    }
  }

  String get label {
    switch (this) {
      case FeeStatus.pending:
        return 'Pending';
      case FeeStatus.partial:
        return 'Partial';
      case FeeStatus.paid:
        return 'Paid';
      case FeeStatus.overdue:
        return 'Overdue';
    }
  }

  Color get color {
    switch (this) {
      case FeeStatus.pending:
        return AppColors.errorRed;
      case FeeStatus.partial:
        return AppColors.warningAmber;
      case FeeStatus.paid:
        return AppColors.successGreen;
      case FeeStatus.overdue:
        return AppColors.errorRed;
    }
  }

  Color get bgColor {
    switch (this) {
      case FeeStatus.pending:
        return AppColors.errorLight;
      case FeeStatus.partial:
        return AppColors.warningAmber.withValues(alpha: 0.12);
      case FeeStatus.paid:
        return AppColors.successLight;
      case FeeStatus.overdue:
        return AppColors.errorLight;
    }
  }

  IconData get icon {
    switch (this) {
      case FeeStatus.pending:
        return Icons.schedule_rounded;
      case FeeStatus.partial:
        return Icons.timelapse_rounded;
      case FeeStatus.paid:
        return Icons.check_circle_rounded;
      case FeeStatus.overdue:
        return Icons.warning_amber_rounded;
    }
  }
}

// ── FeeLedgerModel ────────────────────────────────────────────────────────────
// Mirrors FeeLedgerResponse from app/schemas/fee.py.
//
// NOTE: The backend FeeLedgerResponse does NOT expose fee_category or due_date.
// Those fields live on the related FeeStructure. If the backend schema is updated
// to include them (via a nested structure or extra fields), add them here.

class FeeLedgerModel {
  const FeeLedgerModel({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    this.installmentName,
    this.feeDescription,
    this.dueDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String feeStructureId;
  final String? installmentName;
  final String? feeDescription;
  final DateTime? dueDate;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount; // computed by service: total - paid, clamped ≥ 0
  final FeeStatus status;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 0.0 – 1.0 fraction of total that has been paid, clamped for safety.
  double get progressFraction =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isFullyPaid => status == FeeStatus.paid;
  bool get hasOutstanding => outstandingAmount > 0.01;
  bool get isOverdue {
    if (status == FeeStatus.overdue) return true;
    if (dueDate == null || !hasOutstanding || isFullyPaid) return false;
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day);
    return dueDate!.isBefore(cutoff);
  }

  // Backward-compatible UI helpers
  String get displayLabel =>
      (installmentName != null && installmentName!.trim().isNotEmpty)
          ? installmentName!.trim()
          : 'Installment';

  factory FeeLedgerModel.fromJson(Map<String, dynamic> json) {
    return FeeLedgerModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      feeStructureId: json['fee_structure_id'] as String,
      installmentName:
          (json['installment_name'] ?? json['fee_category']) as String?,
      feeDescription: json['fee_description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      // outstanding_amount is a computed field set by the service (not in DB).
      outstandingAmount:
          (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      status: FeeStatusX.fromString(json['status'] as String?),
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  FeeLedgerModel copyWith({
    double? paidAmount,
    double? outstandingAmount,
    FeeStatus? status,
  }) {
    return FeeLedgerModel(
      id: id,
      studentId: studentId,
      feeStructureId: feeStructureId,
      installmentName: installmentName,
      feeDescription: feeDescription,
      dueDate: dueDate,
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      status: status ?? this.status,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── FeeDashboardResult ────────────────────────────────────────────────────────
// Mirrors FeeDashboardResponse: { items: [...], total: int }

class FeeDashboardResult {
  const FeeDashboardResult({
    required this.items,
    required this.total,
  });

  final List<FeeLedgerModel> items;
  final int total;

  double get grandTotal => items.fold(0.0, (s, l) => s + l.totalAmount);
  double get grandPaid => items.fold(0.0, (s, l) => s + l.paidAmount);
  double get grandOutstanding => items.fold(0.0, (s, l) => s + l.outstandingAmount);
  bool get hasOverdue => items.any((item) => item.isOverdue);

  factory FeeDashboardResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return FeeDashboardResult(
      items: rawItems
          .map((e) => FeeLedgerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
