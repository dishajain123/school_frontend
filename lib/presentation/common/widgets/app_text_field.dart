import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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
  final Widget? suffix;
  final Widget? suffixIcon;
  final Widget? prefix;
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
          _obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 18,
          color: _isFocused ? AppColors.navyMedium : AppColors.grey400,
        ),
        splashRadius: 20,
      );
    }
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (widget.suffixIconData != null) {
      return Icon(
        widget.suffixIconData,
        size: 18,
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
        size: 18,
        color: _isFocused ? AppColors.navyMedium : AppColors.grey400,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? BorderRadius.circular(12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppTypography.labelMedium.copyWith(
              color: _isFocused ? AppColors.navyMedium : AppColors.grey600,
              fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w500,
            ),
            child: Text(widget.label!),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.navyMedium.withValues(alpha: 0.12),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
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
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.grey800,
              fontSize: 15,
            ),
            cursorColor: AppColors.navyMedium,
            cursorWidth: 1.5,
            buildCounter: widget.showCounter
                ? null
                : (_, {required currentLength, required isFocused, maxLength}) =>
                    null,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 15,
              ),
              helperText: widget.helperText,
              helperStyle: AppTypography.caption,
              filled: true,
              fillColor: !widget.enabled
                  ? AppColors.surface100
                  : (widget.fillColor ?? AppColors.white),
              contentPadding: widget.contentPadding ??
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffix: widget.suffix,
              suffixIcon: _buildSuffixIcon(),
              prefix: widget.prefix,
              prefixIcon: _buildPrefixIcon(),
              border: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.surface200,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.surface200,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.navyMedium,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.errorRed,
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.errorRed,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(
                  color: AppColors.surface100,
                  width: 1,
                ),
              ),
              errorStyle: AppTypography.labelSmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}