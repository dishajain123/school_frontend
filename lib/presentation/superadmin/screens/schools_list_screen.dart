import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/school/school_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/school_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/school_tile.dart';

class SchoolsListScreen extends ConsumerStatefulWidget {
  const SchoolsListScreen({super.key});

  @override
  ConsumerState<SchoolsListScreen> createState() => _SchoolsListScreenState();
}

class _SchoolsListScreenState extends ConsumerState<SchoolsListScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolNotifierProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      ref.read(schoolNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final schoolsAsync = ref.watch(schoolNotifierProvider);
    final isSuperadmin = user?.role == UserRole.superadmin;

    if (!isSuperadmin) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Schools', showBack: true),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only superadmin can manage schools.',
        ),
      );
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Schools',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () => context.push(RouteNames.createSchool),
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
      body: schoolsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(schoolNotifierProvider.notifier).load(refresh: true),
        ),
        data: (state) {
          if (state.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              SnackbarUtils.showError(context, state.error!);
              ref.read(schoolNotifierProvider.notifier).clearError();
            });
          }

          return FadeTransition(
            opacity: _fade,
            child: RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () =>
                  ref.read(schoolNotifierProvider.notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _FilterBar(
                      selected: state.filter,
                      totalCount: state.items.length,
                      onSelected: (filter) => ref
                          .read(schoolNotifierProvider.notifier)
                          .setFilter(filter),
                    ),
                  ),
                  if (state.items.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.business_outlined,
                        title: 'No schools found',
                        subtitle: 'Create a school to get started.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverList.separated(
                        itemCount: state.items.length +
                            (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index == state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2),
                              ),
                            );
                          }
                          final school = state.items[index];
                          return SchoolTile(
                            school: school,
                            isLast: index == state.items.length - 1,
                            onTap: () => context.push(
                              RouteNames.schoolDetailPath(school.id),
                              extra: school,
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppLoading.card(height: 70),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onSelected,
    required this.totalCount,
  });

  final SchoolActivityFilter selected;
  final ValueChanged<SchoolActivityFilter> onSelected;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: selected == SchoolActivityFilter.all,
                    onTap: () => onSelected(SchoolActivityFilter.all),
                    color: AppColors.navyDeep,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    isSelected: selected == SchoolActivityFilter.active,
                    onTap: () => onSelected(SchoolActivityFilter.active),
                    color: AppColors.successGreen,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Inactive',
                    isSelected: selected == SchoolActivityFilter.inactive,
                    onTap: () => onSelected(SchoolActivityFilter.inactive),
                    color: AppColors.errorRed,
                    icon: Icons.block_outlined,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalCount schools',
              style: AppTypography.caption.copyWith(
                color: AppColors.grey500,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.1)
              : AppColors.surface100,
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.35))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12,
                  color: isSelected ? color : AppColors.grey500),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected ? color : AppColors.grey600,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}