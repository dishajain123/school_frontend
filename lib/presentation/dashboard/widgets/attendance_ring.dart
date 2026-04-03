import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: AppDimensions.space8,
        mainAxisSpacing: AppDimensions.space8,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _QuickActionTile(item: actions[i]),
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({required this.item});
  final QuickActionItem item;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.item.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: AppDecorations.shadow1,
            border: Border.all(
                color: AppColors.surface200,
                width: AppDimensions.borderThin),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.quickActionContainer(
                    widget.item.color),
                child: Icon(widget.item.icon,
                    size: AppDimensions.iconSM,
                    color: widget.item.color),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                widget.item.label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.grey800,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({
    super.key,
    required this.percentage,
    this.size = 72,
  });

  final double percentage;
  final double size;

  Color _ringColor(double pct) {
    if (pct >= 85) return AppColors.successGreen;
    if (pct >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final value = (percentage.clamp(0, 100)) / 100;
    final color = _ringColor(percentage);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 6,
            backgroundColor: AppColors.white.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            '${percentage.toStringAsFixed(0)}%',
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
