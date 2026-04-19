import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

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
  final bool small;
  final Widget? trailing;
  final VoidCallback? onRemove;

  Color get _bg => isSelected
      ? (selectedColor ?? AppColors.navyDeep)
      : (color ?? AppColors.surface100);

  Color get _fg => isSelected
      ? (selectedTextColor ?? AppColors.white)
      : (textColor ?? AppColors.grey700);

  @override
  Widget build(BuildContext context) {
    final verticalPad = small ? 4.0 : 6.0;
    final horizontalPad = small ? 8.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPad,
          vertical: verticalPad,
        ),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusFull),
          border: isSelected
              ? null
              : Border.all(
                  color: AppColors.surface200,
                  width: 1,
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: _fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: (small
                      ? AppTypography.labelSmall
                      : AppTypography.labelMedium)
                  .copyWith(
                color: _fg,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
            if (onRemove != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.close_rounded,
                  size: 12,
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