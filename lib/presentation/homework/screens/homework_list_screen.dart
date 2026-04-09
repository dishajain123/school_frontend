import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart'; // myTeacherAssignmentsProvider
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

// ── Route name constants (add to route_names.dart & app_router.dart) ──────────
// static const String homeworkList   = '/homework';
// static const String createHomework = '/homework/create';

class HomeworkListScreen extends ConsumerStatefulWidget {
  const HomeworkListScreen({super.key});

  @override
  ConsumerState<HomeworkListScreen> createState() => _HomeworkListScreenState();
}

class _HomeworkListScreenState extends ConsumerState<HomeworkListScreen> {
  DateTime _selectedDate = _today();
  String? _selectedSubjectId; // teacher-only filter

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // ISO "yyyy-MM-dd" for the API
  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool get _isToday {
    final t = _today();
    return _selectedDate.year == t.year &&
        _selectedDate.month == t.month &&
        _selectedDate.day == t.day;
  }

  void _goToPrevDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
      _selectedSubjectId = null;
    });
  }

  void _goToNextDay() {
    if (_isToday) return;
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
      _selectedSubjectId = null;
    });
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
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _selectedSubjectId = null;
      });
    }
  }

  Future<void> _navigateToCreate() async {
    final created = await context.push<bool>('/homework/create');
    // Invalidate so the list refreshes on return
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

    // Load teacher assignments for subject filter + name resolution
    final activeYear = ref.watch(activeYearProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    // Build subjectId → label map for teacher cards
    final Map<String, String> subjectNameMap = {};
    if (isTeacher) {
      assignmentsAsync.whenData((assignments) {
        for (final a in assignments) {
          subjectNameMap[a.subjectId] = a.subjectLabel;
        }
      });
    }

    // Build unique subject options for the filter row (teacher only)
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
    );
    final homeworkAsync = ref.watch(homeworkListProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Homework', showBack: false),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: _navigateToCreate,
              backgroundColor: AppColors.navyDeep,
              tooltip: 'Post Homework',
              child: const Icon(Icons.add, color: AppColors.white),
            )
          : null,
      body: Column(
        children: [
          // ── Date navigation bar ────────────────────────────────────
          _DateNavigationBar(
            selectedDate: _selectedDate,
            isToday: _isToday,
            onPrev: _goToPrevDay,
            onNext: _goToNextDay,
            onTap: _pickDate,
          ),

          // ── Subject filter chips (TEACHER only) ───────────────────
          if (isTeacher && subjectOptions.isNotEmpty)
            _SubjectFilterBar(
              subjectOptions: subjectOptions,
              selectedId: _selectedSubjectId,
              onSelected: (id) {
                setState(() {
                  _selectedSubjectId = _selectedSubjectId == id ? null : id;
                });
              },
            ),

          const Divider(height: 1, color: AppColors.surface100),

          // ── Homework list ─────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () async => ref.invalidate(homeworkListProvider(params)),
              child: homeworkAsync.when(
                loading: () => _HomeworkShimmer(),
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
                    padding: const EdgeInsets.only(
                      top: AppDimensions.space8,
                      bottom: AppDimensions.space64,
                    ),
                    itemCount: response.items.length,
                    itemBuilder: (context, index) {
                      final hw = response.items[index];
                      return HomeworkCard(
                        homework: hw,
                        subjectName: subjectNameMap[hw.subjectId],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date navigation bar ───────────────────────────────────────────────────────

class _DateNavigationBar extends StatelessWidget {
  const _DateNavigationBar({
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          // ← Previous day
          _NavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: onPrev,
            enabled: true,
          ),

          // Date picker trigger
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: AppColors.navyMedium,
                      ),
                      const SizedBox(width: AppDimensions.space6),
                      Text(
                        DateFormatter.formatDate(selectedDate),
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (isToday) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Today',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.navyLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // → Next day (disabled on today)
          _NavArrow(
            icon: Icons.chevron_right_rounded,
            onTap: isToday ? null : onNext,
            enabled: !isToday,
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({
    required this.icon,
    required this.onTap,
    required this.enabled,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space8),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? AppColors.navyDeep : AppColors.grey400,
          ),
        ),
      ),
    );
  }
}

// ── Subject filter bar (teacher only) ─────────────────────────────────────────

class _SubjectFilterBar extends StatelessWidget {
  const _SubjectFilterBar({
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
      height: 52,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        itemCount: subjectOptions.length,
        itemBuilder: (context, index) {
          final entry = subjectOptions.entries.elementAt(index);
          final isSelected = selectedId == entry.key;

          return Padding(
            padding: const EdgeInsets.only(right: AppDimensions.space8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              child: FilterChip(
                label: Text(
                  entry.value,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onSelected(entry.key),
                backgroundColor: AppColors.surface50,
                selectedColor: AppColors.navyDeep,
                checkmarkColor: AppColors.white,
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface200,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shimmer skeleton ──────────────────────────────────────────────────────────

class _HomeworkShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppDimensions.space8),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space6,
        ),
        child: AppLoading.card(),
      ),
    );
  }
}
