import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/assignment/assignment_model.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String? subjectName;
  final String? standardName;
  final VoidCallback? onTap;
  final VoidCallback? onViewSubmissions;
  final bool showSubmissionAction;

  /// Optional: the student's submission status for this card
  final _SubmissionStatus? submissionStatus;

  const AssignmentCard({
    super.key,
    required this.assignment,
    this.subjectName,
    this.standardName,
    this.onTap,
    this.onViewSubmissions,
    this.showSubmissionAction = false,
    this.submissionStatus,
  });

  @override
  Widget build(BuildContext context) {
    final subjectColor = _subjectColor(subjectName);
    final statusInfo = _resolveStatus();

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space6),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Subject color stripe
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppDimensions.radiusMedium),
                        bottomLeft: Radius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: title + status chip
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  assignment.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.grey800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              _StatusChip(info: statusInfo),
                            ],
                          ),

                          const SizedBox(height: AppDimensions.space6),

                          // Subject + standard row
                          Row(
                            children: [
                              Icon(Icons.book_outlined,
                                  size: 13, color: AppColors.grey400),
                              const SizedBox(width: 4),
                              Text(
                                subjectName ?? '—',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.grey600),
                              ),
                              if (standardName != null) ...[
                                const SizedBox(width: AppDimensions.space8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: const BoxDecoration(
                                    color: AppColors.grey400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.space8),
                                Text(
                                  standardName!,
                                  style: AppTypography.bodySmall
                                      .copyWith(color: AppColors.grey600),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: AppDimensions.space12),

                          // Due date row
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 13,
                                color: assignment.isOverdue
                                    ? AppColors.errorRed
                                    : AppColors.grey400,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Due ${DateFormatter.formatDate(assignment.dueDate)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: assignment.isOverdue
                                      ? AppColors.errorRed
                                      : AppColors.grey600,
                                  fontWeight: assignment.isOverdue
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                              ),
                              if (assignment.isDueToday) ...[
                                const SizedBox(width: AppDimensions.space6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: AppColors.warningAmber,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (assignment.fileKey != null)
                                Icon(Icons.attach_file,
                                    size: 14, color: AppColors.grey400),
                            ],
                          ),
                          if (showSubmissionAction &&
                              onViewSubmissions != null) ...[
                            const SizedBox(height: AppDimensions.space12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: onViewSubmissions,
                                icon: const Icon(Icons.fact_check_outlined,
                                    size: 16),
                                label: const Text('View Submissions'),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  side: const BorderSide(
                                      color: AppColors.navyLight),
                                  foregroundColor: AppColors.navyDeep,
                                  textStyle: AppTypography.labelMedium,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _StatusInfo _resolveStatus() {
    if (submissionStatus != null) {
      switch (submissionStatus!) {
        case _SubmissionStatus.graded:
          return _StatusInfo('Graded', AppColors.successGreen,
              AppColors.successLight, Icons.check_circle_outline);
        case _SubmissionStatus.submitted:
          return _StatusInfo('Submitted', AppColors.infoBlue,
              AppColors.infoLight, Icons.upload_outlined);
        case _SubmissionStatus.pending:
          return _resolveDefaultStatus();
      }
    }
    return _resolveDefaultStatus();
  }

  _StatusInfo _resolveDefaultStatus() {
    if (!assignment.isActive) {
      return _StatusInfo('Closed', AppColors.grey400, AppColors.surface100,
          Icons.lock_outline);
    }
    if (assignment.isOverdue) {
      return _StatusInfo('Overdue', AppColors.errorRed, AppColors.errorLight,
          Icons.warning_amber_outlined);
    }
    return _StatusInfo(
        'Active', AppColors.successGreen, AppColors.successLight, null);
  }

  static Color _subjectColor(String? subject) {
    if (subject == null) return AppColors.subjectDefault;
    final lower = subject.toLowerCase();
    if (lower.contains('math')) return AppColors.subjectMath;
    if (lower.contains('science') || lower.contains('bio'))
      return AppColors.subjectScience;
    if (lower.contains('english')) return AppColors.subjectEnglish;
    if (lower.contains('hindi')) return AppColors.subjectHindi;
    if (lower.contains('history') || lower.contains('social'))
      return AppColors.subjectHistory;
    if (lower.contains('physics')) return AppColors.subjectPhysics;
    if (lower.contains('chem')) return AppColors.subjectChem;
    return AppColors.subjectDefault;
  }
}

enum _SubmissionStatus { graded, submitted, pending }

class _StatusInfo {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _StatusInfo(this.label, this.color, this.bg, this.icon);
}

class _StatusChip extends StatelessWidget {
  final _StatusInfo info;
  const _StatusChip({required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: info.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (info.icon != null) ...[
            Icon(info.icon, size: 11, color: info.color),
            const SizedBox(width: 3),
          ],
          Text(
            info.label,
            style: AppTypography.labelMedium.copyWith(
              color: info.color,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

extension _AppColorsAssignment on AppColors {
  static const Color subjectMath = Color(0xFF6366F1);
  static const Color subjectScience = Color(0xFF10B981);
  static const Color subjectEnglish = Color(0xFF3B82F6);
  static const Color subjectHindi = Color(0xFFEC4899);
  static const Color subjectHistory = Color(0xFFF97316);
  static const Color subjectPhysics = Color(0xFF8B5CF6);
  static const Color subjectChem = Color(0xFF14B8A6);
  static const Color subjectDefault = Color(0xFF64748B);
}
