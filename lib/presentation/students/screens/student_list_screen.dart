import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/student_tile.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  final ScrollController _scrollController = ScrollController();
  StandardModel? _selectedStandard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotifierProvider.notifier).load(refresh: true);
      ref.read(standardsNotifierProvider.notifier).refresh();
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
      ref.read(studentNotifierProvider.notifier).loadMore();
    }
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  void _onStandardChanged(StandardModel? standard) {
    setState(() => _selectedStandard = standard);
    ref.read(studentNotifierProvider.notifier).setFilters(
          StudentFilters(standardId: standard?.id),
        );
  }

  String? _getStandardName(StudentModel student, List<StandardModel> standards) {
    if (student.standardId == null) return null;
    try {
      return standards.firstWhere((s) => s.id == student.standardId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(studentNotifierProvider);
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Students',
        showBack: true,
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final result = await context.push(RouteNames.createStudent);
                if (result == true && mounted) {
                  ref
                      .read(studentNotifierProvider.notifier)
                      .load(refresh: true);
                }
              },
              tooltip: 'Add Student',
              child: const Icon(Icons.school_outlined),
            )
          : null,
      body: Column(
        children: [
          // Standard filter bar
          if (standards.isNotEmpty)
            Container(
              height: 52,
              color: AppColors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space8,
                ),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedStandard == null,
                    onTap: () => _onStandardChanged(null),
                  ),
                  ...standards.map(
                    (s) => Padding(
                      padding:
                          const EdgeInsets.only(left: AppDimensions.space8),
                      child: _FilterChip(
                        label: s.name,
                        isSelected: _selectedStandard?.id == s.id,
                        onTap: () => _onStandardChanged(s),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // List
          Expanded(
            child: asyncState.when(
              loading: () => AppLoading.listView(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref
                    .read(studentNotifierProvider.notifier)
                    .load(refresh: true),
              ),
              data: (studentState) {
                if (studentState.isLoading) return AppLoading.listView();

                if (studentState.error != null && studentState.items.isEmpty) {
                  return AppErrorState(
                    message: studentState.error,
                    onRetry: () => ref
                        .read(studentNotifierProvider.notifier)
                        .load(refresh: true),
                  );
                }

                if (studentState.items.isEmpty) {
                  return AppEmptyState(
                    title: 'No students found',
                    subtitle: _selectedStandard != null
                        ? 'No students in ${_selectedStandard!.name}.'
                        : 'Add your first student to get started.',
                    icon: Icons.school_outlined,
                    actionLabel: _canCreate ? 'Add Student' : null,
                    onAction: _canCreate
                        ? () => context.push(RouteNames.createStudent)
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(studentNotifierProvider.notifier)
                      .load(refresh: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppDimensions.pageVertical,
                    ),
                    itemCount: studentState.items.length +
                        (studentState.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.surface100,
                      indent: 68,
                    ),
                    itemBuilder: (context, index) {
                      if (index == studentState.items.length) {
                        return AppLoading.paginating();
                      }
                      final student = studentState.items[index];
                      return Container(
                        color: AppColors.white,
                        child: StudentTile(
                          student: student,
                          standardName: _getStandardName(student, standards),
                          isLast: index == studentState.items.length - 1,
                          onTap: () => context.push(
                            RouteNames.studentDetailPath(student.id),
                            extra: student,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
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
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDeep : AppColors.surface100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.grey800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}