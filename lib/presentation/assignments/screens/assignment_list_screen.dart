import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/assignment/assignment_model.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/academic_year_provider.dart';
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
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  late TabController _tabController;

  // Active filter: null = all, true = active, false = inactive, 'overdue' = overdue
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyTabFilter(0);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(assignmentsProvider.notifier).loadMore();
    }
  }

  void _applyTabFilter(int index) {
    setState(() => _activeFilter = ['all', 'active', 'overdue'][index]);
    final filters = switch (index) {
      1 => const AssignmentFilters(isActive: true),
      2 => const AssignmentFilters(isActive: true), // overdue filtered client-side
      _ => const AssignmentFilters(),
    };
    ref.read(assignmentsProvider.notifier).applyFilters(filters);
  }

  bool _tabFilter(AssignmentModel a) {
    if (_activeFilter == 'overdue') return a.isOverdue && a.isActive;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canCreate =
        currentUser?.hasPermission('assignment:create') ?? false;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Assignments',
        bottom: TabBar(
          controller: _tabController,
          onTap: _applyTabFilter,
          labelColor: AppColors.navyDeep,
          unselectedLabelColor: AppColors.grey400,
          indicatorColor: AppColors.navyDeep,
          indicatorWeight: 2,
          labelStyle: AppTypography.labelLarge,
          unselectedLabelStyle: AppTypography.labelMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Overdue'),
          ],
        ),
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.createAssignment),
              backgroundColor: AppColors.navyDeep,
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
      body: assignmentsState.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(assignmentsProvider.notifier).refresh(),
        ),
        data: (state) {
          final filtered = state.items.where(_tabFilter).toList();

          if (filtered.isEmpty && !state.isLoadingMore) {
            return AppEmptyState(
              icon: Icons.assignment_outlined,
              title: 'No assignments',
              subtitle: _activeFilter == 'overdue'
                  ? "You're all caught up — no overdue assignments."
                  : canCreate
                      ? 'Tap + to create the first assignment.'
                      : 'No assignments have been posted yet.',
              actionLabel: canCreate ? 'Create Assignment' : null,
              onAction: canCreate
                  ? () => context.push(RouteNames.createAssignment)
                  : null,
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(assignmentsProvider.notifier).refresh(),
            color: AppColors.navyDeep,
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filtered.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppDimensions.space16),
                    child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.navyDeep),
                    ),
                  );
                }
                final assignment = filtered[index];
                return AssignmentCard(
                  assignment: assignment,
                  onTap: () => context.push(
                    RouteNames.assignmentDetail,
                    extra: assignment.id,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16, vertical: AppDimensions.space6),
        child: AppLoading.card(),
      ),
    );
  }
}
