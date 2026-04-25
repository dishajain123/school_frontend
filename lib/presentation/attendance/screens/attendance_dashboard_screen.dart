import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../data/models/attendance/attendance_dashboard.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';

class AttendanceDashboardScreen extends ConsumerStatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  ConsumerState<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState
    extends ConsumerState<AttendanceDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _filterStandardId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    if (activeYear == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Attendance Dashboard', showBack: true),
        body: AppEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'No active academic year',
          subtitle: 'Set an active academic year to view attendance analytics.',
        ),
      );
    }

    final params = (
      academicYearId: activeYear.id,
      standardId: _filterStandardId,
    );
    final dashAsync = ref.watch(attendanceDashboardProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Attendance Dashboard', showBack: true),
      body: Column(
        children: [
          // ── Filter bar ──────────────────────────────────────────────────
          _FilterBar(
            activeYearId: activeYear.id,
            selectedStandardId: _filterStandardId,
            onStandardChanged: (id) =>
                setState(() => _filterStandardId = id),
          ),
          // ── Tab bar ─────────────────────────────────────────────────────
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelStyle: AppTypography.labelLarge
                  .copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.labelLarge,
              labelColor: AppColors.navyDeep,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.navyDeep,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Subjects'),
                Tab(text: 'Insights'),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          // ── Content ─────────────────────────────────────────────────────
          Expanded(
            child: dashAsync.when(
              data: (dashboard) => TabBarView(
                controller: _tabCtrl,
                children: [
                  _OverviewTab(dashboard: dashboard),
                  _SubjectsTab(dashboard: dashboard),
                  _InsightsTab(dashboard: dashboard),
                ],
              ),
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.invalidate(attendanceDashboardProvider(params)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter Bar ────────────────────────────────────────────────────────────────

class _FilterBar extends ConsumerWidget {
  const _FilterBar({
    required this.activeYearId,
    required this.selectedStandardId,
    required this.onStandardChanged,
  });
  final String activeYearId;
  final String? selectedStandardId;
  final ValueChanged<String?> onStandardChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: standardsAsync.when(
        data: (standards) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: 'All Classes',
                selected: selectedStandardId == null,
                onTap: () => onStandardChanged(null),
              ),
              const SizedBox(width: 8),
              ...standards.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: s.name,
                      selected: selectedStandardId == s.id,
                      onTap: () => onStandardChanged(s.id),
                    ),
                  )),
            ],
          ),
        ),
        loading: () => const SizedBox(height: 36),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.navyDeep : AppColors.surface50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.navyDeep : AppColors.surface200,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.white : AppColors.grey700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.dashboard});
  final AttendanceDashboardResponse dashboard;

  @override
  Widget build(BuildContext context) {
    final pct = dashboard.overallPercentage;
    final pctColor = pct >= 85
        ? AppColors.successGreen
        : pct >= 75
            ? AppColors.warningAmber
            : AppColors.errorRed;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overall KPI card ─────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navyDeep, AppColors.navyMedium],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('School Attendance',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.white54)),
                    const SizedBox(height: 4),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _KpiMini(
                            label: 'Present',
                            value: dashboard.present,
                            color: AppColors.successGreen),
                        const SizedBox(width: 16),
                        _KpiMini(
                            label: 'Absent',
                            value: dashboard.absent,
                            color: AppColors.errorRed),
                        const SizedBox(width: 16),
                        _KpiMini(
                            label: 'Total',
                            value: dashboard.totalRecords,
                            color: AppColors.white70),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (pct / 100).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: AppColors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text('${pct.toStringAsFixed(0)}%',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Class-wise bar chart ──────────────────────────────────────────
        _SectionTitle('Class-wise Attendance'),
        const SizedBox(height: 10),
        ...dashboard.classStats.map((c) => _ClassBar(stat: c)),
        const SizedBox(height: 16),

        // ── Monthly trend chart ───────────────────────────────────────────
        _SectionTitle('Monthly Trend'),
        const SizedBox(height: 10),
        _TrendChart(items: dashboard.monthlyTrend),
      ],
    );
  }
}

class _KpiMini extends StatelessWidget {
  const _KpiMini(
      {required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value',
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            )),
        Text(label,
            style: AppTypography.caption
                .copyWith(color: AppColors.white54, fontSize: 10)),
      ],
    );
  }
}

// ── Class Bar Row ─────────────────────────────────────────────────────────────

class _ClassBar extends StatelessWidget {
  const _ClassBar({required this.stat});
  final ClassAttendanceStat stat;

  Color get _color => stat.percentage >= 85
      ? AppColors.successGreen
      : stat.percentage >= 75
          ? AppColors.warningAmber
          : AppColors.errorRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${stat.standardName} – ${stat.section}',
                  style: AppTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '${stat.percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleSmall.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: _color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${stat.present}P',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${stat.absent}A',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.errorRed, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('${stat.totalRecords} records',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey400)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Trend Chart ───────────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.items});
  final List<AttendanceTrendItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No trend data'),
        ),
      );
    }

    final maxPct = items.fold<double>(
        0, (p, e) => e.percentage > p ? e.percentage : p);
    final displayMax = maxPct < 60 ? 100.0 : 100.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: items.map((item) {
                final barHeight =
                    (item.percentage / displayMax).clamp(0.0, 1.0) * 100;
                final color = item.percentage >= 85
                    ? AppColors.successGreen
                    : item.percentage >= 75
                        ? AppColors.warningAmber
                        : AppColors.errorRed;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${item.percentage.toStringAsFixed(0)}%',
                          style: AppTypography.caption.copyWith(
                            color: color,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: items.map((item) {
              return Expanded(
                child: Text(
                  item.periodLabel.length > 7
                      ? item.periodLabel.substring(5)
                      : item.periodLabel,
                  textAlign: TextAlign.center,
                  style:
                      AppTypography.caption.copyWith(fontSize: 8),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Subjects Tab ──────────────────────────────────────────────────────────────

class _SubjectsTab extends StatelessWidget {
  const _SubjectsTab({required this.dashboard});
  final AttendanceDashboardResponse dashboard;

  @override
  Widget build(BuildContext context) {
    if (dashboard.subjectStats.isEmpty) {
      return const AppEmptyState(
        icon: Icons.book_outlined,
        title: 'No subject data',
        subtitle: 'Subject analytics will appear once attendance is marked.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: dashboard.subjectStats.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = dashboard.subjectStats[i];
        final pctColor = s.percentage >= 85
            ? AppColors.successGreen
            : s.percentage >= 75
                ? AppColors.warningAmber
                : AppColors.errorRed;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: pctColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    s.subjectCode.length > 3
                        ? s.subjectCode.substring(0, 3)
                        : s.subjectCode,
                    style: AppTypography.labelMedium.copyWith(
                      color: pctColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.subjectName,
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (s.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: pctColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${s.present}P  ${s.absent}A  ${s.totalRecords} total',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${s.percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleMedium.copyWith(
                  color: pctColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Insights Tab ──────────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  const _InsightsTab({required this.dashboard});
  final AttendanceDashboardResponse dashboard;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Top Absentees'),
        const SizedBox(height: 10),
        if (dashboard.topAbsentees.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 32, color: AppColors.successGreen),
                  const SizedBox(height: 8),
                  Text('No absentees found',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.grey600)),
                ],
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: dashboard.topAbsentees.asMap().entries.map((entry) {
                final i = entry.key;
                final a = entry.value;
                final isLast = i == dashboard.topAbsentees.length - 1;
                return _AbsenteeRow(entry: a, rank: i + 1, isLast: isLast);
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
        _SectionTitle('Weekly Trend'),
        const SizedBox(height: 10),
        _TrendChart(items: dashboard.weeklyTrend),
      ],
    );
  }
}

// ── Absentee Row ──────────────────────────────────────────────────────────────

class _AbsenteeRow extends StatelessWidget {
  const _AbsenteeRow(
      {required this.entry, required this.rank, required this.isLast});
  final AbsenteeEntry entry;
  final int rank;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final pctColor = entry.percentage >= 75
        ? AppColors.warningAmber
        : AppColors.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.errorRed.withValues(alpha: 0.1)
                  : AppColors.surface100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTypography.caption.copyWith(
                  color: rank <= 3
                      ? AppColors.errorRed
                      : AppColors.grey500,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName ?? entry.admissionNumber,
                  style: AppTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${entry.standardName} ${entry.section} · ${entry.absences} absences',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: pctColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${entry.percentage.toStringAsFixed(0)}%',
              style: AppTypography.labelMedium.copyWith(
                color: pctColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.grey800,
      ),
    );
  }
}