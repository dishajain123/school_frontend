import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'grade_badge.dart';

class ResultSubjectTile extends StatefulWidget {
  const ResultSubjectTile({
    super.key,
    required this.subjectName,
    required this.marksObtained,
    required this.totalMarks,
    this.gradeLetter,
    this.isPass = true,
    this.onTap,
  });

  final String subjectName;
  final double marksObtained;
  final double totalMarks;
  final String? gradeLetter;
  final bool isPass;
  final VoidCallback? onTap;

  double get percentage =>
      totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0;

  @override
  State<ResultSubjectTile> createState() => _ResultSubjectTileState();
}

class _ResultSubjectTileState extends State<ResultSubjectTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _barCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _barCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _barCtrl.forward());
  }

  @override
  void dispose() {
    _barCtrl.dispose();
    super.dispose();
  }

  Color get _accentColor {
    final p = widget.percentage;
    if (p >= 90) return const Color(0xFF059669);
    if (p >= 75) return AppColors.successGreen;
    if (p >= 60) return AppColors.infoBlue;
    if (p >= 40) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    final pct = widget.percentage;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.subjectName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GradeBadge(
                    percentage: pct,
                    gradeLetter: widget.gradeLetter,
                  ),
                  if (!widget.isPass) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Fail',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: AnimatedBuilder(
                        animation: _barAnim,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: (pct / 100) * _barAnim.value,
                            backgroundColor: AppColors.surface100,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${widget.marksObtained.toStringAsFixed(widget.marksObtained % 1 == 0 ? 0 : 1)} / ${widget.totalMarks.toStringAsFixed(widget.totalMarks % 1 == 0 ? 0 : 1)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.grey500,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}