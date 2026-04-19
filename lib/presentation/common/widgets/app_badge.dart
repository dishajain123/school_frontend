import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

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
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final badgeDiameter = size ?? 17.0;
    final label = count > 99 ? '99+' : count.toString();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -5,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              constraints: BoxConstraints(
                minWidth: badgeDiameter,
                minHeight: badgeDiameter,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: count > 9 ? 4 : 0,
              ),
              decoration: BoxDecoration(
                color: badgeColor ?? AppColors.errorRed,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: AppColors.navyDeep,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorRed.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
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