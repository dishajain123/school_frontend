import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_series_model.dart';

class SeriesHeader extends StatelessWidget {
  const SeriesHeader({
    super.key,
    required this.series,
    required this.entryCount,
    this.onPublish,
    this.canPublish = false,
  });

  final ExamSeriesModel series;
  final int entryCount;
  final VoidCallback? onPublish;
  final bool canPublish;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyDeep,
            AppColors.navyDeep.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  series.name,
                  style: AppTypography.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PublishedBadge(isPublished: series.isPublished),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              const Icon(Icons.library_books_outlined,
                  color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                '$entryCount ${entryCount == 1 ? 'subject' : 'subjects'}',
                style: AppTypography.bodySmall.copyWith(color: Colors.white70),
              ),
              if (canPublish && !series.isPublished) ...[
                const Spacer(),
                _PublishButton(onPublish: onPublish),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PublishedBadge extends StatelessWidget {
  const _PublishedBadge({required this.isPublished});
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublished
            ? AppColors.successGreen.withOpacity(0.2)
            : AppColors.warningAmber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isPublished ? AppColors.successGreen : AppColors.warningAmber,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.check_circle_outline : Icons.edit_outlined,
            size: 12,
            color: isPublished ? AppColors.successGreen : AppColors.warningAmber,
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: AppTypography.labelSmall.copyWith(
              color:
                  isPublished ? AppColors.successGreen : AppColors.warningAmber,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({this.onPublish});
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPublish,
      icon: const Icon(Icons.publish_outlined,
          size: 16, color: AppColors.goldPrimary),
      label: Text(
        'Publish',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: AppColors.goldPrimary.withOpacity(0.15),
        padding:
            const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
    );
  }
}
