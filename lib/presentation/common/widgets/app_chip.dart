import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Generic compact chip for tags, categories, and filter labels.
///
/// For backend status enums (PENDING, APPROVED, etc.), use [AppStatusChip] instead.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.icon,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.selectedTextColor,
    this.small = false,
    this.trailing,
    this.onRemove,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final Color? selectedTextColor;

  /// When true, uses a more compact size (used in filter bars).
  final bool small;

  final Widget? trailing;
  final VoidCallback? onRemove;

  Color get _bg => isSelected
      ? (selectedColor ?? AppColors.navyDeep)
      : (color ?? AppColors.surface100);

  Color get _fg => isSelected
      ? (selectedTextColor ?? AppColors.white)
      : (textColor ?? AppColors.grey800);

  @override
  Widget build(BuildContext context) {
    final verticalPad = small ? AppDimensions.space4 : 6.0;
    final horizontalPad = small
        ? AppDimensions.space8
        : AppDimensions.space12;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: verticalPad,
        ),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.surface200,
                  width: AppDimensions.borderThin,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppDimensions.iconXS, color: _fg),
              const SizedBox(width: AppDimensions.space4),
            ],
            Text(
              label,
              style: (small
                      ? AppTypography.labelSmall
                      : AppTypography.labelMedium)
                  .copyWith(
                color: _fg,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppDimensions.space4),
              trailing!,
            ],
            if (onRemove != null) ...[
              const SizedBox(width: AppDimensions.space4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: AppDimensions.iconXS,
                  color: _fg.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}