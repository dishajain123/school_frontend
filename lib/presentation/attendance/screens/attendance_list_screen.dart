import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../widgets/attendance_calendar.dart';

class AttendanceListScreen extends ConsumerStatefulWidget {
  const AttendanceListScreen({
    super.key,
    this.studentId, // Explicit studentId (from teacher/principal viewing a student)
  });

  final String? studentId;

  @override
  ConsumerState<AttendanceListScreen> createState() =>
      _AttendanceListScreenState();
}

class _AttendanceListScreenState extends ConsumerState<AttendanceListScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  String? _selectedSubjectId;

  String? _resolveStudentId() {
    if (widget.studentId != null) return widget.studentId;
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    if (user.role == 'STUDENT') return user.id;
    if (user.role == 'PARENT') {
      return ref.read(selectedChildIdProvider);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final studentId = _resolveStudentId();

    if (studentId == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Attendance', showBack: true),
        body: AppEmptyState(
          icon: Icons.person_search_outlined,
          title: 'No student selected',
          subtitle: 'Please select a child to view attendance.',
        ),
      );
    }

    final params = (
      studentId: studentId,
      standardId: null,
      date: null,
      month: _month,
      year: _year,
      subjectId: _selectedSubjectId,
    );

    final attendanceAsync = ref.watch(attendanceListProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Attendance', showBack: true),
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async => ref.invalidate(attendanceListProvider(params)),
        child: attendanceAsync.when(
          data: (result) => _buildContent(result.items),
          loading: () => AppLoading.fullPage(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(attendanceListProvider(params)),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<AttendanceModel> records) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(AppDimensions.space16),
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0B1F3A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AttendanceCalendar(
              records: records,
              month: _month,
              year: _year,
              onMonthChanged: (month, year) =>
                  setState(() {
                    _month = month;
                    _year = year;
                  }),
            ),
          ),
        ),
        // Summary stats
        SliverToBoxAdapter(
          child: _buildSummary(records),
        ),
        // Records list
        if (records.isEmpty)
          const SliverFillRemaining(
            child: AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No attendance records',
              subtitle: 'Your attendance will appear here once marked.',
            ),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space16,
                        vertical: AppDimensions.space8),
                    child: Text('Records',
                        style: AppTypography.headlineSmall),
                  );
                }
                final record = records[index - 1];
                return _AttendanceRecordTile(
                    record: record,
                    isLast: index == records.length);
              },
              childCount: records.length + 1,
            ),
          ),
        const SliverPadding(
            padding:
                EdgeInsets.only(bottom: AppDimensions.space40)),
      ],
    );
  }

  Widget _buildSummary(List<AttendanceModel> records) {
    final present =
        records.where((r) => r.status == AttendanceStatus.present).length;
    final absent =
        records.where((r) => r.status == AttendanceStatus.absent).length;
    final late =
        records.where((r) => r.status == AttendanceStatus.late).length;
    final total = records.length;
    final pct = total > 0
        ? ((present + late) / total * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatPill(label: 'Present', value: '$present', color: AppColors.successGreen),
          _StatPill(label: 'Absent', value: '$absent', color: AppColors.errorRed),
          _StatPill(label: 'Late', value: '$late', color: AppColors.warningAmber),
          _StatPill(
            label: 'Overall',
            value: '$pct%',
            color: AppColors.goldPrimary,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        Text(label,
            style: AppTypography.caption.copyWith(
                color: Colors.white.withOpacity(0.7))),
      ],
    );
  }
}

class _AttendanceRecordTile extends StatelessWidget {
  const _AttendanceRecordTile({
    required this.record,
    required this.isLast,
  });

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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
          left: AppDimensions.space16,
          right: AppDimensions.space16,
          bottom: AppDimensions.space8),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0B1F3A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(record.date),
                  style: AppTypography.titleSmall),
              Text(record.subjectId,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.grey400)),
            ],
          ),
          const Spacer(),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space4),
            decoration: BoxDecoration(
              color: _statusBg,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.labelSmall.copyWith(
                  color: _statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
