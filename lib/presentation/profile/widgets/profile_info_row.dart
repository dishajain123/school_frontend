import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onEdit;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, size: AppDimensions.iconSM, color: AppColors.grey600),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onEdit != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: AppDimensions.iconSM, color: AppColors.grey400),
              onPressed: onEdit,
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}