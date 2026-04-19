import 'package:flutter/material.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class StudentAttendanceTile extends StatelessWidget {
  const StudentAttendanceTile({
    super.key,
    required this.studentId,
    this.studentName,
    required this.admissionNumber,
    this.rollNumber,
    this.section,
    required this.currentStatus,
    required this.onStatusChanged,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isLast = false,
  });

  final String studentId;
  final String? studentName;
  final String admissionNumber;
  final String? rollNumber;
  final String? section;
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onStatusChanged;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final resolvedName = (studentName ?? '').trim().isNotEmpty
        ? studentName!.trim()
        : 'Student $admissionNumber';
    final roll = rollNumber?.trim();
    final hasRoll = roll != null && roll.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _rowBackground,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onSelectionChanged(!isSelected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDeep : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface200,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 13, color: AppColors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                resolvedName.length >= 2
                    ? resolvedName.substring(0, 2).toUpperCase()
                    : resolvedName.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navyMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resolvedName,
                    style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(
                  hasRoll ? 'Roll $roll · $admissionNumber' : admissionNumber,
                  style: AppTypography.caption.copyWith(color: AppColors.grey500, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusToggleGroup(currentStatus: currentStatus, onChanged: onStatusChanged),
        ],
      ),
    );
  }

  Color get _rowBackground {
    switch (currentStatus) {
      case AttendanceStatus.present:
        return AppColors.successLight.withValues(alpha: 0.3);
      case AttendanceStatus.absent:
        return AppColors.errorLight.withValues(alpha: 0.25);
      case AttendanceStatus.late:
        return AppColors.warningLight.withValues(alpha: 0.25);
    }
  }
}

class _StatusToggleGroup extends StatelessWidget {
  const _StatusToggleGroup({required this.currentStatus, required this.onChanged});
  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusButton(
          label: 'P',
          isSelected: currentStatus == AttendanceStatus.present,
          selectedColor: AppColors.successGreen,
          selectedBg: AppColors.successLight,
          onTap: () => onChanged(AttendanceStatus.present),
        ),
        const SizedBox(width: 4),
        _StatusButton(
          label: 'A',
          isSelected: currentStatus == AttendanceStatus.absent,
          selectedColor: AppColors.errorRed,
          selectedBg: AppColors.errorLight,
          onTap: () => onChanged(AttendanceStatus.absent),
        ),
        const SizedBox(width: 4),
        _StatusButton(
          label: 'L',
          isSelected: currentStatus == AttendanceStatus.late,
          selectedColor: AppColors.warningAmber,
          selectedBg: AppColors.warningLight,
          onTap: () => onChanged(AttendanceStatus.late),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color selectedColor, selectedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : AppColors.surface50,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected ? selectedColor : AppColors.surface200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? selectedColor : AppColors.grey400,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}