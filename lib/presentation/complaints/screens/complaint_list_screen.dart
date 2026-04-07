import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../../providers/complaint_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/complaint_card.dart';

class ComplaintListScreen extends ConsumerStatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  ConsumerState<ComplaintListScreen> createState() =>
      _ComplaintListScreenState();
}

class _ComplaintListScreenState extends ConsumerState<ComplaintListScreen> {
  ComplaintStatus? _activeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complaintNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(complaintNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = (user?.hasPermission('complaint:create') ?? false) &&
        user?.role != UserRole.principal;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Complaints',
        showBack: true,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.createComplaint),
              backgroundColor: AppColors.goldPrimary,
              tooltip: 'Create Complaint',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: complaintsAsync.when(
        loading: () => AppLoading.listView(count: 6, withAvatar: false),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(complaintNotifierProvider.notifier).load(),
        ),
        data: (state) {
          final items = user?.role == UserRole.principal
              ? state.items
                  .where((c) => c.status != ComplaintStatus.closed)
                  .toList()
              : state.items;
          if (state.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                SnackbarUtils.showError(context, state.error!);
                ref.read(complaintNotifierProvider.notifier).clearError();
              }
            });
          }

          return RefreshIndicator(
            color: AppColors.navyDeep,
            onRefresh: () async {
              await ref.read(complaintNotifierProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _FilterRow(
                    selected: _activeFilter,
                    onSelected: (status) async {
                      setState(() => _activeFilter = status);
                      await ref
                          .read(complaintNotifierProvider.notifier)
                          .setStatusFilter(status);
                    },
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.feedback_outlined,
                      title: 'No complaints submitted',
                      subtitle: 'You have not submitted any complaints.',
                      actionLabel: canCreate ? 'Create Complaint' : null,
                      onAction: canCreate
                          ? () => context.push(RouteNames.createComplaint)
                          : null,
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
                        final complaint = items[index];
                        return ComplaintCard(
                          complaint: complaint,
                          onTap: () => context.push(
                            RouteNames.complaintDetailPath(complaint.id),
                            extra: complaint,
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.selected,
    required this.onSelected,
  });

  final ComplaintStatus? selected;
  final ValueChanged<ComplaintStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final visibleStatuses = ComplaintStatus.values
        .where((s) => s != ComplaintStatus.closed)
        .toList();

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
          ...visibleStatuses.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: AppChip(
                label: s.label,
                icon: s.icon,
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
