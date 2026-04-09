import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../data/models/attendance/attendance_snapshot.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../dashboard/widgets/stat_card.dart';

class ClassSnapshotScreen extends ConsumerStatefulWidget {
  const ClassSnapshotScreen({super.key});

  @override
  ConsumerState<ClassSnapshotScreen> createState() =>
      _ClassSnapshotScreenState();
}

class _ClassSnapshotScreenState extends ConsumerState<ClassSnapshotScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStandardId;
  String? _activeYearId;
  bool _hasFetched = false;
  ClassSnapshotParams? _currentParams;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final year = ref.read(activeYearProvider);
      if (year != null) setState(() => _activeYearId = year.id);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.navyDeep, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _load() {
    if (_selectedStandardId == null || _activeYearId == null) {
      SnackbarUtils.showError(context, 'Please select a class first');
      return;
    }
    final date =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    setState(() {
      _hasFetched = true;
      _currentParams = (
        standardId: _selectedStandardId!,
        academicYearId: _activeYearId!,
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const AppAppBar(title: 'Class Snapshot', showBack: true),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFilterPanel()),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.surface100),
          ),
          SliverToBoxAdapter(child: _buildReportsOverview()),
          const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.surface100),
          ),
          ..._buildContentSlivers(),
        ],
      ),
    );
  }

  Widget _buildReportsOverview() {
    final statsAsync = ref.watch(principalDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;

    String compactAmount(double amount) {
      if (amount >= 10000000) {
        return '${(amount / 10000000).toStringAsFixed(1)}Cr';
      }
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      }
      if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return amount.toStringAsFixed(0);
    }

    return Container(
      color: AppColors.surface50,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports Overview',
            style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.navyDeep),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Student Attendance',
                  value:
                      '${(stats?.studentAttendancePercentage ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.how_to_reg_outlined,
                  iconColor: AppColors.successGreen,
                  onTap: () => context.go(
                      '${RouteNames.principalReportDetails}?metric=student_attendance'),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  label: 'Fees Paid',
                  value: '₹${compactAmount(stats?.feesPaidAmount ?? 0)}',
                  icon: Icons.payments_outlined,
                  iconColor: AppColors.goldPrimary,
                  onTap: () => context.go(
                      '${RouteNames.principalReportDetails}?metric=fees_paid'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Results Avg',
                  value:
                      '${(stats?.resultsAveragePercentage ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.analytics_outlined,
                  iconColor: AppColors.infoBlue,
                  onTap: () => context.go(
                      '${RouteNames.principalReportDetails}?metric=results'),
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: StatCard(
                  label: 'Teacher Attendance',
                  value:
                      '${(stats?.teacherAttendancePercentage ?? 0).toStringAsFixed(1)}%',
                  icon: Icons.co_present,
                  iconColor: AppColors.subjectBio,
                  onTap: () => context.go(
                      '${RouteNames.principalReportDetails}?metric=teacher_attendance'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          _FilterRow(
            icon: Icons.calendar_today_outlined,
            label: _formatDate(_selectedDate),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppDimensions.space12),
          // Standard selector
          Builder(
            builder: (context) {
              final year = ref.watch(activeYearProvider);
              if (year == null) {
                return AppLoading.listTile();
              }
              return ref.watch(standardsProvider(year.id)).when(
                    data: (standards) => DropdownButtonFormField<String>(
                      initialValue: _selectedStandardId,
                      decoration: _dropdownDecoration('Select class'),
                      items: standards
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text(s.name,
                                    style: AppTypography.bodyMedium),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedStandardId = val),
                    ),
                    loading: () => AppLoading.listTile(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
            },
          ),
          const SizedBox(height: AppDimensions.space12),
          AppButton.primary(label: 'Load Snapshot', onTap: _load),
        ],
      ),
    );
  }

  List<Widget> _buildContentSlivers() {
    if (!_hasFetched || _currentParams == null) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.groups_outlined,
            title: 'Select a class and date',
            subtitle: 'Choose a class and date above, then tap Load Snapshot.',
          ),
        ),
      ];
    }

    final snapshotAsync = ref.watch(classSnapshotProvider(_currentParams!));

    return snapshotAsync.when(
      data: (snapshot) {
        if (snapshot.records.isEmpty) {
          return const [
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.event_busy_outlined,
                title: 'No records found',
                subtitle:
                    'No attendance was marked for this class on this date.',
              ),
            ),
          ];
        }
        return [
          SliverToBoxAdapter(child: _SnapshotSummaryBar(snapshot: snapshot)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space8,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SnapshotRecordTile(
                  record: snapshot.records[index],
                  isLast: index == snapshot.records.length - 1,
                  onTap: () => context.push(
                    RouteNames.attendanceAnalyticsPath(
                      snapshot.records[index].studentId,
                    ),
                  ),
                ),
                childCount: snapshot.records.length,
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppDimensions.space40),
          ),
        ];
      },
      loading: () => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SizedBox.expand(child: AppLoading.fullPage()),
        ),
      ],
      error: (e, _) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            message: e.toString(),
            onRetry: _load,
          ),
        ),
      ],
    );
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
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }
}

class _SnapshotSummaryBar extends StatelessWidget {
  const _SnapshotSummaryBar({required this.snapshot});
  final ClassAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.space16),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SnapStat(
                  value: '${snapshot.present}',
                  label: 'Present',
                  color: AppColors.successGreen),
              _SnapStat(
                  value: '${snapshot.absent}',
                  label: 'Absent',
                  color: AppColors.errorRed),
              _SnapStat(
                  value: '${snapshot.late}',
                  label: 'Late',
                  color: AppColors.warningAmber),
              _SnapStat(
                  value: '${snapshot.notMarked}',
                  label: 'Not Marked',
                  color: AppColors.grey400),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: snapshot.presentPercentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            '${snapshot.presentPercentage.toStringAsFixed(1)}% present today',
            style: AppTypography.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SnapStat extends StatelessWidget {
  const _SnapStat(
      {required this.value, required this.label, required this.color});
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.headlineMedium
                .copyWith(color: color, fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTypography.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.6))),
      ],
    );
  }
}

class _SnapshotRecordTile extends StatelessWidget {
  const _SnapshotRecordTile({
    required this.record,
    required this.isLast,
    this.onTap,
  });
  final ClassSnapshotRecord record;
  final bool isLast;
  final VoidCallback? onTap;

  Color get _statusColor {
    if (record.status == null) return AppColors.grey400;
    switch (record.status!) {
      case AttendanceStatus.present:
        return AppColors.successGreen;
      case AttendanceStatus.absent:
        return AppColors.errorRed;
      case AttendanceStatus.late:
        return AppColors.warningAmber;
    }
  }

  Color get _statusBg {
    if (record.status == null) return AppColors.surface100;
    switch (record.status!) {
      case AttendanceStatus.present:
        return AppColors.successLight;
      case AttendanceStatus.absent:
        return AppColors.errorLight;
      case AttendanceStatus.late:
        return AppColors.warningLight;
    }
  }

  String get _statusLabel {
    if (record.status == null) return 'Not Marked';
    switch (record.status!) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D0B1F3A), blurRadius: 8, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Initials avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Center(
                child: Text(
                  record.admissionNumber.length >= 2
                      ? record.admissionNumber.substring(0, 2).toUpperCase()
                      : record.admissionNumber.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.navyMedium, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.admissionNumber, style: AppTypography.titleSmall),
                  if (record.rollNumber != null &&
                      record.rollNumber!.trim().isNotEmpty)
                    Text('Roll ${record.rollNumber}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey600)),
                  if (record.section.isNotEmpty)
                    Text('Sec ${record.section}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey400)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4),
              decoration: BoxDecoration(
                color: _statusBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(_statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                      color: _statusColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space12, vertical: AppDimensions.space12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            Icon(icon, size: AppDimensions.iconSM, color: AppColors.grey600),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(label, style: AppTypography.bodyMedium),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey600),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dropdownDecoration(String hint) => InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12, vertical: AppDimensions.space12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surface200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surface200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.navyMedium),
      ),
    );
