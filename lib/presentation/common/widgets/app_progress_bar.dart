import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Animated horizontal progress bar.
///
/// Animates from 0 to [value] on first render (600ms, easeOutCubic).
/// Commonly used for attendance percentages and completion indicators.
///
/// Usage:
/// ```dart
/// AppProgressBar(
///   value: attendancePercent / 100,
///   label: '${attendancePercent.toStringAsFixed(1)}%',
///   color: attendancePercent >= 75 ? AppColors.successGreen : AppColors.errorRed,
/// )
/// ```
class AppProgressBar extends StatefulWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.label,
    this.subLabel,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.animate = true,
    this.showPercentage = false,
    this.borderRadius,
  }) : assert(value >= 0.0 && value <= 1.0,
            'value must be between 0.0 and 1.0');

  /// Progress from 0.0 (empty) to 1.0 (full).
  final double value;

  /// Optional label shown to the right of the bar.
  final String? label;

  /// Optional secondary text shown below the bar.
  final String? subLabel;

  final Color? color;
  final Color? backgroundColor;

  /// Height of the bar track.
  final double height;

  /// Whether to animate the fill on initial render.
  final bool animate;

  /// When true, automatically appends a percentage label.
  final bool showPercentage;

  final BorderRadius? borderRadius;

  /// Returns a semantic color based on the value:
  /// - ≥ 0.85 → success green
  /// - ≥ 0.75 → warning amber
  /// - < 0.75 → error red
  static Color semanticColor(double value) {
    if (value >= 0.85) return AppColors.successGreen;
    if (value >= 0.75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.animate ? widget.value : widget.value,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    if (widget.animate) {
      _controller.forward();
    }
    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(AppProgressBar old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _animation = Tween<double>(
        begin: _previousValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
      _previousValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _barColor =>
      widget.color ?? AppProgressBar.semanticColor(widget.value);

  String? get _effectiveLabel {
    if (widget.label != null) return widget.label;
    if (widget.showPercentage) {
      return '${(widget.value * 100).toStringAsFixed(1)}%';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = _effectiveLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (effectiveLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.subLabel != null)
                  Text(
                    widget.subLabel!,
                    style: AppTypography.bodySmall,
                  ),
                const Spacer(),
                Text(
                  effectiveLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: _barColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        AnimatedBuilder(
          animation: _animation,
          builder: (_, __) {
            return ClipRRect(
              borderRadius: widget.borderRadius ??
                  BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: _animation.value,
                backgroundColor:
                    widget.backgroundColor ?? AppColors.surface100,
                valueColor: AlwaysStoppedAnimation<Color>(_barColor),
                minHeight: widget.height,
              ),
            );
          },
        ),
        if (widget.subLabel != null && effectiveLabel == null)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space4),
            child: Text(
              widget.subLabel!,
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }
}