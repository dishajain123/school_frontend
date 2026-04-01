import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/parent/parent_model.dart';
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

class _ParentListScreenState extends ConsumerState<ParentListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parentNotifierProvider.notifier).load(refresh: true);
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
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final result = await context.push(RouteNames.createParent);
                if (result == true && mounted) {
                  ref.read(parentNotifierProvider.notifier).load(refresh: true);
                }
              },
              tooltip: 'Add Parent',
              child: const Icon(Icons.person_add_outlined),
            )
          : null,
      body: asyncState.when(
        loading: () => AppLoading.listView(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(parentNotifierProvider.notifier).load(refresh: true),
        ),
        data: (parentState) {
          if (parentState.isLoading) return AppLoading.listView();

          if (parentState.error != null && parentState.items.isEmpty) {
            return AppErrorState(
              message: parentState.error,
              onRetry: () =>
                  ref.read(parentNotifierProvider.notifier).load(refresh: true),
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
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.pageVertical,
              ),
              itemCount: parentState.items.length +
                  (parentState.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.surface100,
                indent: 68,
              ),
              itemBuilder: (context, index) {
                if (index == parentState.items.length) {
                  return AppLoading.paginating();
                }
                final parent = parentState.items[index];
                return Container(
                  color: AppColors.white,
                  child: ParentTile(
                    parent: parent,
                    isLast: index == parentState.items.length - 1,
                    onTap: () => context.push(
                      RouteNames.parentDetailPath(parent.id),
                      extra: parent,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}