import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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

  static const _filters = [
    _FilterItem(label: 'All', icon: Icons.inbox_outlined, typeValue: null, readValue: null),
    _FilterItem(label: 'Unread', icon: Icons.mark_email_unread_outlined, typeValue: null, readValue: false),
    _FilterItem(label: 'Attendance', icon: Icons.fact_check_outlined, typeValue: 'ATTENDANCE', readValue: null),
    _FilterItem(label: 'Assignment', icon: Icons.assignment_outlined, typeValue: 'ASSIGNMENT', readValue: null),
    _FilterItem(label: 'Fee', icon: Icons.account_balance_wallet_outlined, typeValue: 'FEE', readValue: null),
    _FilterItem(label: 'Result', icon: Icons.analytics_outlined, typeValue: 'RESULT', readValue: null),
    _FilterItem(label: 'Leave', icon: Icons.beach_access_outlined, typeValue: 'LEAVE', readValue: null),
    _FilterItem(label: 'Announce', icon: Icons.campaign_outlined, typeValue: 'ANNOUNCEMENT', readValue: null),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = selectedType == filter.typeValue &&
              selectedRead == filter.readValue;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onFilterChanged(filter.typeValue, filter.readValue),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 13,
                      color: isSelected ? AppColors.white : AppColors.grey500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter.label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? AppColors.white : AppColors.grey600,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterItem {
  const _FilterItem({
    required this.label,
    required this.icon,
    required this.typeValue,
    required this.readValue,
  });

  final String label;
  final IconData icon;
  final String? typeValue;
  final bool? readValue;
}