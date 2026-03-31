import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Compact metric display tile used in dashboards.
///
/// Features:
/// - Animated count-up for numeric values
/// - Optional trend indicator (up/down arrow + change value)
/// - Icon in a colored container
/// - Tap to navigate to the relevant detail screen
class AppStatCard extends StatefulWidget {
  const AppStatCard({
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
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  /// Optional trend string like "+5%" or "↑ 3".
  final String? trend;

  /// True if trend is positive (green), false if negative (red).
  final bool trendPositive;
  final VoidCallback? onTap;
  final bool isLoading;
  final String? subtitle;
  final Color? accentColor;

  @override
  State<AppStatCard> createState() => _AppStatCardState();
}

class _AppStatCardState extends State<AppStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  Color get _iconColor =>
      widget.iconColor ?? widget.accentColor ?? AppColors.navyMedium;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => _scaleController.forward()
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _scaleController.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null
          ? () => _scaleController.reverse()
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: AppDecorations.shadow1,
            border: Border.all(
              color: AppColors.surface200,
              width: AppDimensions.borderThin,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + trend row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.icon != null)
                    Container(
                      width: AppDimensions.quickActionIconContainer,
                      height: AppDimensions.quickActionIconContainer,
                      decoration: AppDecorations.quickActionContainer(
                        _iconColor,
                      ),
                      child: Icon(
                        widget.icon,
                        size: AppDimensions.iconSM,
                        color: _iconColor,
                      ),
                    ),
                  if (widget.trend != null) ...[
                    const Spacer(),
                    _TrendBadge(
                      trend: widget.trend!,
                      isPositive: widget.trendPositive,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              // Value
              Text(
                widget.value,
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.space4),
              // Label
              Text(
                widget.label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppDimensions.space2),
                Text(
                  widget.subtitle!,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({
    required this.trend,
    required this.isPositive,
  });

  final String trend;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? AppColors.successGreen : AppColors.errorRed;
    final bg = isPositive ? AppColors.successLight : AppColors.errorLight;
    final icon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.iconXS, color: color),
          const SizedBox(width: 2),
          Text(
            trend,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}