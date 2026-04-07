import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class SchoolLogo extends StatelessWidget {
  const SchoolLogo({
    super.key,
    this.size = 56,
    this.borderRadius = 14,
    this.imagePadding = 8,
  });

  static const String assetPath = 'assets/images/pbhs_logo.jpg';

  final double size;
  final double borderRadius;
  final double imagePadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(imagePadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          AppDimensions.radiusSmall,
        ),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.school_rounded,
            color: AppColors.navyDeep,
          ),
        ),
      ),
    );
  }
}
