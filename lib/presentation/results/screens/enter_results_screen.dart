import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

typedef _ExamSetupParams = ({
  String examId,
  String standardId,
  String? section,
});

typedef _ExistingMarksParams = ({
  String examId,
  String? section,
});

final _examSetupProvider =
    FutureProvider.family<_ExamSetupData, _ExamSetupParams>(
  (ref, params) async {
    if (params.examId.isEmpty || params.standardId.isEmpty) {
      throw Exception('Exam and class are required to enter results.');
    }

    final activeYear = ref.watch(activeYearProvider);
    final exams = await ref.watch(
      examListProvider((
        studentId: null,
        academicYearId: null,
        standardId: params.standardId,
      )).future,
    );
    ExamModel? selectedExam;
    for (final exam in exams) {
      if (exam.id == params.examId) {
        selectedExam = exam;
        break;
      }
    }
    final resolvedAcademicYearId =
        selectedExam?.academicYearId ?? activeYear?.id;
    if (resolvedAcademicYearId == null || resolvedAcademicYearId.isEmpty) {
      throw Exception('No academic year context found for selected exam.');
    }

    final assignments = await ref.watch(
      myTeacherAssignmentsProvider(resolvedAcademicYearId).future,
    );

    final normalizedSection = params.section?.trim();
    TeacherClassSubjectModel? selectedAssignment;
    for (final assignment in assignments) {
      if (assignment.standardId != params.standardId) continue;
      if (normalizedSection != null &&
          normalizedSection.isNotEmpty &&
          assignment.section != normalizedSection) {
        continue;
      }
      selectedAssignment = assignment;
      break;
    }

    if (selectedAssignment == null) {
      throw Exception('No teacher assignment found for selected class.');
    }
    final selectedAssignmentValue = selectedAssignment;

    final studentRepo = ref.read(studentRepositoryProvider);

    final effectiveSection =
        (normalizedSection != null && normalizedSection.isNotEmpty)
            ? normalizedSection
            : selectedAssignmentValue.section.trim();

    Future<List<StudentModel>> fetchStudentsForScope({
      required String? academicYearId,
      required String? section,
    }) async {
      final students = <StudentModel>[];
      var page = 1;
      var totalPages = 1;
      do {
        final result = await studentRepo.list(
          standardId: params.standardId,
          section: section,
          academicYearId: academicYearId,
          page: page,
          pageSize: 100,
        );
        students.addAll(result.items);
        totalPages = result.totalPages <= 0 ? 1 : result.totalPages;
        page += 1;
      } while (page <= totalPages);
      return students;
    }

    // Permanent roster strategy:
    // 1) exam-year scoped students
    // 2) current class/section students (fallback for rollover inconsistencies)
    // 3) students already having marks in this exam (always include)
    final examYearStudents = await fetchStudentsForScope(
      academicYearId: resolvedAcademicYearId,
      section: effectiveSection,
    );
    final currentRosterStudents = await fetchStudentsForScope(
      academicYearId: null,
      section: effectiveSection,
    );
    final studentsById = <String, StudentModel>{
      for (final student in examYearStudents) student.id: student,
    };
    for (final student in currentRosterStudents) {
      studentsById.putIfAbsent(student.id, () => student);
    }

    // Fallback: if section-scoped roster is empty (common after promotions
    // or reassignment timing), load full class roster so marks entry is not blocked.
    if (studentsById.isEmpty) {
      final classWideStudents = await fetchStudentsForScope(
        academicYearId: resolvedAcademicYearId,
        section: null,
      );
      for (final student in classWideStudents) {
        studentsById.putIfAbsent(student.id, () => student);
      }
    }
    if (studentsById.isEmpty) {
      final classWideAnyYear = await fetchStudentsForScope(
        academicYearId: null,
        section: null,
      );
      for (final student in classWideAnyYear) {
        studentsById.putIfAbsent(student.id, () => student);
      }
    }

    try {
      final distribution = await ref.read(
        examDistributionProvider((
          examId: params.examId,
          section: selectedAssignmentValue.section,
          studentId: null,
        )).future,
      );
      for (final item in distribution.items) {
        if (studentsById.containsKey(item.studentId)) continue;
        try {
          final fetched = await studentRepo.getById(item.studentId);
          studentsById[item.studentId] = fetched;
        } catch (_) {
          // Ignore missing/inaccessible students; keep other roster entries.
        }
      }
    } catch (_) {
      // Distribution can fail for brand-new exams; roster still comes from class map.
    }

    final students = studentsById.values.toList();

    int rollOrder(StudentModel s) {
      final raw = s.rollNumber?.trim() ?? '';
      final match = RegExp(r'\d+').firstMatch(raw);
      return int.tryParse(match?.group(0) ?? '') ?? 999999;
    }

    students.sort((a, b) {
      final byRoll = rollOrder(a).compareTo(rollOrder(b));
      if (byRoll != 0) return byRoll;
      return a.admissionNumber
          .toLowerCase()
          .compareTo(b.admissionNumber.toLowerCase());
    });

    final scopedAssignments = assignments.where((assignment) {
      if (assignment.standardId != params.standardId) return false;
      if (normalizedSection == null || normalizedSection.isEmpty) return true;
      return assignment.section.trim() == normalizedSection;
    }).toList();
    if (scopedAssignments.isEmpty) {
      throw Exception(
          'No teacher assignment found for selected class/section.');
    }

    final examSubjects = <_ExamSubject>[];
    final seenSubjectIds = <String>{};
    for (final assignment in scopedAssignments) {
      final subjectId = assignment.subjectId.trim();
      if (subjectId.isEmpty || !seenSubjectIds.add(subjectId)) continue;
      final subjectName = assignment.subjectName?.trim().isNotEmpty == true
          ? assignment.subjectName!.trim()
          : 'Subject';
      final subjectCode = assignment.subjectCode?.trim().isNotEmpty == true
          ? assignment.subjectCode!.trim()
          : '';
      examSubjects.add(
        _ExamSubject(
          id: subjectId,
          name: subjectName,
          code: subjectCode,
          maxMarks: 100,
        ),
      );
    }
    if (examSubjects.isEmpty) {
      throw Exception('No assigned subjects found for this class/section.');
    }

    return _ExamSetupData(
      examName: selectedExam?.name ?? 'Selected Exam',
      standardName: selectedAssignmentValue.classLabel,
      students: students,
      subjects: examSubjects,
    );
  },
);

final _existingMarksProvider =
    FutureProvider.family<Map<String, _ExistingMark>, _ExistingMarksParams>(
  (ref, params) async {
    try {
      final distribution = await ref.watch(
        examDistributionProvider((
          examId: params.examId,
          section: params.section,
          studentId: null,
        )).future,
      );
      final existing = <String, _ExistingMark>{};
      for (final student in distribution.items) {
        for (final subject in student.subjects) {
          existing['${student.studentId}::${subject.subjectId}'] =
              _ExistingMark(
            marksObtained: subject.marksObtained,
            maxMarks: subject.maxMarks,
          );
        }
      }
      return existing;
    } catch (_) {
      return const <String, _ExistingMark>{};
    }
  },
);

class EnterResultsScreen extends ConsumerStatefulWidget {
  const EnterResultsScreen({
    super.key,
    this.examId,
    this.standardId,
    this.section,
  });

  final String? examId;
  final String? standardId;
  final String? section;

  @override
  ConsumerState<EnterResultsScreen> createState() => _EnterResultsScreenState();
}

class _EnterResultsScreenState extends ConsumerState<EnterResultsScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, Map<String, TextEditingController>> _marksControllers = {};
  final Map<String, Map<String, TextEditingController>> _maxControllers = {};
  final Set<String> _hydratedEntryKeys = <String>{};
  bool _isSubmitting = false;
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedExamId;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _selectedStandardId = widget.standardId;
    _selectedSection = widget.section;
    _selectedExamId = widget.examId;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _disposeControllers();
    _animCtrl.dispose();
    super.dispose();
  }

  void _disposeControllers() {
    for (final studentMap in _marksControllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    for (final studentMap in _maxControllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    _marksControllers.clear();
    _maxControllers.clear();
    _hydratedEntryKeys.clear();
  }

  void _resetEntryInputs() {
    _disposeControllers();
  }

  TextEditingController _getMarksCtrl(String studentId, String subjectId) {
    _marksControllers[studentId] ??= {};
    _marksControllers[studentId]![subjectId] ??= TextEditingController();
    return _marksControllers[studentId]![subjectId]!;
  }

  TextEditingController _getMaxCtrl(
      String studentId, String subjectId, double defaultMaxMarks) {
    _maxControllers[studentId] ??= {};
    _maxControllers[studentId]![subjectId] ??=
        TextEditingController(text: defaultMaxMarks.toStringAsFixed(0));
    return _maxControllers[studentId]![subjectId]!;
  }

  bool _looksLikeDuplicateSaveError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('already exists') ||
        lower.contains('duplicate') ||
        lower.contains('uq_result_exam_student_subject') ||
        lower.contains('unique constraint');
  }

  String _entryKey(String studentId, String subjectId) {
    return '$studentId::$subjectId';
  }

  String _formatNumericValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  void _hydrateExistingEntries(
    _ExamSetupData examSetup,
    Map<String, _ExistingMark> existingMarks,
  ) {
    for (final student in examSetup.students) {
      for (final subject in examSetup.subjects) {
        final key = _entryKey(student.id, subject.id);
        if (_hydratedEntryKeys.contains(key)) continue;

        final marksCtrl = _getMarksCtrl(student.id, subject.id);
        final maxCtrl = _getMaxCtrl(student.id, subject.id, subject.maxMarks);
        final existing = existingMarks[key];
        if (existing != null) {
          if (marksCtrl.text.trim().isEmpty) {
            marksCtrl.text = _formatNumericValue(existing.marksObtained);
          }
          if (maxCtrl.text.trim().isEmpty ||
              maxCtrl.text.trim() == subject.maxMarks.toStringAsFixed(0)) {
            maxCtrl.text = _formatNumericValue(existing.maxMarks);
          }
        }
        _hydratedEntryKeys.add(key);
      }
    }
  }

  Future<void> _submit(_ExamSetupData examSetup) async {
    final examId = widget.examId ?? _selectedExamId;
    if (examId == null || examId.isEmpty) {
      SnackbarUtils.showError(context, 'Exam is not selected.');
      return;
    }

    final entries = <Map<String, dynamic>>[];
    String? validationError;
    for (final student in examSetup.students) {
      for (final subject in examSetup.subjects) {
        final marksCtrl = _getMarksCtrl(student.id, subject.id);
        final maxCtrl = _getMaxCtrl(student.id, subject.id, subject.maxMarks);
        final marksText = marksCtrl.text.trim();
        final maxText = maxCtrl.text.trim();

        final hasMarks = marksText.isNotEmpty;
        final hasMax = maxText.isNotEmpty;
        if (!hasMarks && !hasMax) {
          continue;
        }

        final marks = double.tryParse(marksText);
        final maxMarks = double.tryParse(maxText);
        if (!hasMarks || marks == null || marks < 0) {
          validationError =
              'Enter valid obtained marks for ${student.displayName} (${subject.name}).';
          break;
        }
        if (!hasMax || maxMarks == null || maxMarks <= 0) {
          validationError =
              'Enter valid total marks for ${student.displayName} (${subject.name}).';
          break;
        }
        if (marks > maxMarks) {
          validationError =
              'Obtained marks cannot exceed total marks for ${student.displayName} (${subject.name}).';
          break;
        }

        entries.add({
          'student_id': student.id,
          'subject_id': subject.id,
          'marks_obtained': marks,
          'max_marks': maxMarks,
        });
      }
      if (validationError != null) break;
    }

    if (validationError != null) {
      SnackbarUtils.showError(context, validationError);
      return;
    }

    if (entries.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter at least one mark.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await ref.read(enterResultsProvider.notifier).bulkEnter(
            examId: examId,
            entries: entries,
          );
      if (mounted && result != null) {
        SnackbarUtils.showSuccess(context, 'Results saved successfully.');
      } else if (mounted) {
        final err =
            ref.read(enterResultsProvider).error ?? 'Failed to save results.';
        if (_looksLikeDuplicateSaveError(err)) {
          SnackbarUtils.showInfo(
            context,
            'Results already exist. Edit marks and save again to update.',
          );
          return;
        }
        SnackbarUtils.showError(context, err);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _refreshEnterResultsData() async {
    final activeYear = ref.read(activeYearProvider);
    ref.invalidate(academicYearNotifierProvider);
    if (activeYear != null) {
      ref.invalidate(myTeacherAssignmentsProvider(activeYear.id));
    }

    final resolvedExamId = _selectedExamId ?? widget.examId;
    final resolvedStandardId = _selectedStandardId ?? widget.standardId;
    final resolvedSection = _selectedSection ?? widget.section;

    if (resolvedStandardId != null &&
        resolvedStandardId.isNotEmpty &&
        activeYear != null) {
      ref.invalidate(
        examListProvider((
          studentId: null,
          academicYearId: activeYear.id,
          standardId: resolvedStandardId,
        )),
      );
    }

    if (resolvedExamId != null &&
        resolvedExamId.isNotEmpty &&
        resolvedStandardId != null &&
        resolvedStandardId.isNotEmpty) {
      ref.invalidate(
        _examSetupProvider((
          examId: resolvedExamId,
          standardId: resolvedStandardId,
          section: resolvedSection,
        )),
      );
      ref.invalidate(
        _existingMarksProvider((
          examId: resolvedExamId,
          section: resolvedSection,
        )),
      );
      ref.invalidate(
        examDistributionProvider((
          examId: resolvedExamId,
          section: resolvedSection,
          studentId: null,
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final resolvedExamId = _selectedExamId ?? widget.examId;
    final resolvedStandardId = _selectedStandardId ?? widget.standardId;
    final resolvedSection = _selectedSection ?? widget.section;
    final existingMarksAsync =
        (resolvedExamId == null || resolvedExamId.isEmpty)
            ? const AsyncValue<Map<String, _ExistingMark>>.data(
                <String, _ExistingMark>{},
              )
            : ref.watch(_existingMarksProvider((
                examId: resolvedExamId,
                section: resolvedSection,
              )));
    final canCreateExam = currentUser?.role.isSchoolScopedAdmin ?? false;
    final canUploadPdf = currentUser != null &&
        currentUser.hasPermission('result:create') &&
        (currentUser.role == UserRole.teacher ||
            currentUser.role.isSchoolScopedAdmin);

    final assignmentsAsync = activeYear == null
        ? const AsyncValue<List<TeacherClassSubjectModel>>.data(
            <TeacherClassSubjectModel>[],
          )
        : ref.watch(myTeacherAssignmentsProvider(activeYear.id));

    final examsAsync = (resolvedStandardId == null || activeYear == null)
        ? const AsyncValue<List<ExamModel>>.data(<ExamModel>[])
        : ref.watch(
            examListProvider((
              studentId: null,
              academicYearId: activeYear.id,
              standardId: resolvedStandardId,
            )),
          );

    final needsSelection = resolvedExamId == null ||
        resolvedExamId.isEmpty ||
        resolvedStandardId == null ||
        resolvedStandardId.isEmpty;
    if (needsSelection) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(
          title: 'Enter Results',
          showBack: true,
          onBackPressed: () => context.go(RouteNames.dashboard),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
              onPressed: () => _refreshEnterResultsData(),
            ),
          ],
        ),
        body: _SelectionPanel(
          assignmentsAsync: assignmentsAsync,
          examsAsync: examsAsync,
          selectedStandardId: resolvedStandardId,
          selectedSection: resolvedSection,
          selectedExamId: resolvedExamId,
          onClassSectionChanged: (standardId, section) {
            setState(() {
              _resetEntryInputs();
              _selectedStandardId = standardId;
              _selectedSection = section;
              _selectedExamId = null;
            });
          },
          onExamChanged: (examId) {
            setState(() {
              _resetEntryInputs();
              _selectedExamId = examId;
            });
          },
          canCreateExam: canCreateExam,
          onCreateExam: !canCreateExam
              ? null
              : (standardId) async {
                  if (activeYear == null) return;
                  final created = await _openCreateExamDialog(
                    context: context,
                    standardId: standardId,
                    academicYearId: activeYear.id,
                    academicYearStartDate: activeYear.startDate,
                    academicYearEndDate: activeYear.endDate,
                  );
                  if (created != null) {
                    ref.invalidate(
                      examListProvider((
                        studentId: null,
                        academicYearId: activeYear.id,
                        standardId: standardId,
                      )),
                    );
                    setState(() => _selectedExamId = created.id);
                  }
                },
        ),
      );
    }

    final examSetupAsync = ref.watch(
      _examSetupProvider((
        examId: resolvedExamId,
        standardId: resolvedStandardId,
        section: resolvedSection,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Enter Results',
        showBack: true,
        onBackPressed: () {
          setState(() {
            _resetEntryInputs();
            _selectedExamId = null;
            _selectedStandardId = null;
            _selectedSection = null;
          });
        },
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            onPressed: () => _refreshEnterResultsData(),
          ),
        ],
      ),
      body: examSetupAsync.when(
        loading: _buildShimmer,
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (examSetup) {
          if (existingMarksAsync.hasValue) {
            _hydrateExistingEntries(
                examSetup, existingMarksAsync.valueOrNull ?? const {});
          }
          return FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Column(
                children: [
                  _ExamInfoBar(examSetup: examSetup),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      itemCount: examSetup.students.length,
                      itemBuilder: (context, i) {
                        final student = examSetup.students[i];
                        return _StudentResultCard(
                          student: student,
                          subjects: examSetup.subjects,
                          canUploadPdf: canUploadPdf,
                          onUploadPdf: () => context.push(
                            RouteNames.reportCard,
                            extra: {
                              'studentId': student.id,
                              'examId': resolvedExamId,
                            },
                          ),
                          getMarksController: (subjectId) =>
                              _getMarksCtrl(student.id, subjectId),
                          getMaxController: (subjectId, defaultMax) =>
                              _getMaxCtrl(student.id, subjectId, defaultMax),
                        );
                      },
                    ),
                  ),
                  _SubmitBar(
                    studentCount: examSetup.students.length,
                    subjectCount: examSetup.subjects.length,
                    isSubmitting: _isSubmitting,
                    onSubmit: () => _submit(examSetup),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppLoading.card(height: 140),
      ),
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
                      SnackbarUtils.showError(
                        dialogContext,
                        'Exam name is required.',
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
                      SnackbarUtils.showError(
                        dialogContext,
                        ref.read(createExamProvider).error ??
                            'Could not create exam for all classes.',
                      );
                      return;
                    }
                    if (!createForAllClasses && created == null) {
                      SnackbarUtils.showError(
                        dialogContext,
                        ref.read(createExamProvider).error ??
                            'Could not create exam.',
                      );
                      return;
                    }
                    createdExam = createForAllClasses
                        ? (bulkCreated!.created.isNotEmpty
                            ? bulkCreated.created.first
                            : null)
                        : created;
                    if (createForAllClasses) {
                      SnackbarUtils.showSuccess(
                        dialogContext,
                        'Exam created for ${bulkCreated!.createdCount} classes'
                        '${bulkCreated.skippedCount > 0 ? ' (${bulkCreated.skippedCount} skipped)' : ''}.',
                      );
                    } else {
                      SnackbarUtils.showSuccess(dialogContext, 'Exam created.');
                    }
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

class _SelectionPanel extends StatelessWidget {
  const _SelectionPanel({
    required this.assignmentsAsync,
    required this.examsAsync,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedExamId,
    required this.onClassSectionChanged,
    required this.onExamChanged,
    required this.canCreateExam,
    required this.onCreateExam,
  });

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;
  final AsyncValue<List<ExamModel>> examsAsync;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedExamId;
  final void Function(String standardId, String section) onClassSectionChanged;
  final ValueChanged<String?> onExamChanged;
  final bool canCreateExam;
  final Future<void> Function(String standardId)? onCreateExam;

  @override
  Widget build(BuildContext context) {
    final classes =
        assignmentsAsync.valueOrNull ?? const <TeacherClassSubjectModel>[];
    final uniqueClasses = <TeacherClassSubjectModel>[];
    final seen = <String>{};
    for (final item in classes) {
      final key = '${item.standardId}::${item.section}';
      if (seen.add(key)) uniqueClasses.add(item);
    }
    final exams = examsAsync.valueOrNull ?? const <ExamModel>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Class & Exam',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: uniqueClasses.any((c) =>
                        c.standardId == selectedStandardId &&
                        c.section == selectedSection)
                    ? '${selectedStandardId!}::${selectedSection ?? ''}'
                    : null,
                items: uniqueClasses
                    .map(
                      (c) => DropdownMenuItem<String>(
                        value: '${c.standardId}::${c.section}',
                        child: Text(c.classLabel),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Class & Section',
                ),
                onChanged: (value) {
                  if (value == null) return;
                  final split = value.split('::');
                  if (split.length != 2) return;
                  onClassSectionChanged(split[0], split[1]);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: exams.any((e) => e.id == selectedExamId)
                    ? selectedExamId
                    : null,
                items: exams
                    .map(
                      (exam) => DropdownMenuItem<String>(
                        value: exam.id,
                        child: Text(exam.name),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(labelText: 'Exam'),
                onChanged: onExamChanged,
              ),
              const SizedBox(height: 10),
              if (canCreateExam)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed:
                        selectedStandardId == null || onCreateExam == null
                            ? null
                            : () => onCreateExam!(selectedStandardId!),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Exam'),
                  ),
                ),
              if (selectedExamId == null || selectedExamId!.isEmpty)
                Text(
                  canCreateExam
                      ? 'Create or select an exam to start entering subject-wise marks.'
                      : 'Select an exam defined by the principal to enter marks.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExamInfoBar extends StatelessWidget {
  const _ExamInfoBar({required this.examSetup});
  final _ExamSetupData examSetup;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.edit_document,
              size: 20,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  examSetup.examName,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  examSetup.standardName,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey500,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${examSetup.subjects.length} Subjects',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.navyMedium,
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

class _StudentResultCard extends StatelessWidget {
  const _StudentResultCard({
    required this.student,
    required this.subjects,
    required this.getMarksController,
    required this.getMaxController,
    required this.canUploadPdf,
    required this.onUploadPdf,
  });

  final StudentModel student;
  final List<_ExamSubject> subjects;
  final TextEditingController Function(String subjectId) getMarksController;
  final TextEditingController Function(String subjectId, double defaultMax)
      getMaxController;
  final bool canUploadPdf;
  final VoidCallback onUploadPdf;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarBackground(student.admissionNumber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.initials,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.displayName,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (student.rollNumber != null &&
                          student.rollNumber!.isNotEmpty)
                        Text(
                          'Roll ${student.rollNumber}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey400,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (canUploadPdf)
                  TextButton.icon(
                    onPressed: onUploadPdf,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 15),
                    label: const Text('Upload PDF'),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: subjects.asMap().entries.map((entry) {
                final subject = entry.value;
                final isLast = entry.key == subjects.length - 1;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
                  child: _SubjectMarksRow(
                    subjectName: subject.name,
                    maxMarks: subject.maxMarks,
                    marksController: getMarksController(subject.id),
                    maxMarksController:
                        getMaxController(subject.id, subject.maxMarks),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubjectMarksRow extends StatelessWidget {
  const _SubjectMarksRow({
    required this.subjectName,
    required this.maxMarks,
    required this.marksController,
    required this.maxMarksController,
  });

  final String subjectName;
  final double maxMarks;
  final TextEditingController marksController;
  final TextEditingController maxMarksController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            subjectName,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          height: 38,
          child: TextField(
            controller: marksController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: '—',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surface50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surface200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.navyMedium, width: 1.5),
              ),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const Text('/', style: TextStyle(color: AppColors.grey400)),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          height: 38,
          child: TextField(
            controller: maxMarksController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey800,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: maxMarks.toStringAsFixed(0),
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey400,
                fontSize: 13,
              ),
              filled: true,
              fillColor: AppColors.surface50,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surface200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.navyMedium, width: 1.5),
              ),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.studentCount,
    required this.subjectCount,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final int studentCount;
  final int subjectCount;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline_rounded,
                size: 14,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                '$studentCount students · $subjectCount subjects',
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey400,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppButton.primary(
            label: 'Save Results',
            onTap: isSubmitting ? null : onSubmit,
            isLoading: isSubmitting,
            icon: Icons.save_outlined,
          ),
        ],
      ),
    );
  }
}

class _ExamSetupData {
  const _ExamSetupData({
    required this.examName,
    required this.standardName,
    required this.students,
    required this.subjects,
  });

  final String examName;
  final String standardName;
  final List<StudentModel> students;
  final List<_ExamSubject> subjects;
}

class _ExamSubject {
  const _ExamSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.maxMarks,
  });

  final String id;
  final String name;
  final String code;
  final double maxMarks;
}

class _ExistingMark {
  const _ExistingMark({
    required this.marksObtained,
    required this.maxMarks,
  });

  final double marksObtained;
  final double maxMarks;
}
