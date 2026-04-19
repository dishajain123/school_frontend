import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/assignment/assignment_model.dart';

class AssignmentCard extends StatefulWidget {
  final AssignmentModel assignment;
  final String? subjectName;
  final String? standardName;
  final VoidCallback? onTap;
  final VoidCallback? onViewSubmissions;
  final bool showSubmissionAction;
  final SubmissionStatus? submissionStatus;

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
  State<AssignmentCard> createState() => _AssignmentCardState();
}

class _AssignmentCardState extends State<AssignmentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.985)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjectColor = _subjectColor(widget.subjectName);
    final statusInfo = _resolveStatus();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap?.call(); },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.assignment.title,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: AppColors.grey800,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(info: statusInfo),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: subjectColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.subjectName ?? '—',
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.grey500, fontSize: 12),
                              ),
                              if (widget.standardName != null) ...[
                                const SizedBox(width: 6),
                                Text('·', style: AppTypography.caption.copyWith(color: AppColors.grey400)),
                                const SizedBox(width: 6),
                                Text(widget.standardName!,
                                    style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.grey500, fontSize: 12)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 12,
                                color: widget.assignment.isOverdue
                                    ? AppColors.errorRed
                                    : AppColors.grey400,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Due ${DateFormatter.formatDate(widget.assignment.dueDate)}',
                                style: AppTypography.caption.copyWith(
                                  color: widget.assignment.isOverdue
                                      ? AppColors.errorRed
                                      : AppColors.grey500,
                                  fontWeight: widget.assignment.isOverdue
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (widget.assignment.isDueToday) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.warningLight,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('TODAY',
                                      style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.warningAmber,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                              const Spacer(),
                              if (widget.assignment.fileKey != null)
                                const Icon(
                                  Icons.attach_file_rounded,
                                  size: 13,
                                  color: AppColors.grey400,
                                ),
                            ],
                          ),
                          if (widget.showSubmissionAction && widget.onViewSubmissions != null) ...[
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: widget.onViewSubmissions,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.navyDeep.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.fact_check_outlined,
                                        size: 13, color: AppColors.navyMedium),
                                    const SizedBox(width: 5),
                                    Text('View Submissions',
                                        style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.navyMedium,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11)),
                                  ],
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
    if (widget.submissionStatus != null) {
      switch (widget.submissionStatus!) {
        case SubmissionStatus.graded:
          return const _StatusInfo(
            'Graded',
            AppColors.successGreen,
            AppColors.successLight,
            Icons.check_circle_outline,
          );
        case SubmissionStatus.submitted:
          return const _StatusInfo(
            'Submitted',
            AppColors.infoBlue,
            AppColors.infoLight,
            Icons.upload_outlined,
          );
        case SubmissionStatus.pending:
          return _resolveDefaultStatus();
      }
    }
    return _resolveDefaultStatus();
  }

  _StatusInfo _resolveDefaultStatus() {
    if (!widget.assignment.isActive) {
      return const _StatusInfo(
        'Closed',
        AppColors.grey400,
        AppColors.surface100,
        Icons.lock_outline,
      );
    }
    if (widget.assignment.isOverdue) {
      return const _StatusInfo(
        'Overdue',
        AppColors.errorRed,
        AppColors.errorLight,
        Icons.warning_amber_outlined,
      );
    }
    return const _StatusInfo(
      'Active',
      AppColors.successGreen,
      AppColors.successLight,
      null,
    );
  }

  static Color _subjectColor(String? subject) {
    if (subject == null) return AppColors.subjectDefault;
    final lower = subject.toLowerCase();
    if (lower.contains('math')) return AppColors.subjectMath;
    if (lower.contains('science') || lower.contains('bio')) return AppColors.subjectScience;
    if (lower.contains('english')) return AppColors.subjectEnglish;
    if (lower.contains('hindi')) return AppColors.subjectHindi;
    if (lower.contains('history') || lower.contains('social')) return AppColors.subjectHistory;
    if (lower.contains('physics')) return AppColors.subjectPhysics;
    if (lower.contains('chem')) return AppColors.subjectChem;
    return AppColors.subjectDefault;
  }
}

enum SubmissionStatus { graded, submitted, pending }

class _StatusInfo {
  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;
  const _StatusInfo(this.label, this.color, this.bg, this.icon);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.info});
  final _StatusInfo info;

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
            Icon(info.icon, size: 10, color: info.color),
            const SizedBox(width: 3),
          ],
          Text(info.label,
              style: AppTypography.labelSmall.copyWith(
                  color: info.color, fontWeight: FontWeight.w700, fontSize: 10)),
        ],
      ),
    );
  }
}
