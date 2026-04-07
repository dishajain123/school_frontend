import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
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
  const AttendanceAnalyticsScreen({
    super.key,
    this.studentId,
  });

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
    if (role == UserRole.parent &&
        childrenAsync.valueOrNull?.isLoading == true) {
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
          title: role == UserRole.parent
              ? 'No child linked'
              : 'No student selected',
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
          // Month filter chips
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
              onRefresh: () async =>
                  ref.invalidate(studentAnalyticsProvider(params)),
              child: analyticsAsync.when(
                data: (analytics) {
                  if (analytics.subjects.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.bar_chart_outlined,
                      title: 'No analytics data',
                      subtitle:
                          'Attendance analytics will appear here once recorded.',
                    );
                  }
                  return CustomScrollView(
                    slivers: [
                      // Overall ring
                      SliverToBoxAdapter(
                        child: _OverallCard(
                            percentage: analytics.overallPercentage),
                      ),
                      // Subject-wise stats
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space16,
                              vertical: AppDimensions.space8),
                          child: Text('Subject-wise Breakdown',
                              style: AppTypography.headlineSmall),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusMedium),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D0B1F3A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
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
                                      isLast: e.key ==
                                          analytics.subjects.length - 1,
                                    ))
                                .toList(),
                          ),
                        ),
                      ),
                      const SliverPadding(
                          padding:
                              EdgeInsets.only(bottom: AppDimensions.space40)),
                    ],
                  );
                },
                loading: () => AppLoading.fullPage(),
                error: (e, _) => AppErrorState(
                  message: e.toString(),
                  onRetry: () =>
                      ref.invalidate(studentAnalyticsProvider(params)),
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
    'All',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16, vertical: AppDimensions.space8),
        itemCount: _months.length,
        itemBuilder: (context, index) {
          final isSelected =
              index == 0 ? selectedMonth == null : selectedMonth == index;
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                onSelected(null, null);
              } else {
                onSelected(index, DateTime.now().year);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: AppDimensions.space8),
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.space12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.navyDeep : AppColors.surface50,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: isSelected ? AppColors.navyDeep : AppColors.surface200,
                ),
              ),
              child: Center(
                child: Text(
                  _months[index],
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.grey600,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Overall Attendance',
                    style: AppTypography.labelMedium
                        .copyWith(color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: AppTypography.headlineLarge.copyWith(
                    color: _percentageColor(percentage),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  _statusLabel(percentage),
                  style: AppTypography.bodySmall.copyWith(
                    color: _percentageColor(percentage),
                  ),
                ),
              ],
            ),
          ),
          AttendanceRing(percentage: percentage, size: 80),
        ],
      ),
    );
  }

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
}
