import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';

/// Displays a percentage-based grade badge with semantic colour.
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
    if (percentage >= 90) return const Color(0xFF059669); // emerald
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
        return 16;
    }
  }

  double get _padding {
    switch (size) {
      case _GradeBadgeSize.small:
        return 6;
      case _GradeBadgeSize.medium:
        return 8;
      case _GradeBadgeSize.large:
        return 12;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _padding, vertical: _padding / 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: _fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _GradeBadgeSize { small, medium, large }