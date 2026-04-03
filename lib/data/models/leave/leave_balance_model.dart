import 'package:flutter/material.dart';
import 'leave_model.dart';
import '../../../../core/theme/app_colors.dart';

// ── LeaveBalanceModel ─────────────────────────────────────────────────────────
// Mirrors LeaveBalanceResponse from app/schemas/leave.py

class LeaveBalanceModel {
  const LeaveBalanceModel({
    required this.leaveType,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
  });

  final LeaveType leaveType;
  final double totalDays;
  final double usedDays;
  final double remainingDays;

  /// 0.0 – 1.0 fraction of total days used, clamped for safety.
  double get usedFraction =>
      totalDays > 0 ? (usedDays / totalDays).clamp(0.0, 1.0) : 0.0;

  /// 0.0 – 1.0 fraction of total days remaining.
  double get remainingFraction =>
      totalDays > 0 ? (remainingDays / totalDays).clamp(0.0, 1.0) : 0.0;

  bool get isExhausted => remainingDays <= 0;

  Color get progressColor {
    if (usedFraction >= 1.0) return AppColors.errorRed;
    if (usedFraction >= 0.75) return AppColors.warningAmber;
    return AppColors.successGreen;
  }

  factory LeaveBalanceModel.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceModel(
      leaveType: LeaveTypeX.fromString(json['leave_type'] as String?),
      totalDays: (json['total_days'] as num).toDouble(),
      usedDays: (json['used_days'] as num).toDouble(),
      remainingDays: (json['remaining_days'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaveBalanceModel && leaveType == other.leaveType;

  @override
  int get hashCode => leaveType.hashCode;
}