import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

typedef _OverviewParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
  String? studentId,
  String? subjectId,
});

final _attendanceOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, _OverviewParams>(
  (ref, params) async {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(
      '/principal-reports/details',
      queryParameters: {
        'metric': 'student_attendance',
        if (params.academicYearId != null) 'academic_year_id': params.academicYearId,
        if (params.standardId != null) 'standard_id': params.standardId,
        if (params.section != null && params.section!.isNotEmpty) 'section': params.section,
        if (params.studentId != null) 'student_id': params.studentId,
        if (params.subjectId != null) 'subject_id': params.subjectId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  },
);

typedef _OverviewStudentsParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
});

final _overviewStudentsProvider =
    FutureProvider.family<List<StudentModel>, _OverviewStudentsParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final allItems = <StudentModel>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await repo.list(
        academicYearId: params.academicYearId,
        standardId: params.standardId,
        section: params.section,
        page: page,
        pageSize: 100,
      );
      allItems.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);
    return allItems;
  },
);

typedef _OverviewSectionsParams = ({
  String? standardId,
  String? academicYearId,
});

final _overviewSectionsProvider =
    FutureProvider.family<List<String>, _OverviewSectionsParams>(
  (ref, params) async {
    if (params.standardId == null || params.standardId!.isEmpty) {
      return const <String>[];
    }
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.listSections(
      standardId: params.standardId,
      academicYearId: params.academicYearId,
    );
    return sections.where((s) => s.trim().isNotEmpty).toList();
  },
);

class ClassSnapshotScreen extends ConsumerStatefulWidget {
  const ClassSnapshotScreen({super.key});

  @override
  ConsumerState<ClassSnapshotScreen> createState() => _ClassSnapshotScreenState();
}

class _ClassSnapshotScreenState extends ConsumerState<ClassSnapshotScreen> {
  String? _standardId;
  String? _section;
  String? _studentId;
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    final sectionsAsync = ref.watch(_overviewSectionsProvider((
      standardId: _standardId,
      academicYearId: activeYearId,
    )));
    final studentsAsync = ref.watch(_overviewStudentsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
    )));
    final subjectsAsync = ref.watch(subjectsProvider(_standardId));

    final detailsAsync = ref.watch(
      _attendanceOverviewProvider((
        academicYearId: activeYearId,
        standardId: _standardId,
        section: _section,
        studentId: _studentId,
        subjectId: _subjectId,
      )),
    );

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Attendance Overview',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FilterPanel(
            standardsAsync: standardsAsync,
            sectionsAsync: sectionsAsync,
            studentsAsync: studentsAsync,
            subjectsAsync: subjectsAsync,
            standardId: _standardId,
            section: _section,
            studentId: _studentId,
            subjectId: _subjectId,
            onStandardChanged: (v) => setState(() {
              _standardId = v;
              _section = null;
              _studentId = null;
              _subjectId = null;
            }),
            onSectionChanged: (v) => setState(() {
              _section = v;
              _studentId = null;
            }),
            onStudentChanged: (v) => setState(() => _studentId = v),
            onSubjectChanged: (v) => setState(() => _subjectId = v),
          ),
          const SizedBox(height: 12),
          if (detailsAsync.isLoading) AppLoading.card(height: 140),
          if (detailsAsync.hasError)
            AppErrorState(message: detailsAsync.error.toString()),
          if (detailsAsync.hasValue) ...[
            _StudentAttendanceKpi(data: detailsAsync.value!),
            const SizedBox(height: 12),
            _StudentAttendanceBySubject(data: detailsAsync.value!),
          ],
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.standardsAsync,
    required this.sectionsAsync,
    required this.studentsAsync,
    required this.subjectsAsync,
    required this.standardId,
    required this.section,
    required this.studentId,
    required this.subjectId,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
    required this.onSubjectChanged,
  });

  final AsyncValue<dynamic> standardsAsync;
  final AsyncValue<dynamic> sectionsAsync;
  final AsyncValue<dynamic> studentsAsync;
  final AsyncValue<dynamic> subjectsAsync;
  final String? standardId;
  final String? section;
  final String? studentId;
  final String? subjectId;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;
  final ValueChanged<String?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    final standards = (standardsAsync.valueOrNull as List?) ?? const [];
    final sections = (sectionsAsync.valueOrNull as List?) ?? const [];
    final students = (studentsAsync.valueOrNull as List?) ?? const [];
    final subjects = (subjectsAsync.valueOrNull as List?) ?? const [];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _DropdownField<String?>(
                  label: 'Class',
                  value: standardId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...standards.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id as String,
                        child: Text(s.name as String),
                      ),
                    ),
                  ],
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownField<String?>(
                  label: 'Section',
                  value: section,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...sections.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.toString(),
                        child: Text(s.toString()),
                      ),
                    ),
                  ],
                  onChanged: onSectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _DropdownField<String?>(
                  label: 'Student',
                  value: studentId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Students'),
                    ),
                    ...students.map(
                      (s) => DropdownMenuItem<String?>(
                        value: (s as StudentModel).id,
                        child: Text(s.displayName),
                      ),
                    ),
                  ],
                  onChanged: onStudentChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DropdownField<String?>(
                  label: 'Subject',
                  value: subjectId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Subjects'),
                    ),
                    ...subjects.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id as String,
                        child: Text(s.name as String),
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

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
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

class _StudentAttendanceKpi extends StatelessWidget {
  const _StudentAttendanceKpi({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final summary =
        Map<String, dynamic>.from(data['student_attendance'] as Map? ?? {});
    final percent = (summary['value'] as num?)?.toDouble() ?? 0;
    final present = summary['numerator']?.toString() ?? '0';
    final total = summary['denominator']?.toString() ?? '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_outlined, color: AppColors.navyDeep.withValues(alpha: 0.9)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Attendance: ${percent.toStringAsFixed(1)}% ($present/$total)',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudentAttendanceBySubject extends StatelessWidget {
  const _StudentAttendanceBySubject({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final rows = List<Map<String, dynamic>>.from(
      data['attendance_by_subject'] as List? ?? const [],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Attendance by Subject',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'No attendance data found for selected filters.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (row['subject_name'] ?? 'Subject').toString(),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      '${((row['percentage'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
