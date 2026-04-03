import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/behaviour/behaviour_log_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/behaviour_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/behaviour_log_tile.dart';

class BehaviourLogListScreen extends ConsumerStatefulWidget {
  const BehaviourLogListScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<BehaviourLogListScreen> createState() =>
      _BehaviourLogListScreenState();
}

class _BehaviourLogListScreenState
    extends ConsumerState<BehaviourLogListScreen> {
  IncidentType? _incidentFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user?.role == UserRole.parent) {
        await ref.read(childrenNotifierProvider.notifier).loadMyChildren();
      }
    });
  }

  String? _resolveStudentId() {
    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      return widget.studentId;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    if (user.role == UserRole.parent) {
      return ref.read(selectedChildIdProvider);
    }
    if (user.role == UserRole.student) {
      return user.id;
    }
    return null;
  }

  List<BehaviourLogModel> _applyFilter(List<BehaviourLogModel> items) {
    if (_incidentFilter == null) return items;
    return items.where((log) => log.incidentType == _incidentFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final studentId = _resolveStudentId();
    final user = ref.watch(currentUserProvider);
    final canCreate = user?.hasPermission('behaviour_log:create') ?? false;

    if (studentId == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Behaviour Log', showBack: true),
        body: AppEmptyState(
          icon: Icons.person_search_outlined,
          title: 'No student selected',
          subtitle: 'Open this page from a student profile to view logs.',
        ),
      );
    }

    final logsAsync = ref.watch(behaviourLogsProvider(studentId));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Behaviour Log',
        showBack: true,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(
                RouteNames.createBehaviourLogPath(studentId: studentId),
              ),
              backgroundColor: AppColors.goldPrimary,
              tooltip: 'Create Behaviour Log',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async {
          ref.invalidate(behaviourLogsProvider(studentId));
          await ref.read(behaviourLogsProvider(studentId).future);
        },
        child: logsAsync.when(
          loading: () => AppLoading.listView(count: 6, withAvatar: false),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(behaviourLogsProvider(studentId)),
          ),
          data: (response) {
            final filtered = _applyFilter(response.items);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _BehaviourFilterRow(
                    selected: _incidentFilter,
                    onSelected: (type) {
                      setState(() => _incidentFilter = type);
                    },
                  ),
                ),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.fact_check_outlined,
                      title: 'No behaviour entries',
                      subtitle: _incidentFilter == null
                          ? 'No incidents logged for this student yet.'
                          : 'No ${_incidentFilter!.label.toLowerCase()} incidents found.',
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
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimensions.space12),
                      itemBuilder: (_, index) {
                        final log = filtered[index];
                        return BehaviourLogTile(log: log);
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BehaviourFilterRow extends StatelessWidget {
  const _BehaviourFilterRow({
    required this.selected,
    required this.onSelected,
  });

  final IncidentType? selected;
  final ValueChanged<IncidentType?> onSelected;

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
          ...IncidentType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: AppChip(
                label: type.label,
                icon: type.icon,
                isSelected: selected == type,
                onTap: () => onSelected(type),
                selectedColor: type.color,
                small: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
