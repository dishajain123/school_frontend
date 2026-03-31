import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Unified button widget covering all variants required by the design system.
///
/// Usage:
/// ```dart
/// AppButton.primary(label: 'Save', onTap: _handleSave)
/// AppButton.secondary(label: 'Cancel', onTap: _handleCancel)
/// AppButton.destructive(label: 'Delete', onTap: _handleDelete, isLoading: _loading)
/// ```
class AppButton extends StatefulWidget {
  const AppButton._({
    super.key,
    required this.label,
    required this.onTap,
    required this.variant,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.fullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.minWidth,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

  // ── Named constructors ─────────────────────────────────────────────────────

  factory AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = true,
    double height = AppDimensions.buttonHeight,
    double? minWidth,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: _ButtonVariant.primary,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: height,
        minWidth: minWidth,
        padding: padding,
      );

  factory AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = true,
    double height = AppDimensions.buttonHeight,
    double? minWidth,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: _ButtonVariant.secondary,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: height,
        minWidth: minWidth,
        padding: padding,
      );

  factory AppButton.text({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = false,
    double height = AppDimensions.buttonHeightSm,
    EdgeInsetsGeometry? padding,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: _ButtonVariant.text,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: height,
        padding: padding,
      );

  factory AppButton.icon({
    Key? key,
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = true,
    double height = AppDimensions.buttonHeight,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: _ButtonVariant.primary,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: height,
      );

  factory AppButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = true,
    double height = AppDimensions.buttonHeight,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: _ButtonVariant.destructive,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: height,
      );

  factory AppButton.small({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = false,
    _ButtonVariant variant = _ButtonVariant.primary,
  }) =>
      AppButton._(
        key: key,
        label: label,
        onTap: onTap,
        variant: variant,
        icon: icon,
        isLoading: isLoading,
        isDisabled: isDisabled,
        fullWidth: fullWidth,
        height: AppDimensions.buttonHeightSm,
      );

  final String label;
  final VoidCallback? onTap;
  final _ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final bool fullWidth;
  final double height;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  @override
  State<AppButton> createState() => _AppButtonState();
}

enum _ButtonVariant { primary, secondary, text, destructive }

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
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

  bool get _isInteractable =>
      !widget.isDisabled && !widget.isLoading && widget.onTap != null;

  void _handleTapDown(_) {
    if (_isInteractable) _scaleController.forward();
  }

  void _handleTapUp(_) {
    if (_isInteractable) _scaleController.reverse();
  }

  void _handleTapCancel() {
    if (_isInteractable) _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final child = _buildButton();
    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: child)
        : child;
  }

  Widget _buildButton() {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildStyledButton(),
      ),
    );
  }

  Widget _buildStyledButton() {
    switch (widget.variant) {
      case _ButtonVariant.primary:
        return _PrimaryButton(
          label: widget.label,
          onTap: _isInteractable ? widget.onTap : null,
          icon: widget.icon,
          isLoading: widget.isLoading,
          isDisabled: widget.isDisabled,
          height: widget.height,
          minWidth: widget.minWidth,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          textStyle: widget.textStyle,
        );
      case _ButtonVariant.secondary:
        return _SecondaryButton(
          label: widget.label,
          onTap: _isInteractable ? widget.onTap : null,
          icon: widget.icon,
          isLoading: widget.isLoading,
          isDisabled: widget.isDisabled,
          height: widget.height,
          minWidth: widget.minWidth,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
          textStyle: widget.textStyle,
        );
      case _ButtonVariant.text:
        return _TextButton(
          label: widget.label,
          onTap: _isInteractable ? widget.onTap : null,
          icon: widget.icon,
          isLoading: widget.isLoading,
          isDisabled: widget.isDisabled,
          height: widget.height,
          padding: widget.padding,
          textStyle: widget.textStyle,
        );
      case _ButtonVariant.destructive:
        return _DestructiveButton(
          label: widget.label,
          onTap: _isInteractable ? widget.onTap : null,
          icon: widget.icon,
          isLoading: widget.isLoading,
          isDisabled: widget.isDisabled,
          height: widget.height,
          minWidth: widget.minWidth,
          padding: widget.padding,
          borderRadius: widget.borderRadius,
        );
    }
  }
}

// ── Variant implementations ────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = AppDimensions.buttonHeight,
    this.minWidth,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final bg = isDisabled ? AppColors.surface200 : AppColors.navyDeep;
    final fg = isDisabled ? AppColors.grey400 : AppColors.white;

    return Material(
      color: bg,
      borderRadius: borderRadius ??
          BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppDimensions.radiusMedium),
        splashColor: AppColors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          constraints: minWidth != null
              ? BoxConstraints(minWidth: minWidth!)
              : null,
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24),
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            color: fg,
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = AppDimensions.buttonHeight,
    this.minWidth,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDisabled ? AppColors.surface200 : AppColors.navyDeep;
    final fg = isDisabled ? AppColors.grey400 : AppColors.navyDeep;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius ??
          BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppDimensions.radiusMedium),
        splashColor:
            AppColors.navyLight.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          constraints: minWidth != null
              ? BoxConstraints(minWidth: minWidth!)
              : null,
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
              width: AppDimensions.borderMedium,
            ),
            borderRadius: borderRadius ??
                BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            color: fg,
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = AppDimensions.buttonHeightSm,
    this.padding,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final fg = isDisabled ? AppColors.grey400 : AppColors.navyMedium;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        splashColor:
            AppColors.navyLight.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12,
                  vertical: AppDimensions.space8),
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            color: fg,
            textStyle: textStyle,
          ),
        ),
      ),
    );
  }
}

class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = AppDimensions.buttonHeight,
    this.minWidth,
    this.padding,
    this.borderRadius,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final bg = isDisabled ? AppColors.surface200 : AppColors.errorRed;
    final fg = isDisabled ? AppColors.grey400 : AppColors.white;

    return Material(
      color: bg,
      borderRadius: borderRadius ??
          BorderRadius.circular(AppDimensions.radiusMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ??
            BorderRadius.circular(AppDimensions.radiusMedium),
        splashColor: AppColors.white.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          constraints: minWidth != null
              ? BoxConstraints(minWidth: minWidth!)
              : null,
          padding: padding ??
              const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space24),
          child: _ButtonContent(
            label: label,
            icon: icon,
            isLoading: isLoading,
            color: fg,
          ),
        ),
      ),
    );
  }
}

/// Internal content widget shared across all button variants.
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.color,
    this.icon,
    this.isLoading = false,
    this.textStyle,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool isLoading;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppDimensions.iconSM),
          const SizedBox(width: AppDimensions.space8),
          Text(
            label,
            style: (textStyle ??
                    AppTypography.buttonPrimary)
                .copyWith(color: color),
          ),
        ],
      );
    }

    return Center(
      child: Text(
        label,
        style: (textStyle ?? AppTypography.buttonPrimary)
            .copyWith(color: color),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}