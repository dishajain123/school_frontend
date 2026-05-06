import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/academic_year/academic_year_model.dart';

class YearTile extends StatefulWidget {
  const YearTile({
    super.key,
    required this.year,
    required this.canManage,
    required this.onActivate,
    required this.onEdit,
  });

  final AcademicYearModel year;
  final bool canManage;
  final VoidCallback onActivate;
  final VoidCallback onEdit;

  @override
  State<YearTile> createState() => _YearTileState();
}

class _YearTileState extends State<YearTile>
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
    final isActive = widget.year.isActive;

    return ScaleTransition(
      scale: _scale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.goldPrimary.withValues(alpha: 0.5)
                : AppColors.surface100,
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? AppColors.goldPrimary.withValues(alpha: 0.12)
                  : AppColors.navyDeep.withValues(alpha: 0.06),
              blurRadius: isActive ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _YearAvatar(isActive: isActive),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.year.name,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.goldLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.goldPrimary
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Text(
                              'Active',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.goldDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: AppColors.grey400),
                        const SizedBox(width: 4),
                        Text(
                          '${DateFormatter.formatDate(widget.year.startDate)} – ${DateFormatter.formatDate(widget.year.endDate)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.canManage) ...[
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      _IconAction(
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.successGreen,
                        tooltip: 'Set Active',
                        onTap: widget.onActivate,
                      ),
                    if (!isActive) const SizedBox(width: 6),
                    _IconAction(
                      icon: Icons.edit_outlined,
                      color: AppColors.navyMedium,
                      tooltip: 'Edit',
                      onTap: widget.onEdit,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _YearAvatar extends StatelessWidget {
  const _YearAvatar({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.goldPrimary.withValues(alpha: 0.12)
            : AppColors.surface100,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        Icons.calendar_today_rounded,
        color: isActive ? AppColors.goldDark : AppColors.grey400,
        size: 20,
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}