import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Full-page error state shown when initial data load fails.
///
/// For transient errors on already-loaded screens, use a snackbar instead.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final String? message;
  final VoidCallback? onRetry;

  /// Compact mode for inline error within a card or section.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact
        ? AppDimensions.iconXL
        : AppDimensions.iconXL + AppDimensions.iconXS;

    final effectiveMessage = message?.isNotEmpty == true
        ? message!
        : 'Something went wrong. Please try again.';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimensions.space32,
          vertical: compact
              ? AppDimensions.space16
              : AppDimensions.space48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: iconSize,
              color: AppColors.errorRed.withValues(alpha: 0.6),
            ),
            SizedBox(
              height: compact
                  ? AppDimensions.space12
                  : AppDimensions.space20,
            ),
            Text(
              'Something went wrong',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              effectiveMessage,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.space24),
              AppButton.secondary(
                label: 'Try Again',
                onTap: onRetry,
                fullWidth: false,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}