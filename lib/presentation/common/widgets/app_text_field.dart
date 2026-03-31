import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// A consistent text input widget that follows the design system spec.
///
/// Wraps [TextFormField] with proper styling, label, hint, and error handling.
/// All styling comes from the theme — no overrides needed in screen code.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffix,
    this.suffixIcon,
    this.prefix,
    this.prefixIcon,
    this.prefixIconData,
    this.suffixIconData,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.readOnly = false,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.initialValue,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.showCounter = false,
    this.helperText,
    this.fillColor,
    this.borderRadius,
    this.contentPadding,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;

  /// Custom widget placed after the text.
  final Widget? suffix;

  /// Custom suffix icon widget (takes precedence over [suffixIconData]).
  final Widget? suffixIcon;

  /// Custom prefix widget placed before the text.
  final Widget? prefix;

  /// Custom prefix icon widget (takes precedence over [prefixIconData]).
  final Widget? prefixIcon;

  final IconData? prefixIconData;
  final IconData? suffixIconData;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final String? initialValue;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Shows character counter below field when [maxLength] is set.
  final bool showCounter;
  final String? helperText;
  final Color? fillColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;
  bool _isFocused = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  Widget? _buildSuffixIcon() {
    if (widget.obscureText) {
      return IconButton(
        onPressed: () => setState(() => _obscureText = !_obscureText),
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: AppDimensions.iconSM,
          color: _isFocused ? AppColors.navyMedium : AppColors.grey400,
        ),
        splashRadius: 20,
      );
    }
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (widget.suffixIconData != null) {
      return Icon(
        widget.suffixIconData,
        size: AppDimensions.iconSM,
        color: _isFocused ? AppColors.navyMedium : AppColors.grey400,
      );
    }
    return null;
  }

  Widget? _buildPrefixIcon() {
    if (widget.prefixIcon != null) return widget.prefixIcon;
    if (widget.prefixIconData != null) {
      return Icon(
        widget.prefixIconData,
        size: AppDimensions.iconSM,
        color: _isFocused ? AppColors.navyMedium : AppColors.grey400,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ??
        BorderRadius.circular(AppDimensions.radiusSmall);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: _isFocused ? AppColors.navyMedium : AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          focusNode: _focusNode,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: _obscureText,
          maxLines: _obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onEditingComplete: widget.onEditingComplete,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          autofocus: widget.autofocus,
          inputFormatters: widget.inputFormatters,
          textCapitalization: widget.textCapitalization,
          style: AppTypography.bodyLarge.copyWith(color: AppColors.grey800),
          cursorColor: AppColors.navyMedium,
          buildCounter: widget.showCounter
              ? null
              : (_, {required currentLength, required isFocused, maxLength}) =>
                  null,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey400,
            ),
            helperText: widget.helperText,
            helperStyle: AppTypography.caption,
            filled: true,
            fillColor: !widget.enabled
                ? AppColors.surface100
                : (widget.fillColor ?? AppColors.surface50),
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: 14,
                ),
            suffix: widget.suffix,
            suffixIcon: _buildSuffixIcon(),
            prefix: widget.prefix,
            prefixIcon: _buildPrefixIcon(),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.surface200,
                width: AppDimensions.borderMedium,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.surface200,
                width: AppDimensions.borderMedium,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.navyMedium,
                width: AppDimensions.borderMedium,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: AppDimensions.borderMedium,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.errorRed,
                width: AppDimensions.borderThick,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(
                color: AppColors.surface100,
                width: AppDimensions.borderThin,
              ),
            ),
            errorStyle: AppTypography.labelSmall.copyWith(
              color: AppColors.errorRed,
            ),
          ),
        ),
      ],
    );
  }
}