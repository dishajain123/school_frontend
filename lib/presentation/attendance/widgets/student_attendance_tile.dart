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

    return Container(
      decoration: BoxDecoration(
        color: _rowBackground,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.navyMedium,
            onChanged: (value) => onSelectionChanged(value ?? false),
          ),
          const SizedBox(width: AppDimensions.space4),
          // Student avatar / initials
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Center(
              child: Text(
                resolvedName.length >= 2
                    ? resolvedName.substring(0, 2).toUpperCase()
                    : resolvedName.toUpperCase(),
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navyMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          // Student info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resolvedName,
                    style: AppTypography.titleSmall,
                    overflow: TextOverflow.ellipsis),
                Text(
                  hasRoll ? 'Roll $roll • $admissionNumber' : admissionNumber,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey600),
                ),
                if (section != null && section!.isNotEmpty)
                  Text('Section $section',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey400)),
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          // Status toggle buttons
          _StatusToggleGroup(
            currentStatus: currentStatus,
            onChanged: onStatusChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusToggleGroup extends StatelessWidget {
  const _StatusToggleGroup({
    required this.currentStatus,
    required this.onChanged,
  });

  final AttendanceStatus currentStatus;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusButton(
          label: 'P',
          status: AttendanceStatus.present,
          isSelected: currentStatus == AttendanceStatus.present,
          selectedColor: AppColors.successGreen,
          selectedBg: AppColors.successLight,
          onTap: () => onChanged(AttendanceStatus.present),
        ),
        const SizedBox(width: AppDimensions.space4),
        _StatusButton(
          label: 'A',
          status: AttendanceStatus.absent,
          isSelected: currentStatus == AttendanceStatus.absent,
          selectedColor: AppColors.errorRed,
          selectedBg: AppColors.errorLight,
          onTap: () => onChanged(AttendanceStatus.absent),
        ),
      ],
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.status,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  final String label;
  final AttendanceStatus status;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

extension on StudentAttendanceTile {
  Color get _rowBackground {
    switch (currentStatus) {
      case AttendanceStatus.present:
        return AppColors.successLight.withValues(alpha: 0.25);
      case AttendanceStatus.absent:
        return AppColors.errorLight.withValues(alpha: 0.22);
      case AttendanceStatus.late:
        return AppColors.warningLight.withValues(alpha: 0.2);
    }
  }
}
