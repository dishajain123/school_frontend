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
  String? _selectedSection;

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
    setState(() {
      _selectedStandard = standard;
      _selectedSection = null;
    });
    ref.read(studentNotifierProvider.notifier).setFilters(
          StudentFilters(
            standardId: standard?.id,
            section: null,
          ),
        );
  }

  void _onSectionChanged(String? section) {
    setState(() => _selectedSection = section);
    ref.read(studentNotifierProvider.notifier).setFilters(
          StudentFilters(
            standardId: _selectedStandard?.id,
            section: section,
          ),
        );
  }

  String? _getStandardName(
      StudentModel student, List<StandardModel> standards) {
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
    final sectionsAsync =
        ref.watch(studentSectionsProvider(_selectedStandard?.id));
    final sections = sectionsAsync.valueOrNull ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(
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
          // Standard filter dropdown
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
                    decoration: InputDecoration(
                      labelText: 'Filter by Class',
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
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide:
                            const BorderSide(color: AppColors.surface200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.navyDeep,
                          width: 1.4,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Classes',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey800,
                          ),
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
                    initialValue: _selectedSection,
                    isExpanded: true,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    icon: sectionsAsync.isLoading
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
                    decoration: InputDecoration(
                      labelText: 'Filter by Section',
                      labelStyle: AppTypography.labelMedium.copyWith(
                        color: AppColors.grey600,
                      ),
                      filled: true,
                      fillColor: _selectedStandard == null
                          ? AppColors.surface100
                          : AppColors.surface50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide:
                            const BorderSide(color: AppColors.surface200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        borderSide: const BorderSide(
                          color: AppColors.navyDeep,
                          width: 1.4,
                        ),
                      ),
                    ),
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'All Sections',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey800,
                          ),
                        ),
                      ),
                      ...sections.map(
                        (section) => DropdownMenuItem<String?>(
                          value: section,
                          child: Text('Section $section'),
                        ),
                      ),
                    ],
                    onChanged:
                        _selectedStandard == null ? null : _onSectionChanged,
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
