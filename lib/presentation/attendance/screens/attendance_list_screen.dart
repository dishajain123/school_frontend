import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/attendance/attendance_analytics.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/models/auth/current_user.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../widgets/attendance_calendar.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({super.key, this.studentId});
  final String? studentId;

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  String? _selectedSubjectId;
  _AttendanceViewMode _viewMode = _AttendanceViewMode.daily;
  int? _selectedLectureNumber;
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
        appBar: AppAppBar(title: 'Attendance', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (role == UserRole.student && currentStudentIdAsync.hasError) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Attendance', showBack: true),
        body: AppErrorState(
          message: currentStudentIdAsync.error.toString(),
          onRetry: () => ref.invalidate(currentStudentIdProvider),
        ),
      );
    }
    if (role == UserRole.parent &&
        childrenAsync.valueOrNull?.isLoading == true) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Attendance', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (studentId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Attendance', showBack: true),
        body: AppEmptyState(
          icon: Icons.person_search_outlined,
          title: role == UserRole.parent
              ? 'No child linked'
              : 'No student selected',
          subtitle: role == UserRole.parent
              ? 'Link a child in parent dashboard to track attendance history.'
              : 'Please select a child to view attendance.',
        ),
      );
    }

    final params = (
      studentId: studentId,
      standardId: null,
      section: null,
      academicYearId: null,
      date: null,
      month: _month,
      year: _year,
      subjectId: _selectedSubjectId,
      lectureNumber: _viewMode == _AttendanceViewMode.lectureWise
          ? _selectedLectureNumber
          : null,
    );

    final attendanceAsync = ref.watch(attendanceListProvider(params));
    final subjectAnalyticsParams = (
      studentId: studentId,
      month: _month,
      year: _year,
    );
    final subjectAnalyticsAsync =
        ref.watch(studentAnalyticsProvider(subjectAnalyticsParams));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Attendance', showBack: true),
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async => ref.invalidate(attendanceListProvider(params)),
        child: attendanceAsync.when(
          data: (result) => _buildContent(
            result.items,
            subjects: subjectAnalyticsAsync.valueOrNull?.subjects ?? const [],
          ),
          loading: () => AppLoading.fullPage(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(attendanceListProvider(params)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    List<AttendanceModel> records, {
    required List<SubjectAttendanceStat> subjects,
  }) {
    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absent =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final late = records.where((r) => r.status == AttendanceStatus.late).length;
    final total = records.length;
    final pct = total > 0 ? ((present + late) / total * 100) : 0.0;
    final dailyItems = _buildDailySummaries(records);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SummaryHeader(
            present: present,
            absent: absent,
            late: late,
            total: total,
            pct: pct.toDouble(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _AttendanceViewFilters(
              mode: _viewMode,
              subjects: subjects,
              selectedSubjectId: _selectedSubjectId,
              selectedLectureNumber: _selectedLectureNumber,
              onModeChanged: (mode) => setState(() => _viewMode = mode),
              onSubjectChanged: (subjectId) =>
                  setState(() => _selectedSubjectId = subjectId),
              onLectureChanged: (lecture) =>
                  setState(() => _selectedLectureNumber = lecture),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AttendanceCalendar(
                  records: records,
                  month: _month,
                  year: _year,
                  onMonthChanged: (month, year) => setState(() {
                    _month = month;
                    _year = year;
                  }),
                ),
              ),
            ),
          ),
        ),
        if (records.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No attendance records',
              subtitle: 'Your attendance will appear here once marked.',
            ),
          )
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Records',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _viewMode == _AttendanceViewMode.daily
                ? SliverList.builder(
                    itemCount: dailyItems.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _DailyAttendanceTile(summary: dailyItems[index]),
                    ),
                  )
                : SliverList.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _AttendanceRecordTile(
                        record: records[index],
                        isLast: index == records.length - 1,
                      ),
                    ),
                  ),
          ),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  List<_DailyAttendanceSummary> _buildDailySummaries(
      List<AttendanceModel> records) {
    final grouped = <DateTime, List<AttendanceModel>>{};
    for (final record in records) {
      final key =
          DateTime(record.date.year, record.date.month, record.date.day);
      grouped.putIfAbsent(key, () => <AttendanceModel>[]).add(record);
    }
    final list = grouped.entries.map((entry) {
      final dayRecords = entry.value;
      dayRecords.sort((a, b) => a.lectureNumber.compareTo(b.lectureNumber));
      final present =
          dayRecords.where((r) => r.status == AttendanceStatus.present).length;
      final absent =
          dayRecords.where((r) => r.status == AttendanceStatus.absent).length;
      final late =
          dayRecords.where((r) => r.status == AttendanceStatus.late).length;
      return _DailyAttendanceSummary(
        date: entry.key,
        totalLectures: dayRecords.length,
        presentLectures: present,
        absentLectures: absent,
        lateLectures: late,
        section: dayRecords.first.section,
      );
    }).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

enum _AttendanceViewMode { daily, lectureWise }

class _DailyAttendanceSummary {
  const _DailyAttendanceSummary({
    required this.date,
    required this.totalLectures,
    required this.presentLectures,
    required this.absentLectures,
    required this.lateLectures,
    required this.section,
  });

  final DateTime date;
  final int totalLectures;
  final int presentLectures;
  final int absentLectures;
  final int lateLectures;
  final String section;
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.present,
    required this.absent,
    required this.late,
    required this.total,
    required this.pct,
  });

  final int present, absent, late, total;
  final double pct;

  Color get _pctColor {
    if (pct >= 85) return AppColors.successGreen;
    if (pct >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This Month',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pct.toStringAsFixed(1)}%',
                      style: AppTypography.headlineLarge.copyWith(
                        color: _pctColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      ),
                    ),
                    Text(
                      pct >= 85
                          ? 'Good standing'
                          : pct >= 75
                              ? 'Needs attention'
                              : 'Below threshold',
                      style: AppTypography.caption.copyWith(
                        color: _pctColor.withValues(alpha: 0.9),
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
                      backgroundColor: AppColors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(_pctColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '$total',
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
                  value: '$present',
                  color: AppColors.successGreen),
              const SizedBox(width: 8),
              _StatPill(
                  label: 'Absent', value: '$absent', color: AppColors.errorRed),
              const SizedBox(width: 8),
              _StatPill(
                  label: 'Late', value: '$late', color: AppColors.warningAmber),
            ],
          ),
        ],
      ),
    );
  }
}

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

class _AttendanceRecordTile extends StatelessWidget {
  const _AttendanceRecordTile({required this.record, required this.isLast});
  final AttendanceModel record;
  final bool isLast;

  Color get _statusColor {
    switch (record.status) {
      case AttendanceStatus.present:
        return AppColors.successGreen;
      case AttendanceStatus.absent:
        return AppColors.errorRed;
      case AttendanceStatus.late:
        return AppColors.warningAmber;
    }
  }

  Color get _statusBg {
    switch (record.status) {
      case AttendanceStatus.present:
        return AppColors.successLight;
      case AttendanceStatus.absent:
        return AppColors.errorLight;
      case AttendanceStatus.late:
        return AppColors.warningLight;
    }
  }

  String get _statusLabel {
    switch (record.status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
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
      'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]}';
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              record.status == AttendanceStatus.present
                  ? Icons.check_rounded
                  : record.status == AttendanceStatus.absent
                      ? Icons.close_rounded
                      : Icons.access_time_rounded,
              color: _statusColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(record.date),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  'Lecture ${record.lectureNumber}'
                  '${record.section.isNotEmpty ? ' · Sec ${record.section}' : ''}',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.labelSmall.copyWith(
                color: _statusColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceViewFilters extends StatelessWidget {
  const _AttendanceViewFilters({
    required this.mode,
    required this.subjects,
    required this.selectedSubjectId,
    required this.selectedLectureNumber,
    required this.onModeChanged,
    required this.onSubjectChanged,
    required this.onLectureChanged,
  });

  final _AttendanceViewMode mode;
  final List<SubjectAttendanceStat> subjects;
  final String? selectedSubjectId;
  final int? selectedLectureNumber;
  final ValueChanged<_AttendanceViewMode> onModeChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<int?> onLectureChanged;

  @override
  Widget build(BuildContext context) {
    final chipStyle = AppTypography.labelMedium.copyWith(
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: selectedSubjectId,
          decoration: const InputDecoration(
            labelText: 'Subject',
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Subjects'),
            ),
            ...subjects.map(
              (s) => DropdownMenuItem<String?>(
                value: s.subjectId,
                child: Text('${s.subjectName} (${s.subjectCode})'),
              ),
            ),
          ],
          onChanged: onSubjectChanged,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ChoiceChip(
              label: Text('Daily', style: chipStyle),
              selected: mode == _AttendanceViewMode.daily,
              onSelected: (_) => onModeChanged(_AttendanceViewMode.daily),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('Lecture-wise', style: chipStyle),
              selected: mode == _AttendanceViewMode.lectureWise,
              onSelected: (_) => onModeChanged(_AttendanceViewMode.lectureWise),
            ),
          ],
        ),
        if (mode == _AttendanceViewMode.lectureWise) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text('All Lectures', style: chipStyle),
                selected: selectedLectureNumber == null,
                onSelected: (_) => onLectureChanged(null),
              ),
              for (var i = 1; i <= 8; i++)
                ChoiceChip(
                  label: Text('L$i', style: chipStyle),
                  selected: selectedLectureNumber == i,
                  onSelected: (_) => onLectureChanged(i),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DailyAttendanceTile extends StatelessWidget {
  const _DailyAttendanceTile({required this.summary});
  final _DailyAttendanceSummary summary;

  String _formatDate(DateTime d) {
    const months = [
      '',
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
      'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]}';
  }

  ({String label, Color color, Color bg}) get _statusMeta {
    if (summary.totalLectures == 0 ||
        summary.absentLectures == summary.totalLectures) {
      return (
        label: 'Absent',
        color: AppColors.errorRed,
        bg: AppColors.errorLight,
      );
    }
    if (summary.presentLectures == summary.totalLectures) {
      return (
        label: 'Present',
        color: AppColors.successGreen,
        bg: AppColors.successLight,
      );
    }
    if (summary.presentLectures + summary.lateLectures ==
            summary.totalLectures &&
        summary.lateLectures > 0) {
      return (
        label: 'Late',
        color: AppColors.warningAmber,
        bg: AppColors.warningLight,
      );
    }
    return (
      label: 'Partial',
      color: AppColors.infoBlue,
      bg: AppColors.infoLight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta;
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: meta.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.today_outlined,
              color: meta.color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(summary.date),
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey800,
                  ),
                ),
                Text(
                  '${summary.presentLectures}/${summary.totalLectures} attended'
                  '${summary.section.isNotEmpty ? ' · Sec ${summary.section}' : ''}',
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: meta.bg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              meta.label,
              style: AppTypography.labelSmall.copyWith(
                color: meta.color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}