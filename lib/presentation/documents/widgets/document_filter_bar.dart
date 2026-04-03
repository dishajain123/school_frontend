import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';

/// Horizontal scrollable chip row for filtering documents by status.
/// "All" chip shown first; tapping a selected chip deselects it.
class DocumentFilterBar extends StatelessWidget {
  const DocumentFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DocumentStatus? selected;
  final ValueChanged<DocumentStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // All chip
          _Chip(
            label: 'All',
            icon: Icons.list_rounded,
            isSelected: selected == null,
            color: AppColors.navyDeep,
            onTap: () => onSelected(null),
          ),
          const SizedBox(width: AppDimensions.space8),

          // Status chips
          ...DocumentStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: _Chip(
                label: s.label,
                icon: s.icon,
                isSelected: selected == s,
                color: s.color,
                onTap: () => onSelected(selected == s ? null : s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          border: Border.all(
            color: isSelected ? color : AppColors.surface200,
            width: AppDimensions.borderThin,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? AppColors.white : color,
            ),
            const SizedBox(width: AppDimensions.space4),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.grey600,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}