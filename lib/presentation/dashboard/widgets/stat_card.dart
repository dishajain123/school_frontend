import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StatCard extends StatefulWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendPositive = true,
    this.onTap,
    this.isLoading = false,
    this.subtitle,
    this.accentColor,
    this.compact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? subtitle;
  final Color? accentColor;
  final bool compact;

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color get _iconColor => widget.iconColor ?? AppColors.navyMedium;
  Color get _accent => widget.accentColor ?? _iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              _scaleController.forward();
              HapticFeedback.selectionClick();
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _scaleController.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _scaleController.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(widget.compact ? 10 : 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: AppColors.surface100),
          ),
          child: widget.isLoading
              ? const _StatCardSkeleton()
              : _CardContent(
                  label: widget.label,
                  value: widget.value,
                  icon: widget.icon,
                  iconColor: _iconColor,
                  accent: _accent,
                  trend: widget.trend,
                  trendPositive: widget.trendPositive,
                  onTap: widget.onTap,
                  subtitle: widget.subtitle,
                  compact: widget.compact,
                ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.accent,
    required this.trendPositive,
    required this.compact,
    this.trend,
    this.onTap,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color iconColor;
  final Color accent;
  final String? trend;
  final bool trendPositive;
  final VoidCallback? onTap;
  final String? subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: compact ? 26 : 30,
            height: compact ? 26 : 30,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(compact ? 8 : 9),
            ),
            child: Icon(icon, size: compact ? 14 : 16, color: iconColor),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 16 : 18,
                        letterSpacing: -0.3,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trend != null) ...[
                    const SizedBox(width: 6),
                    _TrendBadge(trend: trend!, isPositive: trendPositive),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: compact ? 10 : 10.5,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey400,
                    fontSize: compact ? 9.5 : 10,
                    height: 1.05,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        if (onTap != null) ...[
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded, size: 16, color: accent),
        ],
      ],
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend, required this.isPositive});
  final String trend;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final bg = isPositive ? AppColors.successLight : AppColors.errorLight;
    final icon = isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            trend,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 15,
                decoration: BoxDecoration(
                  color: AppColors.surface100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: 90,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.surface100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal scrollable stat strip — 3–4 compact cards in a row
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.cards});
  final List<StatCard> cards;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: 130, child: cards[i]),
      ),
    );
  }
}
