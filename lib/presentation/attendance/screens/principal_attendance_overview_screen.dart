// lib/presentation/attendance/screens/principal_attendance_overview_screen.dart
// Principal/Trustee: class-wise, section-wise, and subject-wise attendance overview.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/attendance/attendance_dashboard.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

class PrincipalAttendanceOverviewScreen extends ConsumerStatefulWidget {
  const PrincipalAttendanceOverviewScreen({super.key});

  @override
  ConsumerState<PrincipalAttendanceOverviewScreen> createState() =>
      _PrincipalAttendanceOverviewScreenState();
}

class _PrincipalAttendanceOverviewScreenState
    extends ConsumerState<PrincipalAttendanceOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);

    if (activeYear == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Attendance Overview', showBack: true),
        body: AppEmptyState(
          icon: Icons.calendar_today_outlined,
          title: 'No Academic Year',
          subtitle: 'Please set an active academic year to view attendance.',
        ),
      );
    }

    final params = (
      academicYearId: activeYear.id,
      standardId: null,
    );
    final dashAsync = ref.watch(attendanceDashboardProvider(params));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Attendance Overview',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(attendanceDashboardProvider(params)),
          ),
        ],
      ),
      body: dashAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(attendanceDashboardProvider(params)),
        ),
        data: (data) => _buildContent(data),
      ),
    );
  }

  Widget _buildContent(AttendanceDashboardResponse data) {
    final pct = data.overallPercentage;
    final pctColor = pct >= 85
        ? AppColors.successGreen
        : pct >= 75
            ? AppColors.warningAmber
            : AppColors.errorRed;

    return Column(
      children: [
        // ── Overall summary header ─────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Overall Attendance',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pct.toStringAsFixed(1)}%',
                          style: AppTypography.headlineLarge.copyWith(
                            color: pctColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          '${data.totalRecords} total records',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          strokeWidth: 6,
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                          strokeCap: StrokeCap.round,
                        ),
                        Text(
                          '${pct.toStringAsFixed(0)}%',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatPill(
                    label: 'Present',
                    value: '${data.present}',
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Absent',
                    value: '${data.absent}',
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    label: 'Late',
                    value: '${data.late}',
                    color: AppColors.warningAmber,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Tabs ──────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            labelStyle:
                AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
            unselectedLabelStyle: AppTypography.labelMedium,
            labelColor: AppColors.navyDeep,
            unselectedLabelColor: AppColors.grey500,
            indicatorColor: AppColors.navyDeep,
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Class-wise'),
              Tab(text: 'Subject-wise'),
              Tab(text: 'Low Attendance'),
            ],
          ),
        ),

        // ── Tab content ───────────────────────────────────────────────
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ClassWiseTab(classStats: data.classStats),
              _SubjectWiseTab(subjectStats: data.subjectStats),
              _LowAttendanceTab(absentees: data.topAbsentees),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Class-wise Tab ────────────────────────────────────────────────────────────

class _ClassWiseTab extends StatelessWidget {
  const _ClassWiseTab({required this.classStats});
  final List<ClassAttendanceStat> classStats;

  @override
  Widget build(BuildContext context) {
    if (classStats.isEmpty) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'No class data',
        subtitle: 'Attendance records will appear here once marked.',
      );
    }

    // Group by standard name
    final grouped = <String, List<ClassAttendanceStat>>{};
    for (final stat in classStats) {
      grouped.putIfAbsent(stat.standardName, () => []).add(stat);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                entry.key,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
            ),
            ...entry.value.map((stat) => _ClassStatCard(stat: stat)),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}

class _ClassStatCard extends StatelessWidget {
  const _ClassStatCard({required this.stat});
  final ClassAttendanceStat stat;

  Color get _pctColor {
    if (stat.percentage >= 85) return AppColors.successGreen;
    if (stat.percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Section ${stat.section}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${stat.percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleMedium.copyWith(
                  color: _pctColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surface100,
              valueColor: AlwaysStoppedAnimation<Color>(_pctColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                  label: 'Present',
                  value: '${stat.present}',
                  color: AppColors.successGreen),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Absent',
                  value: '${stat.absent}',
                  color: AppColors.errorRed),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Late',
                  value: '${stat.late}',
                  color: AppColors.warningAmber),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Total',
                  value: '${stat.totalRecords}',
                  color: AppColors.grey500),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Subject-wise Tab ──────────────────────────────────────────────────────────

class _SubjectWiseTab extends StatelessWidget {
  const _SubjectWiseTab({required this.subjectStats});
  final List<SubjectSchoolAttendanceStat> subjectStats;

  @override
  Widget build(BuildContext context) {
    if (subjectStats.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subject data',
        subtitle: 'Subject-wise attendance will appear here once marked.',
      );
    }

    final sorted = [...subjectStats]
      ..sort((a, b) => a.percentage.compareTo(b.percentage));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _SubjectStatCard(stat: sorted[i]),
    );
  }
}

class _SubjectStatCard extends StatelessWidget {
  const _SubjectStatCard({required this.stat});
  final SubjectSchoolAttendanceStat stat;

  Color get _pctColor {
    if (stat.percentage >= 85) return AppColors.successGreen;
    if (stat.percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat.subjectName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.grey800,
                      ),
                    ),
                    Text(
                      stat.subjectCode,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              Text(
                '${stat.percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleMedium.copyWith(
                  color: _pctColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (stat.percentage / 100).clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surface100,
              valueColor: AlwaysStoppedAnimation<Color>(_pctColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniStat(
                  label: 'Present',
                  value: '${stat.present}',
                  color: AppColors.successGreen),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Absent',
                  value: '${stat.absent}',
                  color: AppColors.errorRed),
              const SizedBox(width: 16),
              _MiniStat(
                  label: 'Late',
                  value: '${stat.late}',
                  color: AppColors.warningAmber),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Low Attendance Tab ────────────────────────────────────────────────────────

class _LowAttendanceTab extends StatelessWidget {
  const _LowAttendanceTab({required this.absentees});
  final List<AbsenteeEntry> absentees;

  @override
  Widget build(BuildContext context) {
    if (absentees.isEmpty) {
      return const AppEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No low attendance',
        subtitle: 'All students are above the threshold.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: absentees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AbsenteeCard(entry: absentees[i]),
    );
  }
}

class _AbsenteeCard extends StatelessWidget {
  const _AbsenteeCard({required this.entry});
  final AbsenteeEntry entry;

  Color get _pctColor {
    if (entry.percentage >= 85) return AppColors.successGreen;
    if (entry.percentage >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.percentage < 75
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : AppColors.surface200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _pctColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.person_outline, color: _pctColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName ?? entry.admissionNumber,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  '${entry.standardName} · Sec ${entry.section} · ${entry.admissionNumber}',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.percentage.toStringAsFixed(1)}%',
                style: AppTypography.titleSmall.copyWith(
                  color: _pctColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${entry.absences} absent',
                style: AppTypography.caption.copyWith(color: AppColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: AppTypography.titleMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
            Text(label,
                style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.65),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.labelMedium
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.grey400)),
      ],
    );
  }
}
