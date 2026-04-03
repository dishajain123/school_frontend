import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/school_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_chip.dart';
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

class _SchoolsListScreenState extends ConsumerState<SchoolsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(schoolNotifierProvider.notifier).load(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      appBar: const AppAppBar(
        title: 'Schools',
        showBack: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.createSchool),
        backgroundColor: AppColors.goldPrimary,
        tooltip: 'Create School',
        child: const Icon(Icons.add_rounded),
      ),
      body: schoolsAsync.when(
        loading: () => AppLoading.listView(count: 8, withAvatar: false),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(schoolNotifierProvider.notifier).load(
                refresh: true,
              ),
        ),
        data: (state) {
          if (state.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              SnackbarUtils.showError(context, state.error!);
              ref.read(schoolNotifierProvider.notifier).clearError();
            });
          }

          return RefreshIndicator(
            color: AppColors.navyDeep,
            onRefresh: () =>
                ref.read(schoolNotifierProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _SchoolFilterRow(
                    selected: state.filter,
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
                  SliverList.separated(
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.surface100,
                      indent: 68,
                    ),
                    itemBuilder: (context, index) {
                      if (index == state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(AppDimensions.space16),
                          child: Center(
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      final school = state.items[index];
                      return Container(
                        color: AppColors.white,
                        child: SchoolTile(
                          school: school,
                          isLast: index == state.items.length - 1,
                          onTap: () => context.push(
                            RouteNames.schoolDetailPath(school.id),
                            extra: school,
                          ),
                        ),
                      );
                    },
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppDimensions.space40),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SchoolFilterRow extends StatelessWidget {
  const _SchoolFilterRow({
    required this.selected,
    required this.onSelected,
  });

  final SchoolActivityFilter selected;
  final ValueChanged<SchoolActivityFilter> onSelected;

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
            isSelected: selected == SchoolActivityFilter.all,
            onTap: () => onSelected(SchoolActivityFilter.all),
            small: true,
          ),
          const SizedBox(width: AppDimensions.space8),
          AppChip(
            label: 'Active',
            isSelected: selected == SchoolActivityFilter.active,
            onTap: () => onSelected(SchoolActivityFilter.active),
            selectedColor: AppColors.successGreen,
            small: true,
          ),
          const SizedBox(width: AppDimensions.space8),
          AppChip(
            label: 'Inactive',
            isSelected: selected == SchoolActivityFilter.inactive,
            onTap: () => onSelected(SchoolActivityFilter.inactive),
            selectedColor: AppColors.errorRed,
            small: true,
          ),
        ],
      ),
    );
  }
}
