import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

typedef _StudentsFilterParams = ({
  String standardId,
  String? section,
  String? academicYearId,
});

final _studentsByClassSectionProvider =
    FutureProvider.family<List<StudentModel>, _StudentsFilterParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final items = <StudentModel>[];
    var page = 1;
    var totalPages = 1;

    do {
      final result = await repo.list(
        standardId: params.standardId,
        section: params.section,
        academicYearId: params.academicYearId,
        page: page,
        pageSize: 100,
      );
      items.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);

    items.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return items;
  },
);

class PrincipalResultsDistributionScreen extends ConsumerStatefulWidget {
  const PrincipalResultsDistributionScreen({super.key});

  @override
  ConsumerState<PrincipalResultsDistributionScreen> createState() =>
      _PrincipalResultsDistributionScreenState();
}

class _PrincipalResultsDistributionScreenState
    extends ConsumerState<PrincipalResultsDistributionScreen> {
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedExamId;
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    final sectionsAsync =
        (_selectedStandardId == null || _selectedStandardId!.isEmpty)
            ? const AsyncValue<List<String>>.data(<String>[])
            : ref.watch(resultSectionsProvider((
                standardId: _selectedStandardId!,
                academicYearId: activeYearId,
              )));
    final examsAsync = ref.watch(examListProvider((
      studentId: null,
      academicYearId: activeYearId,
      standardId: _selectedStandardId,
    )));

    final studentsAsync =
        (_selectedStandardId == null || _selectedStandardId!.isEmpty)
            ? const AsyncValue<List<StudentModel>>.data(<StudentModel>[])
            : ref.watch(_studentsByClassSectionProvider((
                standardId: _selectedStandardId!,
                section: _selectedSection,
                academicYearId: activeYearId,
              )));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Results Distribution',
        showBack: true,
      ),
      body: Column(
        children: [
          _FiltersPanel(
            standardsAsync: standardsAsync,
            sectionsAsync: sectionsAsync,
            examsAsync: examsAsync,
            studentsAsync: studentsAsync,
            selectedStandardId: _selectedStandardId,
            selectedSection: _selectedSection,
            selectedExamId: _selectedExamId,
            selectedStudentId: _selectedStudentId,
            onStandardChanged: (value) {
              setState(() {
                _selectedStandardId = value;
                _selectedSection = null;
                _selectedExamId = null;
                _selectedStudentId = null;
              });
            },
            onSectionChanged: (value) {
              setState(() {
                _selectedSection = value;
                _selectedStudentId = null;
              });
            },
            onExamChanged: (value) => setState(() => _selectedExamId = value),
            onStudentChanged: (value) =>
                setState(() => _selectedStudentId = value),
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(
            child: examsAsync.when(
              loading: () => AppLoading.listView(count: 4),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (exams) {
                if (_selectedStandardId != null && exams.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.assessment_outlined,
                    title: 'No exams found',
                    subtitle: 'Teachers have not created exams for this class.',
                  );
                }

                final resolvedExamId = (_selectedExamId != null &&
                        exams.any((e) => e.id == _selectedExamId))
                    ? _selectedExamId!
                    : (exams.isNotEmpty ? exams.first.id : null);

                if (_selectedExamId != resolvedExamId &&
                    resolvedExamId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _selectedExamId = resolvedExamId);
                  });
                }

                if (resolvedExamId == null) {
                  return const AppEmptyState(
                    icon: Icons.filter_alt_outlined,
                    title: 'Select Filters',
                    subtitle: 'Choose class and exam to view results.',
                  );
                }

                final distributionAsync = ref.watch(
                  examDistributionProvider((
                    examId: resolvedExamId,
                    section: _selectedSection,
                    studentId: _selectedStudentId,
                  )),
                );

                return distributionAsync.when(
                  loading: () => AppLoading.listView(count: 4),
                  error: (e, _) => AppErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(
                      examDistributionProvider((
                        examId: resolvedExamId,
                        section: _selectedSection,
                        studentId: _selectedStudentId,
                      )),
                    ),
                  ),
                  data: (distribution) {
                    if (distribution.items.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.analytics_outlined,
                        title: 'No marks found',
                        subtitle:
                            'No subject-wise marks found for selected filters.',
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: distribution.items.length,
                      itemBuilder: (context, index) {
                        final student = distribution.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _StudentSummaryCard(
                            student: student,
                            onTap: () => _showStudentDetails(context, student),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentDetails(
    BuildContext context,
    ResultDistributionStudentModel student,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        student.studentName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${student.totalObtained.toStringAsFixed(1)}/${student.totalMax.toStringAsFixed(1)}',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.infoBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: student.subjects.length,
                    separatorBuilder: (_, __) =>
                        Container(height: 1, color: AppColors.surface100),
                    itemBuilder: (context, i) {
                      final s = student.subjects[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                s.subjectName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.grey800,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${s.marksObtained.toStringAsFixed(1)}/${s.maxMarks.toStringAsFixed(1)}',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${s.percentage.toStringAsFixed(1)}%',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                s.gradeLetter ?? '-',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.standardsAsync,
    required this.sectionsAsync,
    required this.examsAsync,
    required this.studentsAsync,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedExamId,
    required this.selectedStudentId,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onExamChanged,
    required this.onStudentChanged,
  });

  final AsyncValue<dynamic> standardsAsync;
  final AsyncValue<dynamic> sectionsAsync;
  final AsyncValue<List<ExamModel>> examsAsync;
  final AsyncValue<List<StudentModel>> studentsAsync;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedExamId;
  final String? selectedStudentId;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onExamChanged;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    final standards = (standardsAsync.valueOrNull as List?) ?? const [];
    final sections = (sectionsAsync.valueOrNull as List?) ?? const [];
    final exams = examsAsync.valueOrNull ?? const <ExamModel>[];
    final students = studentsAsync.valueOrNull ?? const <StudentModel>[];

    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedStandardId,
                  decoration: _inputDecoration('Class'),
                  items: standards
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id.toString(),
                          child: Text(s.name.toString()),
                        ),
                      )
                      .toList(),
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: selectedSection,
                  decoration: _inputDecoration('Section'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...sections.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.toString(),
                        child: Text(s.toString()),
                      ),
                    ),
                  ],
                  onChanged:
                      selectedStandardId == null ? null : onSectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: exams.any((e) => e.id == selectedExamId)
                      ? selectedExamId
                      : null,
                  decoration: _inputDecoration('Exam'),
                  items: exams
                      .map(
                        (exam) => DropdownMenuItem<String>(
                          value: exam.id,
                          child: Text(exam.name),
                        ),
                      )
                      .toList(),
                  onChanged: onExamChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: selectedStudentId,
                  decoration: _inputDecoration('Student'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...students.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id,
                        child: Text(s.displayName),
                      ),
                    ),
                  ],
                  onChanged:
                      selectedStandardId == null ? null : onStudentChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _StudentSummaryCard extends StatelessWidget {
  const _StudentSummaryCard({required this.student, required this.onTap});

  final ResultDistributionStudentModel student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Adm: ${student.admissionNumber}'
                      '${student.section != null ? '  •  Sec ${student.section}' : ''}'
                      '${student.rollNumber != null ? '  •  Roll ${student.rollNumber}' : ''}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${student.overallPercentage.toStringAsFixed(1)}%',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.infoBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${student.totalObtained.toStringAsFixed(1)}/${student.totalMax.toStringAsFixed(1)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
