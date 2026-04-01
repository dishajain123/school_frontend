import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/notification/notification_model.dart';

class NotificationFilterBar extends StatelessWidget {
  const NotificationFilterBar({
    super.key,
    this.selectedType,
    this.selectedRead,
    required this.onFilterChanged,
  });

  final String? selectedType;
  final bool? selectedRead;
  final void Function(String? type, bool? isRead) onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final filters = [
      _FilterChip(label: 'All', typeValue: null, readValue: null),
      _FilterChip(label: 'Unread', typeValue: null, readValue: false),
      _FilterChip(label: 'Attendance', typeValue: 'ATTENDANCE', readValue: null),
      _FilterChip(label: 'Assignment', typeValue: 'ASSIGNMENT', readValue: null),
      _FilterChip(label: 'Fee', typeValue: 'FEE', readValue: null),
      _FilterChip(label: 'Result', typeValue: 'RESULT', readValue: null),
      _FilterChip(label: 'Leave', typeValue: 'LEAVE', readValue: null),
      _FilterChip(label: 'Announcement', typeValue: 'ANNOUNCEMENT', readValue: null),
    ];

    return Container(
      height: 48,
      color: AppColors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedType == filter.typeValue &&
              selectedRead == filter.readValue;
          return GestureDetector(
            onTap: () => onFilterChanged(filter.typeValue, filter.readValue),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space4,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDeep : AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                filter.label,
                style: AppTypography.labelMedium.copyWith(
                  color:
                      isSelected ? AppColors.white : AppColors.grey800,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip {
  const _FilterChip({
    required this.label,
    required this.typeValue,
    required this.readValue,
  });
  final String label;
  final String? typeValue;
  final bool? readValue;
}