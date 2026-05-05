import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
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
  const PrincipalResultsDistributionScreen({
    super.key,
    this.initialStandardId,
    this.initialSection,
    this.initialExamId,
  });

  final String? initialStandardId;
  final String? initialSection;
  final String? initialExamId;

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

  bool _isNoTeacherEntriesError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('no result entries found that were entered by you');
  }

  @override
  void initState() {
    super.initState();
    _selectedStandardId = widget.initialStandardId;
    _selectedSection = widget.initialSection;
    _selectedExamId = widget.initialExamId;
  }

  Future<void> _refreshPrincipalResultsData() async {
    final activeYear = ref.read(activeYearProvider);
    final activeYearId = activeYear?.id;
    final currentUser = ref.read(currentUserProvider);
    final isTeacher = currentUser?.role == UserRole.teacher;

    ref.invalidate(academicYearNotifierProvider);

    if (activeYearId != null && activeYearId.isNotEmpty) {
      ref.invalidate(standardsProvider(activeYearId));
      if (isTeacher) {
        ref.invalidate(myTeacherAssignmentsProvider(activeYearId));
        ref.invalidate(
          examListProvider((
            studentId: null,
            academicYearId: activeYearId,
            standardId: null,
          )),
        );
      }
    }

    final standardId = _selectedStandardId;
    if (standardId != null &&
        standardId.isNotEmpty &&
        activeYearId != null &&
        activeYearId.isNotEmpty) {
      ref.invalidate(
        resultSectionsProvider((
          standardId: standardId,
          academicYearId: activeYearId,
        )),
      );
      ref.invalidate(
        examListProvider((
          studentId: null,
          academicYearId: activeYearId,
          standardId: standardId,
        )),
      );
      ref.invalidate(
        _studentsByClassSectionProvider((
          standardId: standardId,
          section: _selectedSection,
          academicYearId: activeYearId,
        )),
      );
    }

    final examId = _selectedExamId;
    if (examId != null && examId.isNotEmpty) {
      ref.invalidate(
        examDistributionProvider((
          examId: examId,
          section: _selectedSection,
          studentId: _selectedStudentId,
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final activeYearId = activeYear?.id;
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.role == UserRole.teacher;
    final standardsCatalogAsync = ref.watch(standardsProvider(activeYearId));
    final teacherAssignmentsAsync = isTeacher
        ? ref.watch(myTeacherAssignmentsProvider(activeYearId))
        : const AsyncValue<List<TeacherClassSubjectModel>>.data(
            <TeacherClassSubjectModel>[],
          );
    final teacherHistoryExamsAsync = isTeacher
        ? ref.watch(examListProvider((
            studentId: null,
            academicYearId: activeYearId,
            standardId: null,
          )))
        : const AsyncValue<List<ExamModel>>.data(<ExamModel>[]);

    final standards = standardsCatalogAsync.valueOrNull ?? const [];
    final teacherAssignments = teacherAssignmentsAsync.valueOrNull ??
        const <TeacherClassSubjectModel>[];
    final teacherHistoryExams =
        teacherHistoryExamsAsync.valueOrNull ?? const <ExamModel>[];

    final standardOptions = isTeacher
        ? _buildTeacherStandardOptions(
            assignments: teacherAssignments,
            historyExams: teacherHistoryExams,
            standards: standards,
          )
        : standards
            .map((s) => _StandardOption(id: s.id, label: s.name))
            .toList();

    final selectedStandardId = standardOptions.any(
      (option) => option.id == _selectedStandardId,
    )
        ? _selectedStandardId
        : null;

    if (_selectedStandardId != selectedStandardId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedStandardId = selectedStandardId;
          _selectedSection = null;
          _selectedExamId = null;
          _selectedStudentId = null;
        });
      });
    }

    final sectionsAsync =
        (selectedStandardId == null || selectedStandardId.isEmpty)
            ? const AsyncValue<List<String>>.data(<String>[])
            : ref.watch(resultSectionsProvider((
                standardId: selectedStandardId,
                academicYearId: activeYearId,
              )));
    final examsAsync = ref.watch(examListProvider((
      studentId: null,
      academicYearId: activeYearId,
      standardId: selectedStandardId,
    )));

    final studentsAsync =
        (selectedStandardId == null || selectedStandardId.isEmpty)
            ? const AsyncValue<List<StudentModel>>.data(<StudentModel>[])
            : ref.watch(_studentsByClassSectionProvider((
                standardId: selectedStandardId,
                section: _selectedSection,
                academicYearId: activeYearId,
              )));

    return AppScaffold(
      appBar: AppAppBar(
        title: isTeacher ? 'Results' : 'Results Distribution',
        showBack: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _refreshPrincipalResultsData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip:
                'Class timetable for this class/year (same file for every exam)',
            onPressed: selectedStandardId == null || activeYearId == null
                ? null
                : () {
                    context.push(
                      RouteNames.timetableForExamClass(
                        standardId: selectedStandardId,
                        academicYearId: activeYearId,
                        section: _selectedSection,
                      ),
                    );
                  },
            icon: const Icon(Icons.schedule_outlined),
          ),
          if (isTeacher)
            IconButton(
              tooltip: 'Enter Marks',
              onPressed: () {
                if (_selectedStandardId == null || _selectedExamId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Select class and exam first to enter marks.'),
                    ),
                  );
                  return;
                }
                context.push(
                  RouteNames.enterResults,
                  extra: {
                    'examId': _selectedExamId,
                    'standardId': _selectedStandardId,
                    'section': _selectedSection,
                  },
                );
              },
              icon: const Icon(Icons.edit_note_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          _FiltersPanel(
            standardOptions: standardOptions,
            sectionsAsync: sectionsAsync,
            examsAsync: examsAsync,
            studentsAsync: studentsAsync,
            selectedStandardId: selectedStandardId,
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
            onCreateExam: isTeacher ||
                    selectedStandardId == null ||
                    activeYearId == null
                ? null
                : () async {
                    final created = await _openCreateExamDialog(
                      context: context,
                      standardId: selectedStandardId,
                      academicYearId: activeYearId,
                      academicYearStartDate: activeYear!.startDate,
                      academicYearEndDate: activeYear.endDate,
                    );
                    if (created == null || !mounted) return;
                    ref.invalidate(
                      examListProvider((
                        studentId: null,
                        academicYearId: activeYearId,
                        standardId: selectedStandardId,
                      )),
                    );
                    setState(() => _selectedExamId = created.id);
                  },
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(
            child: examsAsync.when(
              loading: () => AppLoading.listView(count: 4),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (exams) {
                if (selectedStandardId != null && exams.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.assessment_outlined,
                    title: 'No exams found',
                    subtitle: isTeacher
                        ? 'No exams are set up for this class in the active academic year yet. Exams created in the admin console appear here automatically.'
                        : 'Create principal-defined exams for this class first.',
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
                  error: (e, _) {
                    if (_isNoTeacherEntriesError(e)) {
                      return const AppEmptyState(
                        icon: Icons.analytics_outlined,
                        title: 'No marks found',
                        subtitle:
                            'No result entries entered by you for this exam yet.',
                      );
                    }
                    return AppErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(
                        examDistributionProvider((
                          examId: resolvedExamId,
                          section: _selectedSection,
                          studentId: _selectedStudentId,
                        )),
                      ),
                    );
                  },
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
                            onTap: () => _showStudentDetails(
                              context,
                              student,
                              resolvedExamId,
                            ),
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

  List<_StandardOption> _buildTeacherStandardOptions({
    required List<TeacherClassSubjectModel> assignments,
    required List<ExamModel> historyExams,
    required List<dynamic> standards,
  }) {
    final namesById = <String, String>{
      for (final standard in standards)
        standard.id.toString(): standard.name.toString(),
    };
    final optionsById = <String, _StandardOption>{};

    for (final assignment in assignments) {
      final id = assignment.standardId.trim();
      if (id.isEmpty) continue;
      final label = (assignment.standardName?.trim().isNotEmpty ?? false)
          ? assignment.standardName!.trim()
          : (namesById[id] ?? 'Class');
      optionsById[id] = _StandardOption(id: id, label: label);
    }

    for (final exam in historyExams) {
      final id = exam.standardId.trim();
      if (id.isEmpty || optionsById.containsKey(id)) continue;
      optionsById[id] = _StandardOption(
        id: id,
        label: namesById[id] ?? 'Class',
      );
    }

    final options = optionsById.values.toList();
    options
        .sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  void _showStudentDetails(
    BuildContext context,
    ResultDistributionStudentModel student,
    String examId,
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
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push(
                        RouteNames.reportCard,
                        extra: {
                          'studentId': student.studentId,
                          'examId': examId,
                        },
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: const Text('Download / upload report card'),
                  ),
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

  Future<ExamModel?> _openCreateExamDialog({
    required BuildContext context,
    required String standardId,
    required String academicYearId,
    required DateTime academicYearStartDate,
    required DateTime academicYearEndDate,
  }) async {
    final nameCtrl = TextEditingController();
    final minDate = DateUtils.dateOnly(academicYearStartDate);
    final maxDate = DateUtils.dateOnly(academicYearEndDate);
    final now = DateUtils.dateOnly(DateTime.now());
    final initialDate = now.isBefore(minDate)
        ? minDate
        : (now.isAfter(maxDate) ? maxDate : now);
    DateTime startDate = initialDate;
    DateTime endDate = initialDate;
    bool createForAllClasses = false;
    ExamModel? createdExam;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Create Exam'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Exam Name',
                        hintText: 'e.g. Midterm 2026',
                      ),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Create for all classes'),
                      subtitle: const Text(
                        'Create this exam for every class in this academic year',
                      ),
                      value: createForAllClasses,
                      onChanged: (value) {
                        setModalState(() => createForAllClasses = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: minDate,
                                lastDate: maxDate,
                                initialDate: startDate,
                              );
                              if (picked != null) {
                                setModalState(() => startDate = picked);
                              }
                            },
                            child: Text(
                              'Start ${startDate.toIso8601String().split("T").first}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: startDate,
                                lastDate: maxDate,
                                initialDate: endDate.isBefore(startDate)
                                    ? startDate
                                    : endDate,
                              );
                              if (picked != null) {
                                setModalState(() => endDate = picked);
                              }
                            },
                            child: Text(
                              'End ${endDate.toIso8601String().split("T").first}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final examName = nameCtrl.text.trim();
                    if (examName.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Exam name is required.'),
                        ),
                      );
                      return;
                    }
                    final created = !createForAllClasses
                        ? await ref
                            .read(createExamProvider.notifier)
                            .createExam(
                              name: examName,
                              standardId: standardId,
                              academicYearId: academicYearId,
                              startDate:
                                  startDate.toIso8601String().split("T").first,
                              endDate:
                                  endDate.toIso8601String().split("T").first,
                            )
                        : null;
                    final bulkCreated = createForAllClasses
                        ? await ref
                            .read(createExamProvider.notifier)
                            .createExamForAllClasses(
                              name: examName,
                              academicYearId: academicYearId,
                              startDate:
                                  startDate.toIso8601String().split("T").first,
                              endDate:
                                  endDate.toIso8601String().split("T").first,
                            )
                        : null;
                    if (!dialogContext.mounted) return;
                    if (createForAllClasses && bulkCreated == null) {
                      final error = ref.read(createExamProvider).error ??
                          'Could not create exam for all classes.';
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }
                    if (!createForAllClasses && created == null) {
                      final error = ref.read(createExamProvider).error ??
                          'Could not create exam.';
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                      return;
                    }
                    createdExam = createForAllClasses
                        ? (bulkCreated!.created.isNotEmpty
                            ? bulkCreated.created.first
                            : null)
                        : created;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          createForAllClasses
                              ? 'Exam created for ${bulkCreated!.createdCount} classes'
                                  '${bulkCreated.skippedCount > 0 ? ' (${bulkCreated.skippedCount} skipped)' : ''}.'
                              : 'Exam created.',
                        ),
                      ),
                    );
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    return createdExam;
  }
}

class _FiltersPanel extends StatelessWidget {
  const _FiltersPanel({
    required this.standardOptions,
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
    required this.onCreateExam,
  });

  final List<_StandardOption> standardOptions;
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
  final Future<void> Function()? onCreateExam;

  @override
  Widget build(BuildContext context) {
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
                  items: standardOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.id,
                          child: Text(option.label),
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
          if (onCreateExam != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onCreateExam,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create Exam'),
              ),
            ),
          ],
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

class _StandardOption {
  const _StandardOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
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
