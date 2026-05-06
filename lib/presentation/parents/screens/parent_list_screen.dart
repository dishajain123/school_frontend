import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/parent_tile.dart';

class ParentListScreen extends ConsumerStatefulWidget {
  const ParentListScreen({super.key});

  @override
  ConsumerState<ParentListScreen> createState() => _ParentListScreenState();
}

class _ParentListScreenState extends ConsumerState<ParentListScreen>
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
      ref.read(parentNotifierProvider.notifier).load(refresh: true);
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
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(parentNotifierProvider.notifier).loadMore();
    }
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(parentNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Parents',
        showBack: true,
        actions: [
          if (_canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () async {
                  final result = await context.push(RouteNames.createParent);
                  if (result == true && mounted) {
                    ref
                        .read(parentNotifierProvider.notifier)
                        .load(refresh: true);
                  }
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.person_add_outlined,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: asyncState.when(
          loading: () => _buildShimmer(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.read(parentNotifierProvider.notifier).load(refresh: true),
          ),
          data: (parentState) {
            if (parentState.isLoading) return _buildShimmer();

            if (parentState.error != null && parentState.items.isEmpty) {
              return AppErrorState(
                message: parentState.error,
                onRetry: () => ref
                    .read(parentNotifierProvider.notifier)
                    .load(refresh: true),
              );
            }

            if (parentState.items.isEmpty) {
              return AppEmptyState(
                title: 'No parents found',
                subtitle: 'Add parent accounts to link them with students.',
                icon: Icons.family_restroom_outlined,
                actionLabel: _canCreate ? 'Add Parent' : null,
                onAction: _canCreate
                    ? () => context.push(RouteNames.createParent)
                    : null,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  ref.read(parentNotifierProvider.notifier).load(refresh: true),
              color: AppColors.navyDeep,
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                itemCount: parentState.items.length +
                    (parentState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == parentState.items.length) {
                    return AppLoading.paginating();
                  }
                  final parent = parentState.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ParentTile(
                        parent: parent,
                        isLast: index == parentState.items.length - 1,
                        onTap: () => context.push(
                          RouteNames.parentDetailPath(parent.id),
                          extra: parent,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppLoading.card(height: 72),
      ),
    );
  }
}