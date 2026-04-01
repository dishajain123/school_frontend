import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../common/widgets/app_avatar.dart';

class TeacherTile extends StatelessWidget {
  const TeacherTile({
    super.key,
    required this.teacher,
    required this.onTap,
    this.isLast = false,
  });

  final TeacherModel teacher;
  final VoidCallback onTap;
  final bool isLast;

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
              AppAvatar.md(
                imageUrl: teacher.profilePhotoUrl,
                name: teacher.displayName,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teacher.displayName,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyLight.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(
                            teacher.employeeCode,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.navyMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (teacher.specialization != null) ...[
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: Text(
                              teacher.specialization!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.grey600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: teacher.isActive
                          ? AppColors.successGreen
                          : AppColors.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}