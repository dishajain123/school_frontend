import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
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
  StandardModel? _selectedStandard;
  String? _selectedSubjectName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teacherNotifierProvider.notifier).load(refresh: true);
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
      ref.read(teacherNotifierProvider.notifier).loadMore();
    }
  }

  void _applyFilters() {
    ref.read(teacherNotifierProvider.notifier).setFilter(
          TeacherFilters(
            standardId: _selectedStandard?.id,
            subjectName: _selectedSubjectName,
          ),
        );
  }

  void _onStandardChanged(StandardModel? standard) {
    setState(() => _selectedStandard = standard);
    _applyFilters();
  }

  void _onSubjectChanged(String? subjectName) {
    setState(() => _selectedSubjectName = subjectName);
    _applyFilters();
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teacherNotifierProvider);
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? const <StandardModel>[];
    final subjectsAsync = ref.watch(subjectsProvider(null));
    final subjects = subjectsAsync.valueOrNull ?? const <SubjectModel>[];
    final uniqueSubjectNames = <String>[];
    final seen = <String>{};
    for (final subject in subjects) {
      final name = subject.name.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.add(key)) uniqueSubjectNames.add(name);
    }
    uniqueSubjectNames
        .sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(
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
      body: Column(
        children: [
          if (standards.isNotEmpty)
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space12,
                AppDimensions.space16,
                AppDimensions.space8,
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedStandard?.id,
                    isExpanded: true,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.navyDeep,
                    ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _dropdownDecoration('Filter by Class'),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Classes',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey800),
                        ),
                      ),
                      ...standards.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (standardId) {
                      final selected =
                          standards.cast<StandardModel?>().firstWhere(
                                (s) => s?.id == standardId,
                                orElse: () => null,
                              );
                      _onStandardChanged(selected);
                    },
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedSubjectName,
                    isExpanded: true,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    icon: subjectsAsync.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.navyDeep,
                            ),
                          )
                        : const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.navyDeep,
                          ),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: _dropdownDecoration('Filter by Subject')
                        .copyWith(fillColor: AppColors.surface50),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Subjects',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey800),
                        ),
                      ),
                      ...uniqueSubjectNames.map(
                        (subjName) => DropdownMenuItem<String?>(
                          value: subjName,
                          child: Text(subjName),
                        ),
                      ),
                    ],
                    onChanged: _onSubjectChanged,
                  ),
                ],
              ),
            ),
          Expanded(
            child: asyncState.when(
              loading: () => AppLoading.listView(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref
                    .read(teacherNotifierProvider.notifier)
                    .load(refresh: true),
              ),
              data: (teacherState) {
                if (teacherState.isLoading) {
                  return AppLoading.listView();
                }

                if (teacherState.error != null && teacherState.items.isEmpty) {
                  return AppErrorState(
                    message: teacherState.error,
                    onRetry: () => ref
                        .read(teacherNotifierProvider.notifier)
                        .load(refresh: true),
                  );
                }

                if (teacherState.items.isEmpty) {
                  return AppEmptyState(
                    title: 'No teachers found',
                    subtitle:
                        'Try changing class/subject filters or add a teacher.',
                    icon: Icons.co_present_outlined,
                    actionLabel: _canCreate ? 'Add Teacher' : null,
                    onAction: _canCreate
                        ? () => context.push(RouteNames.createTeacher)
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(teacherNotifierProvider.notifier)
                      .load(refresh: true),
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
          ),
        ],
      ),
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
      ),
      filled: true,
      fillColor: AppColors.surface50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space12,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surface200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(
          color: AppColors.navyDeep,
          width: 1.4,
        ),
      ),
    );
  }
}
