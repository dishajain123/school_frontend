import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
}

class QuickActionGrid extends StatefulWidget {
  const QuickActionGrid({
    super.key,
    required this.actions,
    this.primaryCount = 4,
    this.showAllInitially = false,
  });

  final List<QuickActionItem> actions;
  final int primaryCount;
  final bool showAllInitially;

  @override
  State<QuickActionGrid> createState() => _QuickActionGridState();
}

class _QuickActionGridState extends State<QuickActionGrid>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _expanded = widget.showAllInitially;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    if (_expanded) _ctrl.value = 1.0;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.actions.take(widget.primaryCount).toList();
    final secondary = widget.actions.skip(widget.primaryCount).toList();
    final hasSecondary = secondary.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrimaryActionsRow(actions: primary),
        if (hasSecondary) ...[
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: _fade,
            builder: (_, child) {
              return Column(
                children: [
                  if (_expanded)
                    FadeTransition(
                      opacity: _fade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SecondaryGrid(actions: secondary),
                      ),
                    ),
                  _ExpandToggle(
                    expanded: _expanded,
                    count: secondary.length,
                    onTap: _toggle,
                  ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _PrimaryActionsRow extends StatelessWidget {
  const _PrimaryActionsRow({required this.actions});
  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: actions.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: _PrimaryActionTile(item: item),
          ),
        );
      }).toList(),
    );
  }
}

class _PrimaryActionTile extends StatefulWidget {
  const _PrimaryActionTile({required this.item});
  final QuickActionItem item;

  @override
  State<_PrimaryActionTile> createState() => _PrimaryActionTileState();
}

class _PrimaryActionTileState extends State<_PrimaryActionTile>
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
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) {
        _ctrl.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        item.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hasBoundedHeight =
                constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
            final isTight = hasBoundedHeight && constraints.maxHeight <= 68;
            final verticalPadding = isTight ? 6.0 : 14.0;
            final iconBox = isTight ? 30.0 : 44.0;
            final iconSize = isTight ? 16.0 : 22.0;
            final iconRadius = isTight ? 10.0 : 14.0;
            final gap = isTight ? 3.0 : 7.0;
            final fontSize = isTight ? 9.0 : 11.0;
            final maxLines = isTight ? 1 : 2;
            final contentHeight = hasBoundedHeight
                ? (constraints.maxHeight - (verticalPadding * 2))
                    .clamp(0.0, double.infinity)
                    .toDouble()
                : null;

            return Container(
              padding: EdgeInsets.symmetric(vertical: verticalPadding),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.color.withValues(alpha: 0.18), width: 1),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (contentHeight != null)
                    SizedBox(
                      height: contentHeight,
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _TileContent(
                            item: item,
                            iconBox: iconBox,
                            iconSize: iconSize,
                            iconRadius: iconRadius,
                            gap: gap,
                            fontSize: fontSize,
                            maxLines: maxLines,
                            isTight: isTight,
                          ),
                        ),
                      ),
                    )
                  else
                    _TileContent(
                      item: item,
                      iconBox: iconBox,
                      iconSize: iconSize,
                      iconRadius: iconRadius,
                      gap: gap,
                      fontSize: fontSize,
                      maxLines: maxLines,
                      isTight: isTight,
                    ),
                  if (item.badge != null)
                    Positioned(
                      top: -4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.errorRed,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.badge!,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textScaler: TextScaler.noScaling,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TileContent extends StatelessWidget {
  const _TileContent({
    required this.item,
    required this.iconBox,
    required this.iconSize,
    required this.iconRadius,
    required this.gap,
    required this.fontSize,
    required this.maxLines,
    required this.isTight,
  });

  final QuickActionItem item;
  final double iconBox;
  final double iconSize;
  final double iconRadius;
  final double gap;
  final double fontSize;
  final int maxLines;
  final bool isTight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(iconRadius),
          ),
          child: Icon(item.icon, size: iconSize, color: item.color),
        ),
        SizedBox(height: gap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              height: isTight ? 1.0 : 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
          ),
        ),
      ],
    );
  }
}

class _SecondaryGrid extends StatelessWidget {
  const _SecondaryGrid({required this.actions});
  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.92,
      ),
      itemCount: actions.length,
      itemBuilder: (context, i) => _PrimaryActionTile(item: actions[i]),
    );
  }
}

class _ExpandToggle extends StatelessWidget {
  const _ExpandToggle({
    required this.expanded,
    required this.count,
    required this.onTap,
  });
  final bool expanded;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              expanded ? 'Show less' : 'More actions ($count)',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceRing extends StatefulWidget {
  const AttendanceRing({super.key, required this.percentage, this.size = 72});

  final double percentage;
  final double size;

  @override
  State<AttendanceRing> createState() => _AttendanceRingState();
}

class _AttendanceRingState extends State<AttendanceRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.percentage / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _ringColor(double pct) {
    if (pct >= 85) return AppColors.successGreen;
    if (pct >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _ringColor(widget.percentage);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: _anim.value,
              strokeWidth: 5,
              backgroundColor: AppColors.surface100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
            Text(
              '${widget.percentage.toStringAsFixed(0)}%',
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
