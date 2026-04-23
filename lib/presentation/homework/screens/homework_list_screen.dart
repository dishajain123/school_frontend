import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/homework_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/models/auth/current_user.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/homework_card.dart';

class HomeworkListScreen extends ConsumerStatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  ConsumerState<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends ConsumerState<HomeworkListScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = _today();
  String? _selectedSubjectId;
  bool? _isSubmittedFilter;
  late AnimationController _dateAnimCtrl;
  late Animation<double> _dateFade;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final t = _today();
    return _selectedDate.year == t.year &&
        _selectedDate.month == t.month &&
        _selectedDate.day == t.day;
  }

  @override
  void initState() {
    super.initState();
    _dateAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dateFade = CurvedAnimation(parent: _dateAnimCtrl, curve: Curves.easeOut);
    _dateAnimCtrl.forward();
  }

  @override
  void dispose() {
    _dateAnimCtrl.dispose();
    super.dispose();
  }

  void _changeDate(DateTime newDate) {
    _dateAnimCtrl.reset();
    setState(() {
      _selectedDate = newDate;
      _selectedSubjectId = null;
      _isSubmittedFilter = null;
    });
    _dateAnimCtrl.forward();
  }

  void _goToPrevDay() =>
      _changeDate(_selectedDate.subtract(const Duration(days: 1)));

  void _goToNextDay() {
    if (_isToday) return;
    _changeDate(_selectedDate.add(const Duration(days: 1)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: _today(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      _changeDate(DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _navigateToCreate() async {
    final created = await context.push<bool>('/homework/create');
    if (created == true && mounted) {
      ref.invalidate(homeworkListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.role == UserRole.teacher;
    final isParent = currentUser?.role == UserRole.parent;
    final canCreate = currentUser?.hasPermission('homework:create') ?? false;
    final selectedChild = ref.watch(selectedChildProvider);

    final activeYear = ref.watch(activeYearProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    final Map<String, String> subjectNameMap = {};
    if (isTeacher) {
      assignmentsAsync.whenData((assignments) {
        for (final a in assignments) {
          subjectNameMap[a.subjectId] = a.subjectLabel;
        }
      });
    }

    final Map<String, String> subjectOptions = {};
    if (isTeacher) {
      assignmentsAsync.whenData((assignments) {
        for (final a in assignments) {
          subjectOptions[a.subjectId] = a.subjectLabel;
        }
      });
    }

    final params = (
      date: _toApiDate(_selectedDate),
      standardId: isParent ? selectedChild?.standardId : null,
      subjectId: _selectedSubjectId,
      academicYearId: null,
      isSubmitted: _isSubmittedFilter,
    );
    final homeworkAsync = ref.watch(homeworkListProvider(params));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Homework',
        showBack: true,
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _navigateToCreate,
                tooltip: 'Post Homework',
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
      body: Column(
        children: [
          _DateBar(
            selectedDate: _selectedDate,
            isToday: _isToday,
            onPrev: _goToPrevDay,
            onNext: _goToNextDay,
            onTap: _pickDate,
          ),
          if (isTeacher && subjectOptions.isNotEmpty)
            _SubjectChipBar(
              subjectOptions: subjectOptions,
              selectedId: _selectedSubjectId,
              onSelected: (id) {
                setState(() {
                  _selectedSubjectId = _selectedSubjectId == id ? null : id;
                });
              },
            ),
          _SubmissionFilterBar(
            selectedValue: _isSubmittedFilter,
            onSelected: (value) {
              setState(() => _isSubmittedFilter = value);
            },
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () async =>
                  ref.invalidate(homeworkListProvider(params)),
              child: FadeTransition(
                opacity: _dateFade,
                child: homeworkAsync.when(
                  loading: () => _buildShimmer(),
                  error: (e, _) => AppErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(homeworkListProvider(params)),
                  ),
                  data: (response) {
                    if (response.items.isEmpty) {
                      return AppEmptyState(
                        icon: Icons.menu_book_outlined,
                        title: _isToday
                            ? 'Nothing due today'
                            : 'No homework on this day',
                        subtitle: _isToday
                            ? 'Enjoy your day — check back tomorrow.'
                            : 'No homework was posted for this date.',
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: response.items.length,
                      itemBuilder: (context, index) {
                        final hw = response.items[index];
                        return HomeworkCard(
                          homework: hw,
                          subjectName: subjectNameMap[hw.subjectId],
                          onTap: () => context.push(
                            RouteNames.homeworkDetailPath(hw.id),
                            extra: hw,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: AppLoading.card(height: 100),
      ),
    );
  }
}

class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.selectedDate,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });

  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          _ArrowButton(
              icon: Icons.chevron_left_rounded, onTap: onPrev, enabled: true),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.navyMedium),
                      const SizedBox(width: 7),
                      Text(
                        DateFormatter.formatDate(selectedDate),
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Today',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.navyMedium,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          _ArrowButton(
            icon: Icons.chevron_right_rounded,
            onTap: isToday ? null : onNext,
            enabled: !isToday,
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton(
      {required this.icon, required this.onTap, required this.enabled});
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? AppColors.surface100 : AppColors.surface50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? AppColors.navyDeep : AppColors.grey400,
        ),
      ),
    );
  }
}

class _SubjectChipBar extends StatelessWidget {
  const _SubjectChipBar({
    required this.subjectOptions,
    required this.selectedId,
    required this.onSelected,
  });

  final Map<String, String> subjectOptions;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: subjectOptions.length,
        itemBuilder: (context, index) {
          final entry = subjectOptions.entries.elementAt(index);
          final isSelected = selectedId == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface100,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  entry.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey600,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SubmissionFilterBar extends StatelessWidget {
  const _SubmissionFilterBar({
    required this.selectedValue,
    required this.onSelected,
  });

  final bool? selectedValue;
  final ValueChanged<bool?> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required String label,
      required bool? value,
    }) {
      final isSelected = selectedValue == value;
      return GestureDetector(
        onTap: () => onSelected(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.navyDeep : AppColors.surface100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: isSelected ? AppColors.white : AppColors.grey600,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Row(
        children: [
          chip(label: 'All', value: null),
          const SizedBox(width: 8),
          chip(label: 'Pending', value: false),
          const SizedBox(width: 8),
          chip(label: 'Completed', value: true),
        ],
      ),
    );
  }
}
