import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Status chip that maps backend status enum values to design-system colors.
///
/// Pass any backend status string (e.g. "PENDING", "APPROVED", "ABSENT") and
/// it will automatically apply the correct semantic color and label.
///
/// Uses the same color mappings as [AppColors.statusBackground]/[statusForeground].
class AppStatusChip extends StatelessWidget {
  const AppStatusChip({
    super.key,
    required this.status,
    this.customLabel,
    this.customBg,
    this.customFg,
    this.small = false,
    this.icon,
  });

  /// Backend status string — matched case-insensitively.
  final String status;

  /// Override the displayed label text.
  final String? customLabel;

  final Color? customBg;
  final Color? customFg;

  /// When true, renders at a slightly more compact size.
  final bool small;

  /// Optional icon prepended to the label.
  final IconData? icon;

  String get _label {
    if (customLabel != null) return customLabel!;
    return _humanize(status);
  }

  Color get _bg => customBg ?? AppColors.statusBackground(status);

  Color get _fg => customFg ?? AppColors.statusForeground(status);

  /// Converts "HELD_BACK" → "Held Back", "IN_PROGRESS" → "In Progress", etc.
  static String _humanize(String s) {
    return s
        .split('_')
        .map((w) => w.isEmpty
            ? ''
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final vPad = small ? 3.0 : 4.0;
    final hPad = small ? AppDimensions.space8 : 10.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: AppDimensions.iconXS - 2,
              color: _fg,
            ),
            const SizedBox(width: AppDimensions.space4),
          ],
          Text(
            _label,
            style: (small
                    ? AppTypography.labelSmall
                    : AppTypography.labelSmall.copyWith(fontSize: 11))
                .copyWith(
              color: _fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}