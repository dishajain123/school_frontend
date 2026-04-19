import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

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
    this.width,
    this.padding,
    this.borderRadius,
    this.textStyle,
  });

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
    double? width,
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
        width: width,
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
    double? width,
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
        width: width,
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
    double? width,
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
        width: width,
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
    double? width,
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
        width: width,
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
    double? width,
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
        width: width,
      );

  factory AppButton.small({
    Key? key,
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool isLoading = false,
    bool isDisabled = false,
    bool fullWidth = false,
    double? width,
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
        width: width,
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
  final double? width;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final dynamic textStyle;

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
      duration: const Duration(milliseconds: 90),
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
    if (widget.fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    if (widget.width != null) {
      return SizedBox(width: widget.width, child: child);
    }
    return child;
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
  final dynamic textStyle;

  @override
  Widget build(BuildContext context) {
    final bg = isDisabled ? AppColors.surface200 : AppColors.navyDeep;
    final fg = isDisabled ? AppColors.grey400 : AppColors.white;
    final br = borderRadius ?? BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF0F2340)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? bg : null,
          borderRadius: br,
          boxShadow: isDisabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          splashColor: AppColors.white.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Container(
            height: height,
            constraints:
                minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
            child: _ButtonContent(
              label: label,
              icon: icon,
              isLoading: isLoading,
              color: fg,
              textStyle: textStyle,
            ),
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
  final dynamic textStyle;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isDisabled ? AppColors.surface200 : AppColors.navyDeep;
    final fg = isDisabled ? AppColors.grey400 : AppColors.navyDeep;
    final br = borderRadius ?? BorderRadius.circular(12);

    return Material(
      color: Colors.transparent,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        splashColor: AppColors.navyLight.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          constraints:
              minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1.5),
            borderRadius: br,
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
  final dynamic textStyle;

  @override
  Widget build(BuildContext context) {
    final fg = isDisabled ? AppColors.grey400 : AppColors.navyMedium;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        splashColor: AppColors.navyLight.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space8,
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
    final br = borderRadius ?? BorderRadius.circular(12);

    return Material(
      color: bg,
      borderRadius: br,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        splashColor: AppColors.white.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Container(
          height: height,
          constraints:
              minWidth != null ? BoxConstraints(minWidth: minWidth!) : null,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
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
  final dynamic textStyle;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      );
    }

    if (icon != null) {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: AppDimensions.iconSM),
              const SizedBox(width: AppDimensions.space8),
              Text(
                label,
                style:
                    (textStyle ?? AppTypography.buttonPrimary).copyWith(color: color),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Text(
        label,
        style: (textStyle ?? AppTypography.buttonPrimary).copyWith(color: color),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        textScaler: TextScaler.noScaling,
      ),
    );
  }
}
