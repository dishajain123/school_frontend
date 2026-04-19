import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
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

class _TeacherListScreenState extends ConsumerState<TeacherListScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  StandardModel? _selectedStandard;
  SubjectModel? _selectedSubject;
  bool _filtersExpanded = false;

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
      ref.read(teacherNotifierProvider.notifier).load(refresh: true);
      ref.read(standardsNotifierProvider.notifier).refresh();
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
      ref.read(teacherNotifierProvider.notifier).loadMore();
    }
  }

  void _applyFilters() {
    ref.read(teacherNotifierProvider.notifier).setFilter(
          TeacherFilters(
            standardId: _selectedStandard?.id,
            subjectId: _selectedSubject?.id,
            subjectName: _selectedSubject?.name,
          ),
        );
  }

  void _onStandardChanged(StandardModel? standard) {
    setState(() {
      _selectedStandard = standard;
      _selectedSubject = null;
    });
    _applyFilters();
  }

  void _onSubjectChanged(SubjectModel? subject) {
    setState(() => _selectedSubject = subject);
    _applyFilters();
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  bool get _hasActiveFilters =>
      _selectedStandard != null || _selectedSubject != null;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(teacherNotifierProvider);
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? const <StandardModel>[];
    final subjectsAsync = ref.watch(subjectsProvider(_selectedStandard?.id));
    final subjects = subjectsAsync.valueOrNull ?? const <SubjectModel>[];
    final sortedSubjects = [...subjects]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Teachers',
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
                  color: _hasActiveFilters
                      ? AppColors.goldPrimary.withValues(alpha: 0.25)
                      : AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _filtersExpanded ? Icons.tune : Icons.tune_outlined,
                  color: _hasActiveFilters
                      ? AppColors.goldPrimary
                      : AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          if (_canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () async {
                  final result = await context.push(RouteNames.createTeacher);
                  if (result == true && mounted) {
                    ref
                        .read(teacherNotifierProvider.notifier)
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
                  child: const Icon(Icons.person_add_outlined,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _FilterPanel(
                standards: standards,
                subjects: sortedSubjects,
                selectedStandard: _selectedStandard,
                selectedSubject: _selectedSubject,
                subjectsLoading: subjectsAsync.isLoading,
                onStandardChanged: _onStandardChanged,
                onSubjectChanged: _onSubjectChanged,
              ),
              crossFadeState: _filtersExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
            if (_filtersExpanded)
              Container(height: 1, color: AppColors.surface100),
            Expanded(
              child: asyncState.when(
                loading: () => _buildShimmer(),
                error: (e, _) => AppErrorState(
                  message: e.toString(),
                  onRetry: () => ref
                      .read(teacherNotifierProvider.notifier)
                      .load(refresh: true),
                ),
                data: (teacherState) {
                  if (teacherState.isLoading) return _buildShimmer();

                  if (teacherState.error != null &&
                      teacherState.items.isEmpty) {
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
                      subtitle: _hasActiveFilters
                          ? 'Try changing class or subject filters.'
                          : 'Add your first teacher to get started.',
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
                    color: AppColors.navyDeep,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: teacherState.items.length +
                          (teacherState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == teacherState.items.length) {
                          return AppLoading.paginating();
                        }
                        final teacher = teacherState.items[index];
                        final isLast = index == teacherState.items.length - 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDeep
                                      .withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TeacherTile(
                              teacher: teacher,
                              isLast: isLast,
                              onTap: () => context.push(
                                RouteNames.teacherDetailPath(teacher.id),
                                extra: teacher,
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
          ],
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

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.standards,
    required this.subjects,
    required this.selectedStandard,
    required this.selectedSubject,
    required this.subjectsLoading,
    required this.onStandardChanged,
    required this.onSubjectChanged,
  });

  final List<StandardModel> standards;
  final List<SubjectModel> subjects;
  final StandardModel? selectedStandard;
  final SubjectModel? selectedSubject;
  final bool subjectsLoading;
  final ValueChanged<StandardModel?> onStandardChanged;
  final ValueChanged<SubjectModel?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DropdownField<String?>(
            label: 'Class',
            hint: 'All Classes',
            value: selectedStandard?.id,
            prefixIcon: Icons.school_outlined,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Classes'),
              ),
              ...standards.map((s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (standardId) {
              final selected = standards.cast<StandardModel?>().firstWhere(
                    (s) => s?.id == standardId,
                    orElse: () => null,
                  );
              onStandardChanged(selected);
            },
          ),
          const SizedBox(height: 12),
          _DropdownField<String?>(
            label: 'Subject',
            hint: 'All Subjects',
            value: selectedSubject?.id,
            prefixIcon: Icons.menu_book_outlined,
            isLoading: subjectsLoading,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Subjects'),
              ),
              ...subjects.map((subject) => DropdownMenuItem<String?>(
                    value: subject.id,
                    child: Text(subject.name),
                  )),
            ],
            onChanged: (subjectId) {
              final selected = subjects.cast<SubjectModel?>().firstWhere(
                    (s) => s?.id == subjectId,
                    orElse: () => null,
                  );
              onSubjectChanged(selected);
            },
          ),
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
    this.isLoading = false,
  });

  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData prefixIcon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface200, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, size: 16, color: AppColors.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navyMedium),
                              ),
                              const SizedBox(width: 8),
                              Text('Loading...',
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.grey400)),
                            ],
                          ),
                        )
                      : DropdownButton<T>(
                          value: value,
                          isExpanded: true,
                          hint: Text(hint,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.grey400)),
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey800),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.grey400),
                          onChanged: onChanged,
                          items: items,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
