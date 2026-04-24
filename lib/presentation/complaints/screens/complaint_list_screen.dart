import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../common/widgets/app_app_bar.dart';
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

class _ComplaintListScreenState extends ConsumerState<ComplaintListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fabCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complaintNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaintsAsync = ref.watch(complaintNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final roleCanCreate = user?.role == UserRole.teacher ||
        user?.role == UserRole.student ||
        user?.role == UserRole.parent;
    final canCreate =
        ((user?.hasPermission('complaint:create') ?? false) || roleCanCreate) &&
            user?.role != UserRole.principal;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Complaints',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (stateHasFilters(complaintsAsync.valueOrNull) ||
                          _filtersExpanded)
                      ? AppColors.goldPrimary.withValues(alpha: 0.25)
                      : AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _filtersExpanded ? Icons.tune : Icons.tune_outlined,
                  color: (stateHasFilters(complaintsAsync.valueOrNull) ||
                          _filtersExpanded)
                      ? AppColors.goldPrimary
                      : AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => context.push(RouteNames.createComplaint),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: complaintsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(complaintNotifierProvider.notifier).load(),
        ),
        data: (state) {
          final userId = user?.id;
          final role = user?.role;
          final items = switch (role) {
            UserRole.principal => state.items
                .where((c) => c.status != ComplaintStatus.closed)
                .toList(),
            UserRole.parent || UserRole.student || UserRole.teacher => state
                .items
                .where((c) => userId != null && c.submittedBy == userId)
                .toList(),
            _ => state.items,
          };

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
                  child: AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _ComplaintFilterPanel(
                      canFilterByComplainant: user?.role == UserRole.principal ||
                          user?.role == UserRole.trustee ||
                          user?.role == UserRole.superadmin,
                      selectedStatus: state.statusFilter,
                      selectedCategory: state.categoryFilter,
                      selectedComplainantType: state.complainantTypeFilter,
                      onStatusSelected: (status) async {
                        await ref
                            .read(complaintNotifierProvider.notifier)
                            .setStatusFilter(status);
                      },
                      onCategorySelected: (category) async {
                        await ref
                            .read(complaintNotifierProvider.notifier)
                            .setCategoryFilter(category);
                      },
                      onComplainantTypeSelected: (type) async {
                        await ref
                            .read(complaintNotifierProvider.notifier)
                            .setComplainantTypeFilter(type);
                      },
                    ),
                    crossFadeState: _filtersExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                  ),
                ),
                if (_filtersExpanded)
                  SliverToBoxAdapter(
                    child: Container(height: 1, color: AppColors.surface100),
                  ),
                if (items.isEmpty)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.62,
                      child: AppEmptyState(
                        icon: Icons.feedback_outlined,
                        title: 'No complaints yet',
                        subtitle: 'Submitted complaints will appear here.',
                        actionLabel: canCreate ? 'Create Complaint' : null,
                        onAction: canCreate
                            ? () => context.push(RouteNames.createComplaint)
                            : null,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final complaint = items[index];
                        return ComplaintCard(
                          complaint: complaint,
                          onTap: () async {
                            await context.push(
                              RouteNames.complaintDetailPath(complaint.id),
                              extra: complaint,
                            );
                          },
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 100),
      ),
    );
  }

  bool stateHasFilters(ComplaintListState? state) {
    if (state == null) return false;
    return state.statusFilter != null ||
        state.categoryFilter != null ||
        state.complainantTypeFilter != null;
  }
}

class _ComplaintFilterPanel extends StatelessWidget {
  const _ComplaintFilterPanel({
    required this.canFilterByComplainant,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.selectedComplainantType,
    required this.onStatusSelected,
    required this.onCategorySelected,
    required this.onComplainantTypeSelected,
  });

  final bool canFilterByComplainant;
  final ComplaintStatus? selectedStatus;
  final ComplaintCategory? selectedCategory;
  final ComplainantType? selectedComplainantType;
  final ValueChanged<ComplaintStatus?> onStatusSelected;
  final ValueChanged<ComplaintCategory?> onCategorySelected;
  final ValueChanged<ComplainantType?> onComplainantTypeSelected;

  @override
  Widget build(BuildContext context) {
    final visibleStatuses = ComplaintStatus.values
        .where((s) => s != ComplaintStatus.closed)
        .toList();

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterStrip<ComplaintStatus>(
            title: 'Status',
            selected: selectedStatus,
            allLabel: 'All',
            allColor: AppColors.navyDeep,
            options: visibleStatuses,
            labelFor: (status) => status.label,
            iconFor: (status) => status.icon,
            colorFor: (status) => status.color,
            onSelected: onStatusSelected,
          ),
          const SizedBox(height: 8),
          if (canFilterByComplainant) ...[
            _FilterStrip<ComplainantType>(
              title: 'Complainant',
              selected: selectedComplainantType,
              allLabel: 'All',
              allColor: AppColors.navyDeep,
              options: ComplainantType.values,
              labelFor: (type) => type.label,
              iconFor: (type) => type.icon,
              colorFor: (type) => type.color,
              onSelected: onComplainantTypeSelected,
            ),
            const SizedBox(height: 8),
          ],
          _FilterStrip<ComplaintCategory>(
            title: 'Category',
            selected: selectedCategory,
            allLabel: 'All',
            allColor: AppColors.navyDeep,
            options: ComplaintCategory.values,
            labelFor: (category) => category.label,
            iconFor: (category) => category.icon,
            colorFor: (category) => category.color,
            onSelected: onCategorySelected,
          ),
        ],
      ),
    );
  }
}

class _FilterStrip<T> extends StatelessWidget {
  const _FilterStrip({
    required this.title,
    required this.selected,
    required this.allLabel,
    required this.allColor,
    required this.options,
    required this.labelFor,
    required this.iconFor,
    required this.colorFor,
    required this.onSelected,
  });

  final String title;
  final T? selected;
  final String allLabel;
  final Color allColor;
  final List<T> options;
  final String Function(T value) labelFor;
  final IconData? Function(T value) iconFor;
  final Color Function(T value) colorFor;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: options.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final T? value = isAll ? null : options[index - 1];
              final isSelected = selected == value;
              final label = isAll ? allLabel : labelFor(value as T);
              final icon = isAll ? null : iconFor(value as T);
              final color = isAll ? allColor : colorFor(value as T);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSelected(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.1)
                          : AppColors.surface100,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: color.withValues(alpha: 0.4))
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon,
                              size: 12,
                              color: isSelected ? color : AppColors.grey500),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          label,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? color : AppColors.grey600,
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
        ),
      ],
    );
  }
}
