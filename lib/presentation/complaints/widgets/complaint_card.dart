import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../common/widgets/app_status_chip.dart';

class ComplaintCard extends StatefulWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  final ComplaintModel complaint;
  final VoidCallback? onTap;

  @override
  State<ComplaintCard> createState() => _ComplaintCardState();
}

class _ComplaintCardState extends State<ComplaintCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
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
    final complaint = widget.complaint;
    final catColor = complaint.category.color;

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
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
                    color: catColor,
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
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(complaint.category.icon,
                                  size: 16, color: catColor),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                complaint.category.label,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.grey800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppStatusChip(
                                status: complaint.status.backendValue,
                                small: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          complaint.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.grey600,
                            height: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProgressStrip(status: complaint.status),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 12, color: AppColors.grey400),
                            const SizedBox(width: 4),
                            Text(
                              DateFormatter.formatDate(complaint.createdAt),
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey400,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            if (complaint.isAnonymous)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.surface100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Anonymous',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.grey500,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            if (complaint.attachmentKey != null) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.attach_file_rounded,
                                  size: 12, color: AppColors.grey400),
                            ],
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16, color: AppColors.grey400),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.status});

  final ComplaintStatus status;

  @override
  Widget build(BuildContext context) {
    final currentStep = status.indexValue + 1;
    const totalSteps = 4;
    final progress = currentStep / totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.track_changes_outlined,
              size: 12,
              color: AppColors.grey500,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Progress: ${status.label} ($currentStep/$totalSteps)',
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: status.color,
            backgroundColor: AppColors.surface100,
          ),
        ),
      ],
    );
  }
}
