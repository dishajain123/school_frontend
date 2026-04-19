import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/auth/current_user.dart';
import '../../../../data/models/leave/leave_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/leave_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/leave_request_card.dart';

class LeaveListScreen extends ConsumerStatefulWidget {
  const LeaveListScreen({super.key});

  @override
  ConsumerState<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends ConsumerState<LeaveListScreen>
    with TickerProviderStateMixin {
  late TabController _principalTabController;
  late TabController _teacherTabController;

  @override
  void initState() {
    super.initState();
    _principalTabController = TabController(length: 4, vsync: this);
    _teacherTabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLoad());
  }

  @override
  void dispose() {
    _principalTabController.dispose();
    _teacherTabController.dispose();
    super.dispose();
  }

  void _initLoad() {
    ref.read(leaveNotifierProvider.notifier).load(
          statusFilter: null,
          refresh: true,
        );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isPrincipal =
        user?.role == UserRole.principal || user?.role == UserRole.trustee;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Leave Requests',
        showBack: true,
        actions: [
          if (!isPrincipal)
            IconButton(
              icon: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.white,
              ),
              tooltip: 'Leave Balance',
              onPressed: () => context.push(RouteNames.leaveBalance),
            ),
        ],
        bottom: isPrincipal
            ? TabBar(
                controller: _principalTabController,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
                ],
              )
            : TabBar(
                controller: _teacherTabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
                ],
              ),
      ),
      floatingActionButton: !isPrincipal
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.applyLeave),
              tooltip: 'Apply Leave',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: isPrincipal
          ? TabBarView(
              controller: _principalTabController,
              children: const [
                _LeaveListView(
                  statusFilter: null,
                  isPrincipal: true,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.pending,
                  isPrincipal: true,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.approved,
                  isPrincipal: true,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.rejected,
                  isPrincipal: true,
                ),
              ],
            )
          : TabBarView(
              controller: _teacherTabController,
              children: const [
                _LeaveListView(
                  statusFilter: null,
                  isPrincipal: false,
                  showFilterChips: false,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.pending,
                  isPrincipal: false,
                  showFilterChips: false,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.approved,
                  isPrincipal: false,
                  showFilterChips: false,
                ),
                _LeaveListView(
                  statusFilter: LeaveStatus.rejected,
                  isPrincipal: false,
                  showFilterChips: false,
                ),
              ],
            ),
    );
  }
}

// ── Leave List View ───────────────────────────────────────────────────────────

class _LeaveListView extends ConsumerStatefulWidget {
  const _LeaveListView({
    this.statusFilter,
    required this.isPrincipal,
    this.showFilterChips = true,
  });

  final LeaveStatus? statusFilter;
  final bool isPrincipal;
  final bool showFilterChips;

  @override
  ConsumerState<_LeaveListView> createState() => _LeaveListViewState();
}

class _LeaveListViewState extends ConsumerState<_LeaveListView> {
  LeaveStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.statusFilter;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaveNotifierProvider);

    return state.when(
      loading: () => AppLoading.listView(count: 5, withAvatar: false),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref
            .read(leaveNotifierProvider.notifier)
            .load(statusFilter: null, refresh: true),
      ),
      data: (leaveState) {
        if (leaveState.isLoading && leaveState.items.isEmpty) {
          return AppLoading.listView(count: 5, withAvatar: false);
        }

        final effectiveFilter =
            widget.showFilterChips ? _activeFilter : widget.statusFilter;
        final items = leaveState.items.where((l) {
          if (effectiveFilter == null) return true;
          return l.status == effectiveFilter;
        }).toList();

        return RefreshIndicator(
          color: AppColors.navyDeep,
          onRefresh: () => ref
              .read(leaveNotifierProvider.notifier)
              .load(statusFilter: null, refresh: true),
          child: CustomScrollView(
            slivers: [
              // Filter chips (teacher view only)
              if (!widget.isPrincipal && widget.showFilterChips)
                SliverToBoxAdapter(
                  child: _FilterChipRow(
                    selected: _activeFilter,
                    onSelected: (status) {
                      setState(() => _activeFilter = status);
                    },
                  ),
                ),

              if (leaveState.error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: AppDimensions.space8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall,
                        ),
                      ),
                      child: Text(
                        leaveState.error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.errorDark,
                        ),
                      ),
                    ),
                  ),
                ),

              // Empty state
              if (items.isEmpty)
                SliverFillRemaining(
                  child: AppEmptyState(
                    icon: Icons.beach_access_outlined,
                    title: widget.isPrincipal
                        ? 'No leave requests'
                        : 'No leaves applied',
                    subtitle: widget.isPrincipal
                        ? 'There are no leave requests to review.'
                        : 'Tap the + button to apply for leave.',
                    iconColor: AppColors.grey400,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    AppDimensions.space8,
                    AppDimensions.space16,
                    AppDimensions.pageBottomScroll,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final leave = items[index];
                      return LeaveRequestCard(
                        leave: leave,
                        showTeacherLabel: widget.isPrincipal,
                        teacherLabel: widget.isPrincipal
                            ? 'Teacher ID: ${leave.teacherId.substring(0, 8)}…'
                            : null,
                        onTap: leave.isPending && widget.isPrincipal
                            ? () => context.push(
                                  RouteNames.leaveDecisionPath(leave.id),
                                  extra: leave,
                                )
                            : null,
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Filter Chip Row (teacher view) ────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({
    required this.selected,
    required this.onSelected,
  });

  final LeaveStatus? selected;
  final ValueChanged<LeaveStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        AppDimensions.space8,
      ),
      child: Row(
        children: [
          AppChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelected(null),
            small: true,
          ),
          const SizedBox(width: AppDimensions.space8),
          ...LeaveStatus.values.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: AppChip(
                label: s.label,
                isSelected: selected == s,
                onTap: () => onSelected(s),
                small: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
