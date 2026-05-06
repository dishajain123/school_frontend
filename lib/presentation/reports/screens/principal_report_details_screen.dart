import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

typedef PrincipalReportDetailParams = ({
  String metric,
  String? academicYearId,
  String? standardId,
  String? section,
  String? studentId,
  String? teacherId,
  String? subjectId,
});

final principalReportDetailsProvider =
    FutureProvider.family<Map<String, dynamic>, PrincipalReportDetailParams>(
  (ref, params) async {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(
      ApiConstants.principalReportsDetails,
      queryParameters: {
        'metric': params.metric,
        if (params.academicYearId != null)
          'academic_year_id': params.academicYearId,
        if (params.standardId != null) 'standard_id': params.standardId,
        if (params.section != null && params.section!.isNotEmpty)
          'section': params.section,
        if (params.studentId != null) 'student_id': params.studentId,
        if (params.teacherId != null) 'teacher_id': params.teacherId,
        if (params.subjectId != null) 'subject_id': params.subjectId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  },
);

typedef ReportStudentFilterParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
});

final reportStudentsProvider =
    FutureProvider.family<List<StudentModel>, ReportStudentFilterParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    const pageSize = 100;
    var page = 1;
    var totalPages = 1;
    final allItems = <StudentModel>[];
    do {
      final result = await repo.list(
        academicYearId: params.academicYearId,
        standardId: params.standardId,
        section: params.section,
        page: page,
        pageSize: pageSize,
      );
      allItems.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);
    return allItems;
  },
);

final reportTeachersProvider =
    FutureProvider.family<List<TeacherModel>, String?>(
  (ref, academicYearId) async {
    final repo = ref.read(teacherRepositoryProvider);
    final result = await repo.list(
      academicYearId: academicYearId,
      page: 1,
      pageSize: 200,
    );
    return result.items;
  },
);

class PrincipalReportDetailsScreen extends ConsumerStatefulWidget {
  const PrincipalReportDetailsScreen({
    super.key,
    this.initialMetric = 'student_attendance',
  });

  final String initialMetric;

  @override
  ConsumerState<PrincipalReportDetailsScreen> createState() =>
      _PrincipalReportDetailsScreenState();
}

class _PrincipalReportDetailsScreenState
    extends ConsumerState<PrincipalReportDetailsScreen>
    with SingleTickerProviderStateMixin {
  late String _metric;
  String? _standardId;
  String? _section;
  String? _studentId;
  String? _teacherId;
  String? _subjectId;
  bool _filtersExpanded = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _metric = _normalizeMetric(widget.initialMetric);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  String _normalizeMetric(String raw) {
    switch (raw) {
      case 'fees_paid':
      case 'results':
      case 'teacher_attendance':
      case 'student_attendance':
        return raw;
      default:
        return 'student_attendance';
    }
  }

  String _metricLabel(String metric) {
    switch (metric) {
      case 'fees_paid':
        return 'Fees Paid';
      case 'results':
        return 'Student Results';
      case 'teacher_attendance':
        return 'Teacher Attendance';
      case 'student_attendance':
      default:
        return 'Student Attendance';
    }
  }

  IconData _metricIcon(String metric) {
    switch (metric) {
      case 'fees_paid':
        return Icons.account_balance_wallet_outlined;
      case 'results':
        return Icons.analytics_outlined;
      case 'teacher_attendance':
        return Icons.supervisor_account_outlined;
      case 'student_attendance':
      default:
        return Icons.fact_check_outlined;
    }
  }

  Color _metricColor(String metric) {
    switch (metric) {
      case 'fees_paid':
        return AppColors.successGreen;
      case 'results':
        return AppColors.infoBlue;
      case 'teacher_attendance':
        return AppColors.warningAmber;
      case 'student_attendance':
      default:
        return AppColors.navyMedium;
    }
  }

  void _onMetricChanged(String v) {
    _animCtrl.reset();
    setState(() => _metric = v);
    _animCtrl.forward();
  }

  bool get _hasActiveFilters =>
      _standardId != null ||
      _section != null ||
      _studentId != null ||
      _teacherId != null ||
      _subjectId != null;

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;

    final detailsAsync = ref.watch(principalReportDetailsProvider((
      metric: _metric,
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
      studentId: _studentId,
      teacherId: _teacherId,
      subjectId: _subjectId,
    )));

    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    final sectionsAsync = ref.watch(studentSectionsProvider(_standardId));
    final studentsAsync = ref.watch(
      reportStudentsProvider((
        academicYearId: activeYearId,
        standardId: _standardId,
        section: _section,
      )),
    );
    final teachersAsync = ref.watch(reportTeachersProvider(activeYearId));
    final subjectsAsync = ref.watch(subjectsProvider(_standardId));

    final accentColor = _metricColor(_metric);

    return AppScaffold(
      appBar: AppAppBar(
        title: '${_metricLabel(_metric)} Report',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hasActiveFilters
                      ? AppColors.goldPrimary.withValues(alpha: 0.25)
                      : AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: _hasActiveFilters
                      ? AppColors.goldPrimary
                      : AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _MetricTabBar(
            selectedMetric: _metric,
            onChanged: _onMetricChanged,
            metricIcon: _metricIcon,
            metricColor: _metricColor,
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _FilterPanel(
              standardsAsync: standardsAsync,
              sectionsAsync: sectionsAsync,
              studentsAsync: studentsAsync,
              teachersAsync: teachersAsync,
              subjectsAsync: subjectsAsync,
              standardId: _standardId,
              section: _section,
              studentId: _studentId,
              teacherId: _teacherId,
              subjectId: _subjectId,
              onStandardChanged: (v) => setState(() {
                _standardId = v;
                _section = null;
                _subjectId = null;
                _studentId = null;
              }),
              onSectionChanged: (v) =>
                  setState(() {
                    _section = v;
                    _studentId = null;
                  }),
              onStudentChanged: (v) => setState(() => _studentId = v),
              onTeacherChanged: (v) => setState(() => _teacherId = v),
              onSubjectChanged: (v) => setState(() => _subjectId = v),
              onClearAll: () => setState(() {
                _standardId = null;
                _section = null;
                _studentId = null;
                _teacherId = null;
                _subjectId = null;
              }),
              hasActiveFilters: _hasActiveFilters,
            ),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(
            child: detailsAsync.when(
              loading: () => _buildShimmer(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(principalReportDetailsProvider),
              ),
              data: (data) => FadeTransition(
                opacity: _fade,
                child: _DetailsBody(
                  metric: _metric,
                  data: data,
                  accentColor: accentColor,
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
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 80),
      ),
    );
  }
}

class _MetricTabBar extends StatelessWidget {
  const _MetricTabBar({
    required this.selectedMetric,
    required this.onChanged,
    required this.metricIcon,
    required this.metricColor,
  });

  final String selectedMetric;
  final ValueChanged<String> onChanged;
  final IconData Function(String) metricIcon;
  final Color Function(String) metricColor;

  static const _metrics = [
    ('student_attendance', 'Attendance'),
    ('fees_paid', 'Fees'),
    ('results', 'Results'),
    ('teacher_attendance', 'Teachers'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _metrics.length,
        itemBuilder: (context, i) {
          final metric = _metrics[i];
          final isSelected = selectedMetric == metric.$1;
          final color = metricColor(metric.$1);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(metric.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface100,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected
                      ? Border.all(color: color.withValues(alpha: 0.4))
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metricIcon(metric.$1),
                      size: 13,
                      color: isSelected ? color : AppColors.grey500,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      metric.$2,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? color : AppColors.grey600,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.standardsAsync,
    required this.sectionsAsync,
    required this.studentsAsync,
    required this.teachersAsync,
    required this.subjectsAsync,
    required this.standardId,
    required this.section,
    required this.studentId,
    required this.teacherId,
    required this.subjectId,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
    required this.onTeacherChanged,
    required this.onSubjectChanged,
    required this.onClearAll,
    required this.hasActiveFilters,
  });

  final AsyncValue<dynamic> standardsAsync;
  final AsyncValue<dynamic> sectionsAsync;
  final AsyncValue<dynamic> studentsAsync;
  final AsyncValue<dynamic> teachersAsync;
  final AsyncValue<dynamic> subjectsAsync;
  final String? standardId;
  final String? section;
  final String? studentId;
  final String? teacherId;
  final String? subjectId;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;
  final ValueChanged<String?> onTeacherChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onClearAll;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Filters',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyDeep,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              if (hasActiveFilters)
                GestureDetector(
                  onTap: onClearAll,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Clear all',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactDropdown<String?>(
                  label: 'Class',
                  hint: 'All Classes',
                  value: standardId,
                  isLoading: standardsAsync.isLoading,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Classes')),
                    ...((standardsAsync.valueOrNull as List?) ?? []).map(
                      (s) => DropdownMenuItem<String?>(
                          value: s.id as String,
                          child: Text(s.name as String)),
                    ),
                  ],
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactDropdown<String?>(
                  label: 'Section',
                  hint: 'All Sections',
                  value: section,
                  isLoading: sectionsAsync.isLoading,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Sections')),
                    ...((sectionsAsync.valueOrNull as List?) ?? []).map(
                      (s) => DropdownMenuItem<String?>(
                          value: s as String, child: Text(s)),
                    ),
                  ],
                  onChanged: onSectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CompactDropdown<String?>(
            label: 'Student',
            hint: 'All Students',
            value: studentId,
            isLoading: studentsAsync.isLoading,
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Students')),
              ...((studentsAsync.valueOrNull as List?) ?? []).map(
                (s) => DropdownMenuItem<String?>(
                  value: (s as StudentModel).id,
                  child: Text(
                    '${s.admissionNumber} (${s.section ?? '-'})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: onStudentChanged,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CompactDropdown<String?>(
                  label: 'Teacher',
                  hint: 'All Teachers',
                  value: teacherId,
                  isLoading: teachersAsync.isLoading,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Teachers')),
                    ...((teachersAsync.valueOrNull as List?) ?? []).map(
                      (t) => DropdownMenuItem<String?>(
                        value: (t as TeacherModel).id,
                        child: Text(t.displayName,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onTeacherChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CompactDropdown<String?>(
                  label: 'Subject',
                  hint: 'All Subjects',
                  value: subjectId,
                  isLoading: subjectsAsync.isLoading,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All Subjects')),
                    ...((subjectsAsync.valueOrNull as List?) ?? []).map(
                      (s) => DropdownMenuItem<String?>(
                        value: (s as SubjectModel).id,
                        child: Text(s.name, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: onSubjectChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
  });

  final String label;
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.grey500,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surface200, width: 1.2),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.navyMedium),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    hint: Text(hint,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.grey400, fontSize: 12)),
                    style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey800, fontSize: 12),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.grey400, size: 16),
                    onChanged: onChanged,
                    items: items,
                  ),
                ),
        ),
      ],
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({
    required this.metric,
    required this.data,
    required this.accentColor,
  });

  final String metric;
  final Map<String, dynamic> data;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final studentAttendance =
        Map<String, dynamic>.from(data['student_attendance'] as Map? ?? {});
    final feesPaid = Map<String, dynamic>.from(data['fees_paid'] as Map? ?? {});
    final results = Map<String, dynamic>.from(data['results'] as Map? ?? {});
    final teacherAttendance =
        Map<String, dynamic>.from(data['teacher_attendance'] as Map? ?? {});

    final attendanceBySubject = List<Map<String, dynamic>>.from(
        data['attendance_by_subject'] as List? ?? []);
    final feesByStudent =
        List<Map<String, dynamic>>.from(data['fees_by_student'] as List? ?? []);
    final resultsBySubject = List<Map<String, dynamic>>.from(
        data['results_by_subject'] as List? ?? []);
    final teacherItems = List<Map<String, dynamic>>.from(
        data['teacher_attendance_items'] as List? ?? []);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryGrid(
          studentAttendance: studentAttendance,
          feesPaid: feesPaid,
          results: results,
          teacherAttendance: teacherAttendance,
          activeMetric: metric,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.navyDeep,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Detailed Breakdown',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navyDeep,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (metric == 'student_attendance')
          _DataTable(
            headers: const ['Subject', 'Present', 'Total', 'Rate'],
            rows: attendanceBySubject
                .map((r) => [
                      (r['subject_name'] ?? '-').toString(),
                      (r['present'] ?? 0).toString(),
                      (r['total'] ?? 0).toString(),
                      '${(r['percentage'] ?? 0).toString()}%',
                    ])
                .toList(),
            accentColor: accentColor,
            emptyTitle: 'No attendance data found',
          ),
        if (metric == 'fees_paid')
          _DataTable(
            headers: const ['Student', 'Paid', 'Transactions'],
            rows: feesByStudent
                .map((r) => [
                      (r['admission_number'] ?? '-').toString(),
                      '₹${(r['paid_amount'] ?? 0).toString()}',
                      (r['transactions'] ?? 0).toString(),
                    ])
                .toList(),
            accentColor: accentColor,
            emptyTitle: 'No fee data found',
          ),
        if (metric == 'results')
          _DataTable(
            headers: const ['Subject', 'Avg %', 'Entries'],
            rows: resultsBySubject
                .map((r) => [
                      (r['subject_name'] ?? '-').toString(),
                      '${(r['average_percentage'] ?? 0).toString()}%',
                      (r['entries'] ?? 0).toString(),
                    ])
                .toList(),
            accentColor: accentColor,
            emptyTitle: 'No results data found',
          ),
        if (metric == 'teacher_attendance')
          _DataTable(
            headers: const ['Teacher', 'Present', 'On Leave'],
            rows: teacherItems
                .map((r) => [
                      (r['teacher_label'] ?? '-').toString(),
                      ((r['is_present'] ?? false) as bool) ? 'Yes' : 'No',
                      ((r['on_leave'] ?? false) as bool) ? 'Yes' : 'No',
                    ])
                .toList(),
            accentColor: accentColor,
            emptyTitle: 'No teacher attendance data found',
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.studentAttendance,
    required this.feesPaid,
    required this.results,
    required this.teacherAttendance,
    required this.activeMetric,
  });

  final Map<String, dynamic> studentAttendance;
  final Map<String, dynamic> feesPaid;
  final Map<String, dynamic> results;
  final Map<String, dynamic> teacherAttendance;
  final String activeMetric;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SummaryData(
        title: 'Student Attendance',
        value: '${(studentAttendance['value'] ?? 0)}%',
        icon: Icons.fact_check_outlined,
        color: AppColors.navyMedium,
        isActive: activeMetric == 'student_attendance',
      ),
      _SummaryData(
        title: 'Fees Collected',
        value: '₹${(feesPaid['amount'] ?? 0)}',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.successGreen,
        isActive: activeMetric == 'fees_paid',
      ),
      _SummaryData(
        title: 'Results Avg',
        value: '${(results['value'] ?? 0)}%',
        icon: Icons.analytics_outlined,
        color: AppColors.infoBlue,
        isActive: activeMetric == 'results',
      ),
      _SummaryData(
        title: 'Teacher Attend.',
        value: '${(teacherAttendance['value'] ?? 0)}%',
        icon: Icons.supervisor_account_outlined,
        color: AppColors.warningAmber,
        isActive: activeMetric == 'teacher_attendance',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _SummaryKpiCard(data: cards[i]),
    );
  }
}

class _SummaryData {
  const _SummaryData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isActive,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isActive;
}

class _SummaryKpiCard extends StatelessWidget {
  const _SummaryKpiCard({required this.data});
  final _SummaryData data;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: data.isActive
            ? data.color.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: data.isActive
              ? data.color.withValues(alpha: 0.35)
              : AppColors.surface100,
          width: data.isActive ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.color),
              ),
              if (data.isActive) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: data.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: data.isActive ? data.color : AppColors.navyDeep,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                data.title,
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey500,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataTable extends StatelessWidget {
  const _DataTable({
    required this.headers,
    required this.rows,
    required this.accentColor,
    required this.emptyTitle,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final Color accentColor;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.insights_outlined,
        title: emptyTitle,
        subtitle: 'Try adjusting your filters.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                      child: Text(
                        h,
                        style: AppTypography.labelSmall.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        textAlign: headers.indexOf(h) == 0
                            ? TextAlign.left
                            : TextAlign.center,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...rows.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;
            final isLast = index == rows.length - 1;
            return Column(
              children: [
                if (index > 0)
                  Container(height: 1, color: AppColors.surface100),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: index.isEven
                        ? AppColors.white
                        : AppColors.surface50.withValues(alpha: 0.5),
                    borderRadius: isLast
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16))
                        : null,
                  ),
                  child: Row(
                    children: row
                        .map(
                          (cell) => Expanded(
                            child: Text(
                              cell,
                              style: AppTypography.bodySmall.copyWith(
                                color: row.indexOf(cell) == 0
                                    ? AppColors.grey800
                                    : AppColors.grey600,
                                fontWeight: row.indexOf(cell) == 0
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                                fontSize: 12,
                              ),
                              textAlign: row.indexOf(cell) == 0
                                  ? TextAlign.left
                                  : TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}