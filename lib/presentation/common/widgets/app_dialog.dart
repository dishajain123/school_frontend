import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'app_button.dart';

class AppDialog extends StatelessWidget {
  const AppDialog._({
    super.key,
    required this.title,
    required this.message,
    required this.variant,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.icon,
    this.iconColor,
    this.content,
  });

  final String title;
  final String message;
  final _DialogVariant variant;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? iconColor;
  final Widget? content;

  static Future<bool?> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => AppDialog._(
        title: title,
        message: message,
        variant: _DialogVariant.confirm,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
      ),
    );
  }

  static Future<void> info(
    BuildContext context, {
    required String title,
    required String message,
    String okLabel = 'OK',
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => AppDialog._(
        title: title,
        message: message,
        variant: _DialogVariant.info,
        confirmLabel: okLabel,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }

  static Future<bool?> destructive(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => AppDialog._(
        title: title,
        message: message,
        variant: _DialogVariant.destructive,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon ?? Icons.delete_outline_rounded,
        iconColor: AppColors.errorRed,
      ),
    );
  }

  static Future<T?> custom<T>(
    BuildContext context, {
    required String title,
    required Widget content,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => AppDialog._(
        title: title,
        message: '',
        variant: _DialogVariant.custom,
        confirmLabel: confirmLabel ?? 'OK',
        cancelLabel: cancelLabel ?? 'Cancel',
        onConfirm: onConfirm,
        onCancel: onCancel,
        content: content,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.navyDeep)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? AppColors.navyDeep,
                  size: 22,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
            ],
            Text(
              title,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            if (variant == _DialogVariant.custom && content != null) ...[
              const SizedBox(height: AppDimensions.space12),
              content!,
            ] else if (message.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space8),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.grey600,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppDimensions.space24),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    switch (variant) {
      case _DialogVariant.info:
        return SizedBox(
          width: double.infinity,
          child: AppButton.primary(
            label: confirmLabel,
            onTap: () {
              onConfirm?.call();
              Navigator.of(context).pop();
            },
          ),
        );

      case _DialogVariant.confirm:
        return Row(
          children: [
            Expanded(
              child: AppButton.secondary(
                label: cancelLabel,
                onTap: () {
                  onCancel?.call();
                  Navigator.of(context).pop(false);
                },
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: AppButton.primary(
                label: confirmLabel,
                onTap: () {
                  onConfirm?.call();
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        );

      case _DialogVariant.destructive:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppButton.destructive(
              label: confirmLabel,
              onTap: () {
                onConfirm?.call();
                Navigator.of(context).pop(true);
              },
            ),
            const SizedBox(height: AppDimensions.space8),
            AppButton.text(
              label: cancelLabel,
              onTap: () {
                onCancel?.call();
                Navigator.of(context).pop(false);
              },
              fullWidth: true,
            ),
          ],
        );

      case _DialogVariant.custom:
        return Row(
          children: [
            if (onCancel != null || cancelLabel.isNotEmpty) ...[
              Expanded(
                child: AppButton.secondary(
                  label: cancelLabel,
                  onTap: () {
                    onCancel?.call();
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
            ],
            Expanded(
              child: AppButton.primary(
                label: confirmLabel,
                onTap: () {
                  onConfirm?.call();
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        );
    }
  }
}

enum _DialogVariant { confirm, info, destructive, custom }