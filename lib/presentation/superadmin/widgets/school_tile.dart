import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/school/school_model.dart';

class SchoolTile extends StatefulWidget {
  const SchoolTile({
    super.key,
    required this.school,
    this.onTap,
    this.isLast = false,
  });

  final SchoolModel school;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  State<SchoolTile> createState() => _SchoolTileState();
}

class _SchoolTileState extends State<SchoolTile>
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

  Color get _planColor {
    switch (widget.school.subscriptionPlan) {
      case SubscriptionPlan.basic:
        return AppColors.infoBlue;
      case SubscriptionPlan.standard:
        return AppColors.warningAmber;
      case SubscriptionPlan.premium:
        return AppColors.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final school = widget.school;
    final planColor = _planColor;

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
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.business_outlined,
                      color: AppColors.navyMedium, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.name,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        school.contactEmail,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grey400,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: planColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: planColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        school.subscriptionPlan.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: planColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: school.isActive
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          school.isActive ? 'Active' : 'Inactive',
                          style: AppTypography.caption.copyWith(
                            color: school.isActive
                                ? AppColors.successGreen
                                : AppColors.errorRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.grey300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}