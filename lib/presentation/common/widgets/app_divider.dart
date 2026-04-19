import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.label,
    this.color,
    this.thickness = 1,
    this.indent = 0,
    this.endIndent = 0,
    this.height,
    this.padding,
  });

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
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 12,
              ),
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