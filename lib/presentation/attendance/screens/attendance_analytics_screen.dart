import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/models/auth/current_user.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../dashboard/widgets/attendance_ring.dart';
import '../widgets/subject_stat_row.dart';

class AttendanceAnalyticsScreen extends ConsumerStatefulWidget {
  const AttendanceAnalyticsScreen({super.key, this.studentId});
  final String? studentId;

  @override
  ConsumerState<AttendanceAnalyticsScreen> createState() =>
      _AttendanceAnalyticsScreenState();
}

class _AttendanceAnalyticsScreenState
    extends ConsumerState<AttendanceAnalyticsScreen> {
  int? _selectedMonth;
  int? _selectedYear;
  bool _requestedParentChildrenLoad = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role;
    final childrenAsync = ref.watch(childrenNotifierProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final currentStudentIdAsync = ref.watch(currentStudentIdProvider);

    if (role == UserRole.parent && !_requestedParentChildrenLoad) {
      _requestedParentChildrenLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(childrenNotifierProvider.notifier).loadMyChildren();
      });
    }

    final studentId = widget.studentId ??
        (role == UserRole.parent
            ? selectedChildId
            : (role == UserRole.student
                ? currentStudentIdAsync.valueOrNull
                : null));

    if (role == UserRole.student && currentStudentIdAsync.isLoading) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Analytics', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (role == UserRole.student && currentStudentIdAsync.hasError) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Analytics', showBack: true),
        body: AppErrorState(
          message: currentStudentIdAsync.error.toString(),
          onRetry: () => ref.invalidate(currentStudentIdProvider),
        ),
      );
    }
    if (role == UserRole.parent && childrenAsync.valueOrNull?.isLoading == true) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Analytics', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (studentId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Analytics', showBack: true),
        body: AppEmptyState(
          icon: Icons.analytics_outlined,
          title: role == UserRole.parent ? 'No child linked' : 'No student selected',
          subtitle: role == UserRole.parent
              ? 'Link a child in parent dashboard to track attendance analytics.'
              : 'Please select a child to view analytics.',
        ),
      );
    }

    final params = (
      studentId: studentId,
      month: _selectedMonth,
      year: _selectedYear,
    );
    final analyticsAsync = ref.watch(studentAnalyticsProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Attendance Analytics', showBack: true),
      body: Column(
        children: [
          _MonthFilterBar(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear ?? DateTime.now().year,
            onSelected: (month, year) => setState(() {
              _selectedMonth = month;
              _selectedYear = year;
            }),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () async => ref.invalidate(studentAnalyticsProvider(params)),
              child: analyticsAsync.when(
                data: (analytics) {
                  if (analytics.subjects.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: 'No analytics data',
                      subtitle: 'Attendance analytics will appear here once recorded.',
                    );
                  }
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _OverallCard(percentage: analytics.overallPercentage),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Subject-wise Breakdown',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.grey800,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDeep.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              children: analytics.subjects
                                  .asMap()
                                  .entries
                                  .map((e) => SubjectStatRow(
                                        subjectName: e.value.subjectName,
                                        subjectCode: e.value.subjectCode,
                                        percentage: e.value.percentage,
                                        present: e.value.present,
                                        total: e.value.totalClasses,
                                        isLast: e.key == analytics.subjects.length - 1,
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                    ],
                  );
                },
                loading: () => AppLoading.fullPage(),
                error: (e, _) => AppErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(studentAnalyticsProvider(params)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthFilterBar extends StatelessWidget {
  const _MonthFilterBar({
    required this.selectedMonth,
    required this.selectedYear,
    required this.onSelected,
  });

  final int? selectedMonth;
  final int selectedYear;
  final void Function(int? month, int? year) onSelected;

  static const _months = [
    'All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final isSelected = index == 0 ? selectedMonth == null : selectedMonth == index;
          return GestureDetector(
            onTap: () => index == 0
                ? onSelected(null, null)
                : onSelected(index, DateTime.now().year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDeep : AppColors.surface100,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )]
                    : null,
              ),
              child: Center(
                child: Text(
                  _months[index],
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

class _OverallCard extends StatelessWidget {
  const _OverallCard({required this.percentage});
  final double percentage;

  Color _percentageColor(double pct) {
    if (pct >= 85) return AppColors.successGreen;
    if (pct >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  String _statusLabel(double pct) {
    if (pct >= 85) return 'Good standing';
    if (pct >= 75) return 'Needs attention';
    return 'Below threshold — at risk';
  }

  @override
  Widget build(BuildContext context) {
    final color = _percentageColor(percentage);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overall Attendance',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.headlineLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 36,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(percentage),
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AttendanceRing(percentage: percentage, size: 84),
        ],
      ),
    );
  }
}
