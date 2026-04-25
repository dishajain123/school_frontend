import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

// ── FeeStatus ─────────────────────────────────────────────────────────────────

enum FeeStatus { pending, partial, paid, overdue }

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
        return AppColors.grey500;
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
        return AppColors.surface100;
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

class FeeLedgerModel {
  const FeeLedgerModel({
    required this.id,
    required this.studentId,
    required this.feeStructureId,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.installmentName,
    this.feeCategory,
    this.customFeeHead,
    this.dueDate,
    this.feeDescription,
    this.lastPaymentDate,
  });

  final String id;
  final String studentId;
  final String feeStructureId;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final FeeStatus status;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Installment-specific fields (new)
  final String? installmentName;
  final String? feeCategory;
  final String? customFeeHead;
  final DateTime? dueDate;
  final String? feeDescription;
  final DateTime? lastPaymentDate;

  double get progressFraction =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  bool get isFullyPaid => status == FeeStatus.paid;
  bool get hasOutstanding => outstandingAmount > 0.01;
  bool get isOverdue => status == FeeStatus.overdue;

  /// Display label: installment name > custom_fee_head > fee_category > "Fee Entry"
  String get displayLabel {
    if (installmentName != null && installmentName!.trim().isNotEmpty) {
      return installmentName!.trim();
    }
    if (customFeeHead != null && customFeeHead!.trim().isNotEmpty) {
      return customFeeHead!.trim();
    }
    if (feeCategory != null && feeCategory!.isNotEmpty) {
      final c = feeCategory!;
      return c[0].toUpperCase() + c.substring(1).toLowerCase();
    }
    return 'Fee Entry';
  }

  factory FeeLedgerModel.fromJson(Map<String, dynamic> json) {
    final instName = json['installment_name'] as String?;
    return FeeLedgerModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      feeStructureId: json['fee_structure_id'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      paidAmount: (json['paid_amount'] as num).toDouble(),
      outstandingAmount: (json['outstanding_amount'] as num?)?.toDouble() ?? 0.0,
      status: FeeStatusX.fromString(json['status'] as String?),
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      installmentName:
          (instName == null || instName.isEmpty) ? null : instName,
      feeCategory: json['fee_category'] as String?,
      customFeeHead: json['custom_fee_head'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      feeDescription: json['fee_description'] as String?,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.tryParse(json['last_payment_date'] as String)
          : null,
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
      totalAmount: totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
      status: status ?? this.status,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      installmentName: installmentName,
      feeCategory: feeCategory,
      customFeeHead: customFeeHead,
      dueDate: dueDate,
      feeDescription: feeDescription,
      lastPaymentDate: lastPaymentDate,
    );
  }
}

// ── FeeDashboardResult ────────────────────────────────────────────────────────

class FeeDashboardResult {
  const FeeDashboardResult({
    required this.items,
    required this.total,
    this.totalBilled = 0.0,
    this.totalPaid = 0.0,
    this.totalOutstanding = 0.0,
    this.hasOverdue = false,
  });

  final List<FeeLedgerModel> items;
  final int total;
  final double totalBilled;
  final double totalPaid;
  final double totalOutstanding;
  final bool hasOverdue;

  double get grandTotal =>
      totalBilled > 0 ? totalBilled : items.fold(0.0, (s, l) => s + l.totalAmount);
  double get grandPaid =>
      totalPaid > 0 ? totalPaid : items.fold(0.0, (s, l) => s + l.paidAmount);
  double get grandOutstanding =>
      totalOutstanding > 0
          ? totalOutstanding
          : items.fold(0.0, (s, l) => s + l.outstandingAmount);

  factory FeeDashboardResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return FeeDashboardResult(
      items: rawItems
          .map((e) => FeeLedgerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      totalBilled: (json['total_billed'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalOutstanding: (json['total_outstanding'] as num?)?.toDouble() ?? 0.0,
      hasOverdue: json['has_overdue'] as bool? ?? false,
    );
  }
}