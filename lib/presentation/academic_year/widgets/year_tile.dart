import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/academic_year/academic_year_model.dart';

class YearTile extends StatelessWidget {
  const YearTile({
    super.key,
    required this.year,
    required this.canManage,
    required this.onActivate,
    required this.onEdit,
  });

  final AcademicYearModel year;
  final bool canManage;
  final VoidCallback onActivate;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: year.isActive
              ? AppColors.goldPrimary.withValues(alpha: 0.5)
              : AppColors.surface200,
          width: year.isActive
              ? AppDimensions.borderThick
              : AppDimensions.borderThin,
        ),
        boxShadow: year.isActive
            ? [
                BoxShadow(
                  color: AppColors.goldPrimary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: year.isActive
                    ? AppColors.goldLight
                    : AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: year.isActive
                    ? AppColors.goldDark
                    : AppColors.grey400,
                size: AppDimensions.iconSM,
              ),
            ),

            const SizedBox(width: AppDimensions.space12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        year.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (year.isActive) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                            border: Border.all(
                              color: AppColors.goldPrimary
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            'Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    '${DateFormatter.formatDate(year.startDate)} – ${DateFormatter.formatDate(year.endDate)}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),

            // Actions
            if (canManage)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!year.isActive)
                    _ActionButton(
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.successGreen,
                      tooltip: 'Set Active',
                      onTap: onActivate,
                    ),
                  const SizedBox(width: AppDimensions.space4),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    color: AppColors.navyMedium,
                    tooltip: 'Edit',
                    onTap: onEdit,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon,
              size: AppDimensions.iconSM, color: color),
        ),
      ),
    );
  }
}