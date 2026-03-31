import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Wraps any widget with a notification count badge in the top-right corner.
///
/// The badge is hidden when [count] is 0.
/// When [count] > 99, displays "99+".
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.child,
    required this.count,
    this.badgeColor,
    this.textColor,
    this.size,
  });

  final Widget child;
  final int count;
  final Color? badgeColor;
  final Color? textColor;

  /// Diameter of the badge circle. Defaults to 18px.
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final badgeDiameter = size ?? 18.0;
    final label = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              constraints: BoxConstraints(
                minWidth: badgeDiameter,
                minHeight: badgeDiameter,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: count > 9 ? AppDimensions.space4 : 0,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.errorRed,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.navyDeep,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: textColor ?? AppColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}