import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/result/result_model.dart';
import 'grade_badge.dart';

/// A single subject row in the result list / report card.
class ResultSubjectTile extends StatelessWidget {
  const ResultSubjectTile({
    super.key,
    required this.entry,
    required this.subjectName,
    this.subjectCode,
    this.isLast = false,
    this.showPublishedBadge = false,
  });

  final ResultEntryModel entry;
  final String subjectName;
  final String? subjectCode;
  final bool isLast;
  final bool showPublishedBadge;

  Color get _barColor {
    if (entry.percentage >= 75) return AppColors.successGreen;
    if (entry.percentage >= 50) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1),
              ),
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
                    Text(
                      subjectName,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subjectCode != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subjectCode!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey400),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              // Marks fraction
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: entry.marksObtained
                              .toStringAsFixed(
                                  entry.marksObtained % 1 == 0 ? 0 : 1),
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${entry.maxMarks.toStringAsFixed(entry.maxMarks % 1 == 0 ? 0 : 1)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (showPublishedBadge && entry.isPublished) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull),
                          ),
                          child: Text(
                            'Published',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.successGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space4),
                      ],
                      GradeBadge.small(
                        percentage: entry.percentage,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: (entry.percentage / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surface100,
              valueColor: AlwaysStoppedAnimation<Color>(_barColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${entry.percentage.toStringAsFixed(1)}%',
            style: AppTypography.caption.copyWith(
              color: _barColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}