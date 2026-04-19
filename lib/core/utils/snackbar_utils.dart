import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_typography.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.successGreen,
      icon: Icons.check_circle_outline_rounded,
      duration: const Duration(
        milliseconds: AppConstants.snackbarSuccessDurationMs,
      ),
    );
  }

  static void showError(BuildContext context, String message, {VoidCallback? onRetry}) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.errorRed,
      icon: Icons.error_outline_rounded,
      duration: const Duration(
        milliseconds: AppConstants.snackbarErrorDurationMs,
      ),
      action: onRetry != null
          ? SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      backgroundColor: AppColors.navyMedium,
      icon: Icons.info_outline_rounded,
      duration: const Duration(
        milliseconds: AppConstants.snackbarInfoDurationMs,
      ),
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          margin: const EdgeInsets.all(AppDimensions.spacingMd),
          duration: duration,
          action: action,
        ),
      );
  }
}
