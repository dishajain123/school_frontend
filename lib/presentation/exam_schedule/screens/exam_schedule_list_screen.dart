import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_series_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';

// NOTE: Since there is no list-series endpoint in the backend spec, the list
// screen acts as a selector: choose a standard, then input a series ID to view.
// When FM19 gets a list endpoint in the future this can be updated.
// For now, the list screen lets the user navigate into the table screen.

class ExamScheduleListScreen extends ConsumerStatefulWidget {
  const ExamScheduleListScreen({super.key});

  @override
  ConsumerState<ExamScheduleListScreen> createState() =>
      _ExamScheduleListScreenState();
}

class _ExamScheduleListScreenState
    extends ConsumerState<ExamScheduleListScreen> {
  String? _selectedStandardId;

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final standardsAsync = ref.watch(standardsProvider(null));
    final canCreate = currentUser?.hasPermission('exam_schedule:create') ?? false;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Exam Schedules',
        actions: canCreate
            ? [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Create Series',
                  onPressed: _selectedStandardId != null
                      ? () => context.push(
                            RouteNames.createExamSeries,
                            extra: {'standard_id': _selectedStandardId},
                          )
                      : null,
                ),
              ]
            : const [],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Standard selector
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: Text(
              'Select Class',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          standardsAsync.when(
            data: (standards) => _StandardChips(
              standards: standards
                  .map((s) => _StandardItem(id: s.id, name: s.name))
                  .toList(),
              selectedId: _selectedStandardId,
              onSelect: (id) => setState(() => _selectedStandardId = id),
            ),
            loading: () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
              child: AppLoading.fullPage(),
            ),
            error: (e, _) => AppErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(standardsProvider(null)),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          if (_selectedStandardId == null)
            Expanded(
              child: AppEmptyState(
                icon: Icons.calendar_month_outlined,
                title: 'Choose a Class',
                subtitle: 'Select a class above to view its exam schedules',
              ),
            )
          else
            Expanded(
              child: _SeriesList(
                standardId: _selectedStandardId!,
                canCreate: canCreate,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Standard chip selector ────────────────────────────────────────────────────

class _StandardItem {
  const _StandardItem({required this.id, required this.name});
  final String id;
  final String name;
}

class _StandardChips extends StatelessWidget {
  const _StandardChips({
    required this.standards,
    required this.selectedId,
    required this.onSelect,
  });

  final List<_StandardItem> standards;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16),
        itemCount: standards.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, index) {
          final s = standards[index];
          final selected = s.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(s.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space12),
              decoration: BoxDecoration(
                color: selected ? AppColors.navyDeep : Colors.transparent,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: selected
                      ? AppColors.navyDeep
                      : AppColors.surface200,
                ),
              ),
              child: Center(
                child: Text(
                  s.name,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected ? Colors.white : AppColors.grey600,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Series list for selected standard ────────────────────────────────────────

// Since the backend does not expose a "list series by standard" endpoint,
// we show a prompt to enter a series ID or navigate to create one.
// Real implementations can swap this out if a list endpoint is added.
class _SeriesList extends StatelessWidget {
  const _SeriesList({
    required this.standardId,
    required this.canCreate,
  });

  final String standardId;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canCreate)
            _ActionCard(
              icon: Icons.add_circle_outline,
              title: 'Create New Exam Series',
              subtitle: 'Set up exam dates and subjects for this class',
              color: AppColors.navyDeep,
              onTap: () => context.push(
                RouteNames.createExamSeries,
                extra: {'standard_id': standardId},
              ),
            ),
          const SizedBox(height: AppDimensions.space12),
          _ActionCard(
            icon: Icons.table_chart_outlined,
            title: 'View Exam Schedule',
            subtitle: 'Browse published and draft exam series',
            color: AppColors.infoBlue,
            onTap: () => context.push(
              RouteNames.examScheduleTable,
              extra: {'standard_id': standardId},
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
