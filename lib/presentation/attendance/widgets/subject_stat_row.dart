import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

class SubjectStatRow extends StatefulWidget {
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

  @override
  State<SubjectStatRow> createState() => _SubjectStatRowState();
}

class _SubjectStatRowState extends State<SubjectStatRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _barAnim = Tween<double>(begin: 0, end: widget.percentage / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _barColor {
    if (widget.percentage >= 85) return AppColors.successGreen;
    if (widget.percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: widget.isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.surface100, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _barColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.subjectName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis),
                    Text(widget.subjectCode,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 11,
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: _barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.percentage.toStringAsFixed(1)}%',
                      style: AppTypography.labelSmall.copyWith(
                        color: _barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.present}/${widget.total}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _barAnim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: _barAnim.value,
                backgroundColor: AppColors.surface100,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                minHeight: 5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}