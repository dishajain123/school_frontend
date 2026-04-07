import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/student/student_model.dart';

class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.student,
    required this.onTap,
    this.standardName,
    this.isLast = false,
    this.showSelection = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final StudentModel student;
  final VoidCallback onTap;
  final String? standardName;
  final bool isLast;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        splashColor: AppColors.navyLight.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Row(
            children: [
              // Avatar with initials
              Container(
                width: AppDimensions.avatarMd,
                height: AppDimensions.avatarMd,
                decoration: BoxDecoration(
                  color: AppColors.avatarBackground(student.admissionNumber),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    student.initials,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.admissionNumber,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Row(
                      children: [
                        if (standardName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                            ),
                            child: Text(
                              standardName!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.infoBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        if (student.section != null) ...[
                          const SizedBox(width: AppDimensions.space4),
                          Text(
                            '· Sec ${student.section}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                        if (student.rollNumber != null) ...[
                          const SizedBox(width: AppDimensions.space4),
                          Text(
                            '· Roll ${student.rollNumber}',
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (student.isPromoted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    'Promoted',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(width: AppDimensions.space8),
              if (showSelection)
                Checkbox(
                  value: isSelected,
                  onChanged: (v) => onSelectionChanged?.call(v ?? false),
                  activeColor: AppColors.navyDeep,
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.grey400,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
