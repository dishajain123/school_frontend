import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/parent/child_summary.dart';

class ChildCard extends StatelessWidget {
  const ChildCard({
    super.key,
    required this.child,
    this.standardName,
    this.onTap,
  });

  final ChildSummaryModel child;
  final String? standardName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.surface200,
            width: AppDimensions.borderThin,
          ),
          boxShadow: AppDecorations.shadow1,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.avatarBackground(child.admissionNumber),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  child.initials,
                  style: AppTypography.titleMedium.copyWith(
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
                    child.admissionNumber,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Wrap(
                    spacing: AppDimensions.space6,
                    children: [
                      if (standardName != null)
                        _InfoChip(
                          label: standardName!,
                          color: AppColors.infoBlue,
                        ),
                      if (child.section != null)
                        _InfoChip(
                          label: 'Sec ${child.section}',
                          color: AppColors.navyMedium,
                        ),
                      if (child.rollNumber != null)
                        _InfoChip(
                          label: 'Roll ${child.rollNumber}',
                          color: AppColors.grey600,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.grey400,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}