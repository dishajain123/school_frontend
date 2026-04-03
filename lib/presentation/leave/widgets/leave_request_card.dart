import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/leave/leave_model.dart';

/// Card displaying a leave request summary.
///
/// Used in both the TEACHER's own leave list and the PRINCIPAL's approval list.
/// When [showTeacherInfo] is true, the teacher ID area is shown (PRINCIPAL view).
class LeaveRequestCard extends StatelessWidget {
  const LeaveRequestCard({
    super.key,
    required this.leave,
    this.onTap,
    this.showTeacherLabel = false,
    this.teacherLabel,
  });

  final LeaveModel leave;
  final VoidCallback? onTap;

  /// When true, shows a "Teacher" info row (for PRINCIPAL view).
  final bool showTeacherLabel;
  final String? teacherLabel;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: AppDecorations.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row: leave type icon + type label + status chip ────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space16,
                AppDimensions.space16,
                AppDimensions.space12,
              ),
              child: Row(
                children: [
                  // Leave type icon container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: leave.leaveType.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Icon(
                      leave.leaveType.icon,
                      color: leave.leaveType.color,
                      size: AppDimensions.iconSM,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          leave.leaveType.label,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.grey800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showTeacherLabel && teacherLabel != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            teacherLabel!,
                            style: AppTypography.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  // Status chip
                  _StatusChip(status: leave.status),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────────────
            const Divider(
              height: 1,
              color: AppColors.surface100,
              indent: AppDimensions.space16,
              endIndent: AppDimensions.space16,
            ),

            // ── Date range + days count + reason preview ───────────────────
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date range row
                  Row(
                    children: [
                      const Icon(
                        Icons.date_range_outlined,
                        size: AppDimensions.iconXS,
                        color: AppColors.grey400,
                      ),
                      const SizedBox(width: AppDimensions.space6),
                      Text(
                        '${_formatDate(leave.fromDate)}  →  ${_formatDate(leave.toDate)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                      const Spacer(),
                      // Days count badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface100,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          '${leave.daysCount} ${leave.daysCount == 1 ? 'day' : 'days'}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.grey600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Reason preview
                  if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      leave.reason!,
                      style: AppTypography.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Remarks (principal's response)
                  if (leave.remarks != null && leave.remarks!.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space8,
                      ),
                      decoration: BoxDecoration(
                        color: leave.status == LeaveStatus.approved
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: AppDimensions.iconXS,
                            color: leave.status == LeaveStatus.approved
                                ? AppColors.successDark
                                : AppColors.errorDark,
                          ),
                          const SizedBox(width: AppDimensions.space6),
                          Expanded(
                            child: Text(
                              leave.remarks!,
                              style: AppTypography.bodySmall.copyWith(
                                color: leave.status == LeaveStatus.approved
                                    ? AppColors.successDark
                                    : AppColors.errorDark,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Applied date
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Applied ${_formatRelative(leave.createdAt)}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  String _formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return _formatDate(dt);
  }
}

// ── Internal status chip ──────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status.icon,
            size: AppDimensions.iconXS - 2,
            color: status.color,
          ),
          const SizedBox(width: AppDimensions.space4),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}