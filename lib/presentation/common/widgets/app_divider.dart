import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Thin horizontal rule using the design system border color.
///
/// Optionally supports a centered [label] (used for "or" separators in forms).
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.label,
    this.color,
    this.thickness = AppDimensions.borderThin,
    this.indent = 0,
    this.endIndent = 0,
    this.height,
    this.padding,
  });

  /// When set, renders the label centered over the divider line.
  final String? label;
  final Color? color;
  final double thickness;
  final double indent;
  final double endIndent;
  final double? height;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.surface100;

    if (label != null) {
      return Padding(
        padding: padding ?? EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: effectiveColor,
                thickness: thickness,
                endIndent: AppDimensions.space12,
              ),
            ),
            Text(
              label!,
              style: AppTypography.labelMedium,
            ),
            Expanded(
              child: Divider(
                color: effectiveColor,
                thickness: thickness,
                indent: AppDimensions.space12,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Divider(
        color: effectiveColor,
        thickness: thickness,
        indent: indent,
        endIndent: endIndent,
        height: height ?? (thickness + AppDimensions.space8),
      ),
    );
  }
}