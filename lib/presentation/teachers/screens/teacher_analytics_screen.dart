import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

class TeacherAnalyticsScreen extends ConsumerStatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  ConsumerState<TeacherAnalyticsScreen> createState() =>
      _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState
    extends ConsumerState<TeacherAnalyticsScreen> {
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedSubjectId;

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final params = (
      academicYearId: activeYearId,
      standardId: _selectedStandardId,
      section: _selectedSection,
      subjectId: _selectedSubjectId,
    );
    final analyticsAsync = ref.watch(teacherAnalyticsProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Teacher Analytics',
        showBack: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(teacherAnalyticsProvider(params));
          await ref.read(teacherAnalyticsProvider(params).future);
        },
        child: analyticsAsync.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            children: [
              AppLoading.card(height: 140),
              const SizedBox(height: 12),
              AppLoading.card(height: 140),
              const SizedBox(height: 12),
              AppLoading.card(height: 140),
            ],
          ),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            children: [
              AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(teacherAnalyticsProvider(params)),
              ),
            ],
          ),
          data: (analytics) {
            if (analytics.assignments.isEmpty &&
                analytics.assignmentSubmission.totalAssignments == 0 &&
                analytics.attendance.totalRecords == 0 &&
                analytics.marks.totalEntries == 0) {
              return ListView(
                padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                children: const [
                  AppEmptyState(
                    title: 'No analytics data yet',
                    subtitle:
                        'Analytics will appear after assignments, attendance, and results are recorded.',
                    icon: Icons.insights_outlined,
                  ),
                ],
              );
            }

            final classOptions = <_Option>[
              for (final item in analytics.assignments)
                _Option(id: item.standardId, label: item.standardName),
            ]
                .fold<Map<String, _Option>>({}, (map, item) {
                  map[item.id] = item;
                  return map;
                })
                .values
                .toList();

            final sectionOptions = <String>{
              for (final item in analytics.assignments)
                if (_selectedStandardId == null ||
                    item.standardId == _selectedStandardId)
                  item.section,
            }.toList()
              ..sort();

            final subjectOptions = <_Option>[
              for (final item in analytics.assignments)
                if ((_selectedStandardId == null ||
                        item.standardId == _selectedStandardId) &&
                    (_selectedSection == null ||
                        item.section == _selectedSection))
                  _Option(id: item.subjectId, label: item.subjectName),
            ]
                .fold<Map<String, _Option>>({}, (map, item) {
                  map[item.id] = item;
                  return map;
                })
                .values
                .toList();

            return ListView(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              children: [
                AppCard.outlined(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filters',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDeep,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Class',
                        value: _selectedStandardId,
                        options: classOptions,
                        allLabel: 'All Classes',
                        onChanged: (v) {
                          setState(() {
                            _selectedStandardId = v;
                            _selectedSection = null;
                            _selectedSubjectId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Section',
                        value: _selectedSection,
                        options: sectionOptions
                            .map((s) => _Option(id: s, label: s))
                            .toList(),
                        allLabel: 'All Sections',
                        onChanged: (v) {
                          setState(() {
                            _selectedSection = v;
                            _selectedSubjectId = null;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      _DropdownField(
                        label: 'Subject',
                        value: _selectedSubjectId,
                        options: subjectOptions,
                        allLabel: 'All Subjects',
                        onChanged: (v) =>
                            setState(() => _selectedSubjectId = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _AssignmentAnalyticsCard(data: analytics),
                const SizedBox(height: 12),
                _AttendanceAnalyticsCard(data: analytics),
                const SizedBox(height: 12),
                _MarksAnalyticsCard(data: analytics),
                const SizedBox(height: 90),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AssignmentAnalyticsCard extends StatelessWidget {
  const _AssignmentAnalyticsCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final a = data.assignmentSubmission;
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assignments',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            leftLabel: 'Total',
            leftValue: '${a.totalAssignments}',
            rightLabel: 'Overdue',
            rightValue: '${a.overdueAssignments}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            leftLabel: 'Submissions',
            leftValue: '${a.totalSubmissions}',
            rightLabel: 'Pending Review',
            rightValue: '${a.pendingReviewSubmissions}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            leftLabel: 'On-time',
            leftValue: '${a.onTimeSubmissions}',
            rightLabel: 'Late',
            rightValue: '${a.lateSubmissions}',
          ),
        ],
      ),
    );
  }
}

class _AttendanceAnalyticsCard extends StatelessWidget {
  const _AttendanceAnalyticsCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final a = data.attendance;
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance (Your Subject Records)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            leftLabel: 'Overall',
            leftValue: '${a.attendancePercentage.toStringAsFixed(1)}%',
            rightLabel: 'Total Records',
            rightValue: '${a.totalRecords}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            leftLabel: 'Present',
            leftValue: '${a.presentCount}',
            rightLabel: 'Absent/Late',
            rightValue: '${a.absentCount + a.lateCount}',
          ),
          if (a.bySubject.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...a.bySubject.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subjectName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${item.attendancePercentage.toStringAsFixed(1)}% (${item.present}/${item.total})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarksAnalyticsCard extends StatelessWidget {
  const _MarksAnalyticsCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final m = data.marks;
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marks (Entries By You)',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 12),
          _MetricRow(
            leftLabel: 'Average',
            leftValue: '${m.averagePercentage.toStringAsFixed(1)}%',
            rightLabel: 'Entries',
            rightValue: '${m.totalEntries}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            leftLabel: 'Above Avg (>=75)',
            leftValue: '${m.aboveAverageCount}',
            rightLabel: 'Moderate (40-74)',
            rightValue: '${m.moderateCount}',
          ),
          const SizedBox(height: 8),
          _MetricRow(
            leftLabel: 'Below Avg (<40)',
            leftValue: '${m.belowAverageCount}',
            rightLabel: ' ',
            rightValue: ' ',
          ),
          if (m.bySubject.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...m.bySubject.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.subjectName,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${item.averagePercentage.toStringAsFixed(1)}% (${item.entries})',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricItem(
            label: leftLabel,
            value: leftValue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricItem(
            label: rightLabel,
            value: rightValue,
          ),
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option({required this.id, required this.label});
  final String id;
  final String label;
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<_Option> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = options.map((e) => e.id).toSet();
    final safeValue = (value != null && values.contains(value)) ? value : null;
    return DropdownButtonFormField<String?>(
      initialValue: safeValue,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(allLabel),
        ),
        ...options.map(
          (opt) => DropdownMenuItem<String?>(
            value: opt.id,
            child: Text(opt.label),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
