import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class SubjectStatRow extends StatelessWidget {
  const SubjectStatRow({
    super.key,
    required this.subjectName,
    required this.subjectCode,
    required this.percentage,
    required this.present,
    required this.total,
    this.isLast = false,
  });

  final String subjectName;
  final String subjectCode;
  final double percentage;
  final int present;
  final int total;
  final bool isLast;

  Color get _barColor {
    if (percentage >= 85) return AppColors.successGreen;
    if (percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  Color get _percentageColor {
    if (percentage >= 85) return AppColors.successGreen;
    if (percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject name + code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subjectName,
                        style: AppTypography.titleSmall,
                        overflow: TextOverflow.ellipsis),
                    Text(subjectCode,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey400)),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              // Attendance count
              Text(
                '$present / $total',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.grey600),
              ),
              const SizedBox(width: AppDimensions.space8),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space8,
                    vertical: AppDimensions.space4),
                decoration: BoxDecoration(
                  color: _barColor.withOpacity(0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.labelSmall.copyWith(
                    color: _percentageColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: AppColors.surface100,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}