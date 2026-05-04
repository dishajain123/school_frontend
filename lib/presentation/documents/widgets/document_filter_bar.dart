import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';

/// Chips for GET /documents `status_filter` workflow buckets (matches backend).
class DocumentFilterBar extends StatelessWidget {
  const DocumentFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final DocumentWorkflowFilter selected;
  final ValueChanged<DocumentWorkflowFilter> onSelected;

  static const List<DocumentWorkflowFilter> _options = [
    DocumentWorkflowFilter.all,
    DocumentWorkflowFilter.requested,
    DocumentWorkflowFilter.pending,
    DocumentWorkflowFilter.approved,
    DocumentWorkflowFilter.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _options.length; i++) ...[
            if (i > 0) const SizedBox(width: AppDimensions.space8),
            _Chip(
              label: _options[i].label,
              icon: _options[i].icon,
              isSelected: selected == _options[i],
              color: _options[i].color,
              onTap: () => onSelected(
                selected == _options[i]
                    ? DocumentWorkflowFilter.all
                    : _options[i],
              ),
            ),
          ],
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
