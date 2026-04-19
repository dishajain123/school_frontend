import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class GradeBadge extends StatelessWidget {
  const GradeBadge({
    super.key,
    required this.percentage,
    this.gradeLetter,
    this.size = _GradeBadgeSize.medium,
  });

  final double percentage;
  final String? gradeLetter;
  final _GradeBadgeSize size;

  factory GradeBadge.small({
    Key? key,
    required double percentage,
    String? gradeLetter,
  }) =>
      GradeBadge(
        key: key,
        percentage: percentage,
        gradeLetter: gradeLetter,
        size: _GradeBadgeSize.small,
      );

  factory GradeBadge.large({
    Key? key,
    required double percentage,
    String? gradeLetter,
  }) =>
      GradeBadge(
        key: key,
        percentage: percentage,
        gradeLetter: gradeLetter,
        size: _GradeBadgeSize.large,
      );

  Color get _color {
    if (percentage >= 90) return const Color(0xFF059669);
    if (percentage >= 75) return AppColors.successGreen;
    if (percentage >= 60) return AppColors.infoBlue;
    if (percentage >= 40) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  Color get _bg {
    if (percentage >= 90) return const Color(0xFFD1FAE5);
    if (percentage >= 75) return AppColors.successLight;
    if (percentage >= 60) return AppColors.infoLight;
    if (percentage >= 40) return AppColors.warningLight;
    return AppColors.errorLight;
  }

  String get _label {
    if (gradeLetter != null && gradeLetter!.isNotEmpty) return gradeLetter!;
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  double get _fontSize {
    switch (size) {
      case _GradeBadgeSize.small:
        return 10;
      case _GradeBadgeSize.medium:
        return 12;
      case _GradeBadgeSize.large:
        return 18;
    }
  }

  EdgeInsets get _padding {
    switch (size) {
      case _GradeBadgeSize.small:
        return const EdgeInsets.symmetric(horizontal: 7, vertical: 3);
      case _GradeBadgeSize.medium:
        return const EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      case _GradeBadgeSize.large:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  double get _borderRadius {
    switch (size) {
      case _GradeBadgeSize.small:
        return 8;
      case _GradeBadgeSize.medium:
        return 10;
      case _GradeBadgeSize.large:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(_borderRadius),
        border: Border.all(color: _color.withValues(alpha: 0.35), width: 1.2),
        boxShadow: size == _GradeBadgeSize.large
            ? [
                BoxShadow(
                  color: _color.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Text(
        _label,
        style: AppTypography.labelMedium.copyWith(
          color: _color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

enum _GradeBadgeSize { small, medium, large }
