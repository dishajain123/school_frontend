import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../providers/parent_provider.dart';

class ChildSelector extends ConsumerWidget {
  const ChildSelector({
    super.key,
    required this.childrenAsync,
    required this.onSelectChild,
    required this.onAddChild,
  });

  final AsyncValue<ChildrenState> childrenAsync;
  final void Function(String childId) onSelectChild;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = childrenAsync.valueOrNull ?? const ChildrenState();
    final children = state.children;
    final selected = state.selectedChildId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.surface100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.child_care_rounded, size: 15, color: AppColors.navyDeep),
              ),
              const SizedBox(width: 8),
              Text(
                'Child Profile',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onAddChild,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_add_alt_1_rounded, size: 12, color: AppColors.navyMedium),
                      const SizedBox(width: 4),
                      Text(
                        'Add Child',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.navyMedium,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (childrenAsync.isLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 2),
          ] else if (children.isEmpty) ...[
            const SizedBox(height: 10),
            _EmptyChildState(onAddChild: onAddChild),
          ] else ...[
            const SizedBox(height: 10),
            _ChildDropdown(
              children: children,
              selected: selected ?? children.first.id,
              onChanged: onSelectChild,
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyChildState extends StatelessWidget {
  const _EmptyChildState({required this.onAddChild});
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAddChild,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Column(
          children: [
            const Icon(Icons.person_add_outlined,
                size: 22, color: AppColors.grey400),
            const SizedBox(height: 5),
            Text('No child linked yet',
                style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
            const SizedBox(height: 2),
            Text('Tap to add a child',
                style: AppTypography.caption.copyWith(
                    color: AppColors.navyMedium, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _ChildDropdown extends StatelessWidget {
  const _ChildDropdown({required this.children, required this.selected, required this.onChanged});

  final List<ChildSummaryModel> children;
  final String selected;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('child-$selected'),
        initialValue: selected,
        items: children
            .map(
              (child) => DropdownMenuItem<String>(
                value: child.id,
                child: Text(
                  child.section != null && child.section!.trim().isNotEmpty
                      ? '${child.admissionNumber}  ·  Sec ${child.section}'
                      : child.admissionNumber,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        decoration: const InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 11),
          labelText: 'Select Child',
        ),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey400, size: 20),
        isExpanded: true,
        dropdownColor: AppColors.white,
      ),
    );
  }
}
