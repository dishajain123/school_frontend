import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart'; // myTeacherAssignmentsProvider
import '../../../providers/auth_provider.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/diary_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/diary_entry_card.dart';

class DiaryListScreen extends ConsumerStatefulWidget {
  const DiaryListScreen({super.key});

  @override
  ConsumerState<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends ConsumerState<DiaryListScreen> {
  String? _selectedSubjectId;

  Future<void> _navigateToCreate() async {
    final created = await context.push<bool>(RouteNames.createDiary);
    if (created == true && mounted) {
      ref.invalidate(diaryListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isParent = currentUser?.role == UserRole.parent;
    final canCreate = currentUser?.hasPermission('diary:create') ?? false;
    final selectedChild = ref.watch(selectedChildProvider);

    // Load teacher assignments for subject filter + name resolution
    final activeYear = ref.watch(activeYearProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    final params = (
      date: null,
      standardId: isParent ? selectedChild?.standardId : null,
      subjectId: _selectedSubjectId,
      academicYearId: null,
    );
    final diaryAsync = ref.watch(diaryListProvider(params));
    final unfilteredParams = (
      date: null,
      standardId: isParent ? selectedChild?.standardId : null,
      subjectId: null,
      academicYearId: null,
    );
    final diaryAllAsync = ref.watch(diaryListProvider(unfilteredParams));

    final Map<String, String> subjectNameMap = {};
    assignmentsAsync.whenData((assignments) {
      for (final a in assignments) {
        subjectNameMap[a.subjectId] = a.subjectLabel;
      }
    });
    diaryAllAsync.whenData((response) {
      for (final d in response.items) {
        final label = (d.subjectName?.trim().isNotEmpty ?? false)
            ? d.subjectName!.trim()
            : 'Subject';
        subjectNameMap.putIfAbsent(d.subjectId, () => label);
      }
    });
    final subjectOptions = Map<String, String>.from(subjectNameMap);

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Class Diary',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                tooltip: 'Add Diary Entry',
                onPressed: _navigateToCreate,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (subjectOptions.isNotEmpty)
            _SubjectFilterBar(
              subjectOptions: subjectOptions,
              selectedId: _selectedSubjectId,
              onSelected: (id) {
                setState(() {
                  _selectedSubjectId = _selectedSubjectId == id ? null : id;
                });
              },
            ),

          const Divider(height: 1, color: AppColors.surface100),

          // ── Diary list ─────────────────────────────────────────────
          Expanded(
            child: isParent && selectedChild == null
                ? const AppEmptyState(
                    icon: Icons.family_restroom_outlined,
                    title: 'Select Child',
                    subtitle:
                        'Choose a child from dashboard first to view class diary.',
                  )
                : RefreshIndicator(
                    color: AppColors.navyDeep,
                    onRefresh: () async =>
                        ref.invalidate(diaryListProvider(params)),
                    child: diaryAsync.when(
                      loading: () => _DiaryShimmer(),
                      error: (e, _) => AppErrorState(
                        message: e.toString(),
                        onRetry: () =>
                            ref.invalidate(diaryListProvider(params)),
                      ),
                      data: (response) {
                        final items = [...response.items]..sort((a, b) {
                            final byDate = b.date.compareTo(a.date);
                            if (byDate != 0) return byDate;
                            return b.createdAt.compareTo(a.createdAt);
                          });
                        if (items.isEmpty) {
                          return const AppEmptyState(
                            icon: Icons.auto_stories_outlined,
                            title: 'No diary entries found',
                            subtitle:
                                'No diary entries are available for selected filters.',
                          );
                        }
                        return ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(
                            top: AppDimensions.space8,
                            bottom: AppDimensions.space64,
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final entry = items[index];
                            return DiaryEntryCard(
                              diary: entry,
                              subjectName: subjectNameMap[entry.subjectId] ??
                                  entry.subjectName,
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Subject filter bar ────────────────────────────────────────────────────────

class _SubjectFilterBar extends StatelessWidget {
  const _SubjectFilterBar({
    required this.subjectOptions,
    required this.selectedId,
    required this.onSelected,
  });

  final Map<String, String> subjectOptions;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        itemCount: subjectOptions.length,
        itemBuilder: (context, index) {
          final entry = subjectOptions.entries.elementAt(index);
          final isSelected = selectedId == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: FilterChip(
                label: Text(
                  entry.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(entry.key),
                backgroundColor: AppColors.surface50,
                selectedColor: AppColors.navyDeep,
                checkmarkColor: AppColors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface200,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _DiaryShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppDimensions.space8),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space6,
        ),
        child: AppLoading.card(),
      ),
    );
  }
}
