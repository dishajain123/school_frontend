import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
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
      '/principal-reports/details',
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
    extends ConsumerState<PrincipalReportDetailsScreen> {
  late String _metric;
  String? _standardId;
  String? _section;
  String? _studentId;
  String? _teacherId;
  String? _subjectId;

  @override
  void initState() {
    super.initState();
    _metric = _normalizeMetric(widget.initialMetric);
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
    final sectionsAsync = ref.watch(
      studentSectionsProvider(_standardId),
    );
    final studentsAsync = ref.watch(
      reportStudentsProvider((
        academicYearId: activeYearId,
        standardId: _standardId,
        section: _section,
      )),
    );
    final teachersAsync = ref.watch(reportTeachersProvider(activeYearId));
    final subjectsAsync = ref.watch(subjectsProvider(_standardId));

    return AppScaffold(
      appBar: AppAppBar(
        title: '${_metricLabel(_metric)} Analysis',
        showBack: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _metric,
                  decoration: _decoration('Report Type'),
                  items: const [
                    DropdownMenuItem(
                        value: 'student_attendance',
                        child: Text('Student Attendance')),
                    DropdownMenuItem(
                        value: 'fees_paid', child: Text('Fees Paid')),
                    DropdownMenuItem(value: 'results', child: Text('Results')),
                    DropdownMenuItem(
                        value: 'teacher_attendance',
                        child: Text('Teacher Attendance')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _metric = v);
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                standardsAsync.when(
                  data: (standards) => DropdownButtonFormField<String>(
                    initialValue: _standardId,
                    decoration: _decoration('Class'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('All Classes')),
                      ...standards.map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _standardId = v;
                        _section = null;
                        _subjectId = null;
                        _studentId = null;
                      });
                    },
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppDimensions.space12),
                sectionsAsync.when(
                  data: (sections) => DropdownButtonFormField<String>(
                    initialValue: _section,
                    decoration: _decoration('Section'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('All Sections')),
                      ...sections.map(
                        (s) =>
                            DropdownMenuItem<String>(value: s, child: Text(s)),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      _section = v;
                      _studentId = null;
                    }),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppDimensions.space12),
                studentsAsync.when(
                  data: (students) => DropdownButtonFormField<String>(
                    initialValue: _studentId,
                    decoration: _decoration('Student'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('All Students')),
                      ...students.map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text('${s.admissionNumber} (${s.section})'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _studentId = v),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppDimensions.space12),
                teachersAsync.when(
                  data: (teachers) => DropdownButtonFormField<String>(
                    initialValue: _teacherId,
                    decoration: _decoration('Teacher'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('All Teachers')),
                      ...teachers.map(
                        (t) => DropdownMenuItem<String>(
                          value: t.id,
                          child: Text(t.displayName),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _teacherId = v),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppDimensions.space12),
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String>(
                    initialValue: _subjectId,
                    decoration: _decoration('Subject'),
                    items: [
                      const DropdownMenuItem<String>(
                          value: null, child: Text('All Subjects')),
                      ...subjects.map(
                        (SubjectModel s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _subjectId = v),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: detailsAsync.when(
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(principalReportDetailsProvider),
              ),
              data: (data) => _DetailsBody(metric: _metric, data: data),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsBody extends StatelessWidget {
  const _DetailsBody({required this.metric, required this.data});

  final String metric;
  final Map<String, dynamic> data;

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
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        _TopSummaryCards(
          studentAttendance: studentAttendance,
          feesPaid: feesPaid,
          results: results,
          teacherAttendance: teacherAttendance,
        ),
        const SizedBox(height: AppDimensions.space16),
        Text(
          'Detailed Analysis',
          style:
              AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppDimensions.space12),
        if (metric == 'student_attendance')
          _SimpleTable(
            headers: const ['Subject', 'Present', 'Total', '%'],
            rows: attendanceBySubject
                .map(
                  (r) => [
                    (r['subject_name'] ?? '-').toString(),
                    (r['present'] ?? 0).toString(),
                    (r['total'] ?? 0).toString(),
                    '${(r['percentage'] ?? 0).toString()}%',
                  ],
                )
                .toList(),
            emptyTitle: 'No attendance analysis data',
          ),
        if (metric == 'fees_paid')
          _SimpleTable(
            headers: const ['Student', 'Paid Amount', 'Transactions'],
            rows: feesByStudent
                .map(
                  (r) => [
                    (r['admission_number'] ?? '-').toString(),
                    '₹${(r['paid_amount'] ?? 0).toString()}',
                    (r['transactions'] ?? 0).toString(),
                  ],
                )
                .toList(),
            emptyTitle: 'No fee analysis data',
          ),
        if (metric == 'results')
          _SimpleTable(
            headers: const ['Subject', 'Avg %', 'Entries'],
            rows: resultsBySubject
                .map(
                  (r) => [
                    (r['subject_name'] ?? '-').toString(),
                    '${(r['average_percentage'] ?? 0).toString()}%',
                    (r['entries'] ?? 0).toString(),
                  ],
                )
                .toList(),
            emptyTitle: 'No results analysis data',
          ),
        if (metric == 'teacher_attendance')
          _SimpleTable(
            headers: const ['Teacher', 'Present', 'On Leave'],
            rows: teacherItems
                .map(
                  (r) => [
                    (r['teacher_label'] ?? '-').toString(),
                    ((r['is_present'] ?? false) as bool) ? 'Yes' : 'No',
                    ((r['on_leave'] ?? false) as bool) ? 'Yes' : 'No',
                  ],
                )
                .toList(),
            emptyTitle: 'No teacher attendance analysis data',
          ),
      ],
    );
  }
}

class _TopSummaryCards extends StatelessWidget {
  const _TopSummaryCards({
    required this.studentAttendance,
    required this.feesPaid,
    required this.results,
    required this.teacherAttendance,
  });

  final Map<String, dynamic> studentAttendance;
  final Map<String, dynamic> feesPaid;
  final Map<String, dynamic> results;
  final Map<String, dynamic> teacherAttendance;

  String _valuePct(Map<String, dynamic> data) =>
      '${(data['value'] ?? 0).toString()}%';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Student Attendance',
                value: _valuePct(studentAttendance),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _MetricCard(
                title: 'Fees Paid',
                value: '₹${(feesPaid['amount'] ?? 0).toString()}',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Results Avg',
                value: _valuePct(results),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: _MetricCard(
                title: 'Teacher Attendance',
                value: _valuePct(teacherAttendance),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.grey600)),
          const SizedBox(height: AppDimensions.space4),
          Text(value,
              style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700, color: AppColors.navyDeep)),
        ],
      ),
    );
  }
}

class _SimpleTable extends StatelessWidget {
  const _SimpleTable({
    required this.headers,
    required this.rows,
    required this.emptyTitle,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String emptyTitle;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return AppEmptyState(
        icon: Icons.insights_outlined,
        title: emptyTitle,
        subtitle: 'Try changing filters.',
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers
              .map(
                (h) => DataColumn(
                  label: Text(
                    h,
                    style: AppTypography.labelMedium
                        .copyWith(color: AppColors.navyDeep),
                  ),
                ),
              )
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map(
                        (c) => DataCell(
                          Text(c, style: AppTypography.bodySmall),
                        ),
                      )
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String hint) => InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
    );
