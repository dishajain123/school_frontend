import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/assignment/submission_model.dart';
import '../../common/widgets/app_avatar.dart';

class SubmissionTile extends StatelessWidget {
  final SubmissionModel submission;
  final String studentName;
  final String? standardName;
  final String? subjectName;
  final String? section;
  final VoidCallback? onGrade;
  final VoidCallback? onViewFile;
  final bool isLast;

  const SubmissionTile({
    super.key,
    required this.submission,
    required this.studentName,
    this.standardName,
    this.subjectName,
    this.section,
    this.onGrade,
    this.onViewFile,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: studentName, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        studentName,
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (submission.isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Late',
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.errorRed, fontWeight: FontWeight.w700, fontSize: 10)),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'Submitted ${DateFormatter.formatRelative(submission.submittedAt)}',
                  style: AppTypography.caption.copyWith(color: AppColors.grey400, fontSize: 11),
                ),
                if (standardName != null || subjectName != null || section != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (standardName != null) standardName!,
                      if (section != null && section!.isNotEmpty) 'Sec $section',
                      if (subjectName != null) subjectName!,
                    ].join(' · '),
                    style: AppTypography.caption.copyWith(color: AppColors.grey500, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    if (submission.isApproved)
                      _Badge(label: 'Approved', color: AppColors.successGreen,
                          bg: AppColors.successLight, icon: Icons.verified_rounded),
                    if (submission.isGraded && submission.grade != null)
                      _Badge(label: 'Grade: ${submission.grade}',
                          color: AppColors.successGreen, bg: AppColors.successLight),
                    if (submission.fileKey != null)
                      GestureDetector(
                        onTap: onViewFile,
                        child: const _Badge(label: 'File attached',
                            color: AppColors.infoBlue, bg: AppColors.infoLight,
                            icon: Icons.attach_file_rounded),
                      ),
                    if (submission.feedback != null && submission.feedback!.trim().isNotEmpty)
                      const _Badge(label: 'Feedback', color: AppColors.warningAmber,
                          bg: AppColors.warningLight, icon: Icons.comment_outlined),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (onGrade != null)
            _GradeButton(
              onTap: onGrade!,
              label: submission.isGraded || submission.isApproved ? 'Review' : 'Grade',
            )
          else if (submission.isGraded)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.successGreen, size: 16),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  const _Badge({required this.label, required this.color, required this.bg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: color, fontWeight: FontWeight.w600, fontSize: 10)),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({required this.onTap, this.label = 'Grade'});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.navyDeep,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    );
  }
}