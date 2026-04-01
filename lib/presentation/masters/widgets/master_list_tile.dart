import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class MasterListTile extends StatelessWidget {
  const MasterListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.onEdit,
    this.onDelete,
    this.isLast = false,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isLast;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100, width: 1),
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppDimensions.space12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyLight.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(
                            badge!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.navyMedium,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppDimensions.space4),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: AppDimensions.space8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.navyMedium,
                      onTap: onEdit!,
                      tooltip: 'Edit',
                    ),
                  if (onDelete != null) ...[
                    const SizedBox(width: AppDimensions.space4),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.errorRed,
                      onTap: onDelete!,
                      tooltip: 'Delete',
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Icon(icon, size: AppDimensions.iconSM, color: color),
        ),
      ),
    );
  }
}