import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/router/route_names.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../widgets/assignment_card.dart';

class AssignmentListScreen extends ConsumerStatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  ConsumerState<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends ConsumerState<AssignmentListScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _scrollCtrl = ScrollController();
  late TabController _tabController;
  Timer? _autoRefreshTimer;
  String _activeFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);
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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(assignmentsProvider.notifier).loadMore();
    }
  }

  void _applyTabFilter(int index) {
    setState(() => _activeFilter = ['all', 'active', 'overdue'][index]);
    final filters = switch (index) {
      1 => const AssignmentFilters(isActive: true, isOverdue: false),
      2 => const AssignmentFilters(isActive: true, isOverdue: true),
      _ => const AssignmentFilters(),
    };
    ref.read(assignmentsProvider.notifier).applyFilters(filters);
  }

  @override
  Widget build(BuildContext context) {
    final assignmentsState = ref.watch(assignmentsProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canCreate = currentUser?.hasPermission('assignment:create') ?? false;
    final canGrade = currentUser?.hasPermission('submission:grade') ?? false;
    final canViewSubmissions = canGrade || currentUser?.role == UserRole.teacher;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Assignments',
        bottom: TabBar(
          controller: _tabController,
          onTap: _applyTabFilter,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.55),
          indicatorColor: AppColors.goldPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          tabs: const [Tab(text: 'All'), Tab(text: 'Active'), Tab(text: 'Overdue')],
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
      body: assignmentsState.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(assignmentsProvider.notifier).refresh(),
        ),
        data: (state) {
          final filtered = switch (_activeFilter) {
            'active' => state.items.where((a) => a.isActive && !a.isOverdue).toList(),
            'overdue' => state.items.where((a) => a.isActive && a.isOverdue).toList(),
            _ => state.items,
          };

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
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyDeep),
                    ),
                  );
                }
                final assignment = filtered[index];
                return AssignmentCard(
                  assignment: assignment,
                  onTap: () => context.push(RouteNames.assignmentDetailPath(assignment.id)),
                  showSubmissionAction: canViewSubmissions,
                  onViewSubmissions: canViewSubmissions
                      ? () => context.push(RouteNames.submissionListPath(assignment.id))
                      : null,
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
      padding: const EdgeInsets.only(top: 8),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AppLoading.card(height: 120),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
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
          child: const Icon(Icons.add_rounded, color: AppColors.white, size: 24),
        ),
      ),
    );
  }
}