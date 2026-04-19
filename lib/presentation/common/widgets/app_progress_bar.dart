import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

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

  final double value;
  final String? label;
  final String? subLabel;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final bool animate;
  final bool showPercentage;
  final BorderRadius? borderRadius;

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
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.animate ? widget.value : widget.value,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    if (widget.animate) _controller.forward();
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
        if (effectiveLabel != null || widget.subLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.subLabel != null)
                  Text(
                    widget.subLabel!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  )
                else
                  const Spacer(),
                if (effectiveLabel != null)
                  Text(
                    effectiveLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: _barColor,
                      fontWeight: FontWeight.w700,
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
      ],
    );
  }
}