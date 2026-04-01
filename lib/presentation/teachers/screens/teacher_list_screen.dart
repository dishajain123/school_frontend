import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/teacher_tile.dart';

class TeacherListScreen extends ConsumerStatefulWidget {
  const TeacherListScreen({super.key});

  @override
  ConsumerState<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends ConsumerState<TeacherListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherNotifierProvider.notifier).load(refresh: true);
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
      ref.read(teacherNotifierProvider.notifier).loadMore();
    }
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teacherNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Teachers',
        showBack: true,
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.createTeacher),
              tooltip: 'Add Teacher',
              child: const Icon(Icons.person_add_outlined),
            )
          : null,
      body: asyncState.when(
        loading: () => AppLoading.listView(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(teacherNotifierProvider.notifier).load(refresh: true),
        ),
        data: (teacherState) {
          if (teacherState.isLoading) {
            return AppLoading.listView();
          }

          if (teacherState.error != null && teacherState.items.isEmpty) {
            return AppErrorState(
              message: teacherState.error,
              onRetry: () =>
                  ref.read(teacherNotifierProvider.notifier).load(refresh: true),
            );
          }

          if (teacherState.items.isEmpty) {
            return AppEmptyState(
              title: 'No teachers found',
              subtitle: 'Add your first teacher to get started.',
              icon: Icons.co_present_outlined,
              actionLabel: _canCreate ? 'Add Teacher' : null,
              onAction: _canCreate
                  ? () => context.push(RouteNames.createTeacher)
                  : null,
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(teacherNotifierProvider.notifier).load(refresh: true),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                vertical: AppDimensions.pageVertical,
              ),
              itemCount: teacherState.items.length +
                  (teacherState.isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.surface100,
                indent: 68,
              ),
              itemBuilder: (context, index) {
                if (index == teacherState.items.length) {
                  return AppLoading.paginating();
                }
                final teacher = teacherState.items[index];
                return Container(
                  color: AppColors.white,
                  child: TeacherTile(
                    teacher: teacher,
                    isLast: index == teacherState.items.length - 1,
                    onTap: () => context.push(
                      RouteNames.teacherDetailPath(teacher.id),
                      extra: teacher,
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