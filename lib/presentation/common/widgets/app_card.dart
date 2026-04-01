import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';

/// Elevated card wrapper that applies design system shadow, radius, and ripple.
///
/// Usage:
/// ```dart
/// AppCard(
///   onTap: () => context.push('/detail'),
///   child: Text('Card content'),
/// )
/// ```
///
/// Variants:
/// - Default: white background, shadow1, radiusMedium
/// - [AppCard.hero]: white background, shadow2, radiusLarge (for dashboard sections)
/// - [AppCard.outlined]: no shadow, border only
/// - [AppCard.surface]: off-white background, for section containers
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.clipBehavior = Clip.antiAlias,
    _CardVariant variant = _CardVariant.standard,
  }) : _variant = variant;

  factory AppCard.hero({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
  }) =>
      AppCard(
        key: key,
        onTap: onTap,
        padding: padding,
        margin: margin,
        backgroundColor: backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppDecorations.shadow2,
        variant: _CardVariant.hero,
        child: child,
      );

  factory AppCard.outlined({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? backgroundColor,
    Color? borderColor,
  }) =>
      AppCard(
        key: key,
        onTap: onTap,
        padding: padding,
        margin: margin,
        backgroundColor: backgroundColor ?? AppColors.white,
        boxShadow: AppDecorations.shadow0,
        border: Border.all(
          color: borderColor ?? AppColors.surface200,
          width: AppDimensions.borderThin,
        ),
        variant: _CardVariant.outlined,
        child: child,
      );

  factory AppCard.surface({
    Key? key,
    required Widget child,
    VoidCallback? onTap,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) =>
      AppCard(
        key: key,
        onTap: onTap,
        padding: padding,
        margin: margin,
        backgroundColor: AppColors.surface50,
        boxShadow: AppDecorations.shadow0,
        border: Border.all(
          color: AppColors.surface100,
          width: AppDimensions.borderThin,
        ),
        variant: _CardVariant.surface,
        child: child,
      );

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final BoxBorder? border;
  final Clip clipBehavior;
  final _CardVariant _variant;

  @override
  State<AppCard> createState() => _AppCardState();
}

enum _CardVariant { standard, hero, outlined, surface }

class _AppCardState extends State<AppCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.99).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  BorderRadius get _borderRadius =>
      widget.borderRadius ??
      BorderRadius.circular(
        widget._variant == _CardVariant.hero
            ? AppDimensions.radiusLarge
            : AppDimensions.radiusMedium,
      );

  List<BoxShadow> get _shadow =>
      widget.boxShadow ??
      (widget._variant == _CardVariant.hero
          ? AppDecorations.shadow2
          : AppDecorations.shadow1);

  EdgeInsetsGeometry get _defaultPadding =>
      EdgeInsets.all(
        widget._variant == _CardVariant.hero
            ? AppDimensions.space20
            : AppDimensions.space16,
      );

  @override
  Widget build(BuildContext context) {
    final br = _borderRadius;

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.white,
        borderRadius: br,
        boxShadow: _shadow,
        border: widget.border,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Padding(
          padding: widget.padding ?? _defaultPadding,
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        onTapDown: (_) => _scaleController.forward(),
        onTapUp: (_) {
          _scaleController.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _scaleController.reverse(),
        onLongPress: widget.onLongPress,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: content,
        ),
      );
    }

    return content;
  }
}
