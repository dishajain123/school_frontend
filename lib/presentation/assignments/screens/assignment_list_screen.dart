import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../widgets/assignment_card.dart';

class AssignmentListScreen extends ConsumerStatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  ConsumerState<AssignmentListScreen> createState() =>
      _AssignmentListScreenState();
}

class _AssignmentListScreenState extends ConsumerState<AssignmentListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _scrollCtrl = ScrollController();
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  String _activeFilter = 'all';
  String? _selectedClassKey;
  String? _selectedScopedSubjectId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _scrollCtrl.addListener(_onScroll);
    _autoRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => ref.read(assignmentsProvider.notifier).refresh(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyTabFilter(0));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _scrollCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(assignmentsProvider.notifier).refresh();
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(assignmentsProvider.notifier).loadMore();
    }
  }

  void _applyTabFilter(int index) {
    setState(
        () => _activeFilter = ['all', 'active', 'overdue', 'submitted'][index]);
    final role = ref.read(currentUserProvider)?.role;
    final isStudent = role == UserRole.student;
    final isParent = role == UserRole.parent;
    final selectedChild = isParent ? ref.read(selectedChildProvider) : null;
    final filters = _buildFiltersForCurrentState(
      indexOverride: index,
      scopedSubjectId:
          (isStudent || isParent) ? _selectedScopedSubjectId : null,
      scopedStandardId: isParent ? selectedChild?.standardId : null,
    );
    ref.read(assignmentsProvider.notifier).applyFilters(filters);
  }

  AssignmentFilters _buildFiltersForCurrentState({
    int? indexOverride,
    String? scopedSubjectId,
    String? scopedStandardId,
  }) {
    final index = indexOverride ?? _tabController.index;
    final selectedStandardId =
        _selectedClassKey?.split('|').first ?? scopedStandardId;
    return switch (index) {
      1 => AssignmentFilters(
          standardId: selectedStandardId,
          subjectId: scopedSubjectId,
          isActive: true,
          isOverdue: false,
        ),
      2 => AssignmentFilters(
          standardId: selectedStandardId,
          subjectId: scopedSubjectId,
          isActive: true,
          isOverdue: true,
        ),
      3 => AssignmentFilters(
          standardId: selectedStandardId,
          subjectId: scopedSubjectId,
          isSubmitted: true,
        ),
      _ => AssignmentFilters(
          standardId: selectedStandardId,
          subjectId: scopedSubjectId,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canCreate = currentUser?.hasPermission('assignment:create') ?? false;
    final canGrade = currentUser?.hasPermission('submission:grade') ?? false;
    final canViewSubmissions =
        canGrade || currentUser?.role == UserRole.teacher;
    final isTeacher = currentUser?.role == UserRole.teacher;
    final isStudent = currentUser?.role == UserRole.student;
    final isParent = currentUser?.role == UserRole.parent;
    final selectedChild = isParent ? ref.watch(selectedChildProvider) : null;
    final parentStandardId = selectedChild?.standardId;
    final activeYear = ref.watch(activeYearProvider);
    final teacherAssignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));
    AsyncValue<dynamic> studentProfileAsync = const AsyncData(null);
    if (isStudent) {
      studentProfileAsync = ref.watch(myStudentProfileProvider);
    }
    final studentStandardId =
        (studentProfileAsync.valueOrNull as dynamic)?.standardId as String?;
    final scopedStandardId = isStudent ? studentStandardId : parentStandardId;
    AsyncValue<List<dynamic>> scopedSubjectsAsync = const AsyncData(<dynamic>[]);
    if ((isStudent || isParent) &&
        scopedStandardId != null &&
        scopedStandardId.isNotEmpty) {
      scopedSubjectsAsync = ref.watch(subjectsProvider(scopedStandardId));
    }

    final classOptions = <_ClassOption>[];
    final classOptionKeys = <String>{};
    if (isTeacher) {
      teacherAssignmentsAsync.whenData((assignments) {
        for (final a in assignments) {
          final key = '${a.standardId}|${a.section.trim()}';
          if (classOptionKeys.add(key)) {
            classOptions.add(
              _ClassOption(
                key: key,
                standardId: a.standardId,
                label: a.classLabel,
              ),
            );
          }
        }
      });
      final hasSelected =
          _selectedClassKey == null || classOptionKeys.contains(_selectedClassKey);
      if (!hasSelected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedClassKey = null);
          ref
              .read(assignmentsProvider.notifier)
              .applyFilters(_buildFiltersForCurrentState(
                scopedSubjectId: null,
                scopedStandardId: scopedStandardId,
              ));
        });
      }
    }
    final scopedSubjectOptions = <String, String>{};
    if (isStudent || isParent) {
      final subjects = (scopedSubjectsAsync.valueOrNull ?? const <dynamic>[]);
      for (final subject in subjects) {
        final id = (subject.id as String?)?.trim();
        final name = (subject.name as String?)?.trim();
        if (id != null && id.isNotEmpty && name != null && name.isNotEmpty) {
          scopedSubjectOptions[id] = name;
        }
      }
      if (_selectedScopedSubjectId != null &&
          !scopedSubjectOptions.containsKey(_selectedScopedSubjectId)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedScopedSubjectId = null);
          ref.read(assignmentsProvider.notifier).applyFilters(
                _buildFiltersForCurrentState(
                  scopedSubjectId: null,
                  scopedStandardId: scopedStandardId,
                ),
              );
        });
      }
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Assignments',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
        bottom: TabBar(
          controller: _tabController,
          onTap: _applyTabFilter,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.55),
          indicatorColor: AppColors.goldPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle:
              AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
            Tab(text: 'Submitted'),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? _PremiumFab(
              onTap: () async {
                await context.push(RouteNames.createAssignment);
                if (!mounted) return;
                await ref.read(assignmentsProvider.notifier).refresh();
              },
            )
          : null,
      body: Column(
        children: [
          if (isTeacher && classOptions.isNotEmpty)
            _TeacherClassFilterBar(
              classOptions: classOptions,
              selectedClassKey: _selectedClassKey,
              onSelect: (classKey) {
                setState(() => _selectedClassKey = classKey);
                ref
                    .read(assignmentsProvider.notifier)
                    .applyFilters(_buildFiltersForCurrentState(
                      scopedSubjectId: null,
                      scopedStandardId: null,
                    ));
              },
            ),
          if ((isStudent || isParent) && scopedSubjectOptions.isNotEmpty)
            _StudentSubjectFilterBar(
              subjectOptions: scopedSubjectOptions,
              selectedSubjectId: _selectedScopedSubjectId,
              onSelect: (subjectId) {
                setState(() => _selectedScopedSubjectId = subjectId);
                ref.read(assignmentsProvider.notifier).applyFilters(
                      _buildFiltersForCurrentState(
                        scopedSubjectId: _selectedScopedSubjectId,
                        scopedStandardId: scopedStandardId,
                      ),
                    );
              },
            ),
          Expanded(
            child: assignmentsState.when(
              loading: () => _buildShimmer(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.read(assignmentsProvider.notifier).refresh(),
              ),
              data: (state) {
                final filtered = switch (_activeFilter) {
                  'active' =>
                    state.items.where((a) => a.isActive && !a.isOverdue).toList(),
                  'overdue' =>
                    state.items.where((a) => a.isActive && a.isOverdue).toList(),
                  'submitted' => state.items,
                  _ => state.items,
                };

                if (filtered.isEmpty && !state.isLoadingMore) {
                  return AppEmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'No assignments',
                    subtitle: _activeFilter == 'overdue'
                        ? "You're all caught up — no overdue assignments."
                        : _activeFilter == 'submitted'
                            ? 'No submitted assignments found yet.'
                            : canCreate
                                ? 'Tap + to create the first assignment.'
                                : 'No assignments have been posted yet.',
                    actionLabel: canCreate ? 'Create Assignment' : null,
                    onAction: canCreate
                        ? () async {
                            await context.push(RouteNames.createAssignment);
                            if (!mounted) return;
                            await ref.read(assignmentsProvider.notifier).refresh();
                          }
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(assignmentsProvider.notifier).refresh(),
                  color: AppColors.navyDeep,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.navyDeep),
                          ),
                        );
                      }
                      final assignment = filtered[index];
                      return AssignmentCard(
                        assignment: assignment,
                        onTap: () =>
                            context.push(RouteNames.assignmentDetailPath(assignment.id)),
                        showSubmissionAction: canViewSubmissions,
                        onViewSubmissions: canViewSubmissions
                            ? () => context
                                .push(RouteNames.submissionListPath(assignment.id))
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AppLoading.card(height: 120),
      ),
    );
  }
}

class _TeacherClassFilterBar extends StatelessWidget {
  const _TeacherClassFilterBar({
    required this.classOptions,
    required this.selectedClassKey,
    required this.onSelect,
  });

  final List<_ClassOption> classOptions;
  final String? selectedClassKey;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ClassFilterChip(
              label: 'All Classes',
              selected: selectedClassKey == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: 8),
            ...classOptions.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ClassFilterChip(
                  label: entry.label,
                  selected: selectedClassKey == entry.key,
                  onTap: () => onSelect(entry.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassOption {
  const _ClassOption({
    required this.key,
    required this.standardId,
    required this.label,
  });

  final String key;
  final String standardId;
  final String label;
}

class _StudentSubjectFilterBar extends StatelessWidget {
  const _StudentSubjectFilterBar({
    required this.subjectOptions,
    required this.selectedSubjectId,
    required this.onSelect,
  });

  final Map<String, String> subjectOptions;
  final String? selectedSubjectId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ClassFilterChip(
              label: 'All Subjects',
              selected: selectedSubjectId == null,
              onTap: () => onSelect(null),
            ),
            const SizedBox(width: 8),
            ...subjectOptions.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ClassFilterChip(
                  label: entry.value,
                  selected: selectedSubjectId == entry.key,
                  onTap: () => onSelect(entry.key),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassFilterChip extends StatelessWidget {
  const _ClassFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.navyDeep.withValues(alpha: 0.12)
              : AppColors.surface50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.navyDeep.withValues(alpha: 0.35)
                : AppColors.surface200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.navyDeep : AppColors.grey700,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PremiumFab extends StatefulWidget {
  const _PremiumFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_PremiumFab> createState() => _PremiumFabState();
}

class _PremiumFabState extends State<_PremiumFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A5F), Color(0xFF0F2340)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child:
              const Icon(Icons.add_rounded, color: AppColors.white, size: 24),
        ),
      ),
    );
  }
}
