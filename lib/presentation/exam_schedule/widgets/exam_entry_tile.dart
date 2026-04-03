import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_entry_model.dart';

class ExamEntryTile extends StatelessWidget {
  const ExamEntryTile({
    super.key,
    required this.entry,
    required this.subjectName,
    this.onCancel,
    this.canCancel = false,
    this.isLast = false,
  });

  final ExamEntryModel entry;
  final String subjectName;
  final VoidCallback? onCancel;
  final bool canCancel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isCancelled = entry.isCancelled;
    final dateLabel = DateFormat('EEE, dd MMM yyyy').format(entry.examDate);

    return Opacity(
      opacity: isCancelled ? 0.55 : 1.0,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : AppDimensions.space8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: isCancelled
                ? AppColors.errorRed.withOpacity(0.3)
                : AppColors.surface200.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject color dot + date column
              _DateColumn(date: entry.examDate),
              const SizedBox(width: AppDimensions.space12),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subjectName,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isCancelled
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCancelled
                                  ? AppColors.grey600
                                  : AppColors.grey800,
                            ),
                          ),
                        ),
                        if (isCancelled)
                          _CancelledBadge()
                        else if (canCancel)
                          _CancelButton(onCancel: onCancel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey600,
                        decoration:
                            isCancelled ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Wrap(
                      spacing: AppDimensions.space8,
                      children: [
                        _InfoChip(
                          icon: Icons.access_time_outlined,
                          label:
                              '${entry.formattedStartTime} – ${entry.formattedEndTime}',
                        ),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: entry.durationLabel,
                        ),
                        if (entry.venue != null && entry.venue!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: entry.venue!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateColumn extends StatelessWidget {
  const _DateColumn({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('dd').format(date),
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            DateFormat('EEE').format(date),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.grey600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.grey600),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.grey600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withOpacity(0.8),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.4)),
      ),
      child: Text(
        'Cancelled',
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.errorRed,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({this.onCancel});
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCancel,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.errorLight.withOpacity(0.8),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child:
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.errorRed),
      ),
    );
  }
}
