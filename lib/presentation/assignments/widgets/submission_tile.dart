import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/assignment/submission_model.dart';
import '../../common/widgets/app_avatar.dart';

class SubmissionTile extends StatelessWidget {
  final SubmissionModel submission;

  /// Display name for the student (fetched externally)
  final String studentName;
  final VoidCallback? onGrade;
  final VoidCallback? onViewFile;
  final bool isLast;

  const SubmissionTile({
    super.key,
    required this.submission,
    required this.studentName,
    this.onGrade,
    this.onViewFile,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            AppAvatar(name: studentName, size: 40),
            const SizedBox(width: AppDimensions.space12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          studentName,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.grey800,
                          ),
                        ),
                      ),
                      if (submission.isLate)
                        _Badge(
                            label: 'Late',
                            color: AppColors.errorRed,
                            bg: AppColors.errorLight),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Submitted ${DateFormatter.formatRelative(submission.submittedAt)}',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.grey400),
                  ),
                  const SizedBox(height: AppDimensions.space6),
                  Row(
                    children: [
                      if (submission.isApproved) ...[
                        _Badge(
                          label: 'Approved',
                          color: AppColors.successGreen,
                          bg: AppColors.successLight,
                          icon: Icons.verified_rounded,
                        ),
                        const SizedBox(width: AppDimensions.space6),
                      ],
                      if (submission.isGraded && submission.grade != null) ...[
                        _Badge(
                          label: 'Grade: ${submission.grade}',
                          color: AppColors.successGreen,
                          bg: AppColors.successLight,
                        ),
                        const SizedBox(width: AppDimensions.space6),
                      ],
                      if (submission.fileKey != null)
                        GestureDetector(
                          onTap: onViewFile,
                          child: _Badge(
                            label: 'File attached',
                            color: AppColors.infoBlue,
                            bg: AppColors.infoLight,
                            icon: Icons.attach_file,
                          ),
                        ),
                      if (submission.feedback != null &&
                          submission.feedback!.trim().isNotEmpty) ...[
                        const SizedBox(width: AppDimensions.space6),
                        _Badge(
                          label: 'Feedback',
                          color: AppColors.warningAmber,
                          bg: AppColors.warningLight,
                          icon: Icons.comment_bank_outlined,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppDimensions.space8),

            // Grade button
            if (onGrade != null)
              _GradeButton(
                onTap: onGrade!,
                label: submission.isGraded || submission.isApproved
                    ? 'Review'
                    : 'Grade',
              )
            else if (submission.isGraded)
              Icon(Icons.check_circle, color: AppColors.successGreen, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _Badge(
      {required this.label,
      required this.color,
      required this.bg,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.labelMedium
                .copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _GradeButton({required this.onTap, this.label = 'Grade'});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12, vertical: AppDimensions.space6),
        decoration: BoxDecoration(
          color: AppColors.navyDeep,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
