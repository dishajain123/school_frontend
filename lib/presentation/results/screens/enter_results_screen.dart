import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/masters_provider.dart';
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

final _examSetupProvider =
    FutureProvider.family<_ExamSetupData, _ExamSetupParams>(
  (ref, params) async {
    if (params.examId.isEmpty || params.standardId.isEmpty) {
      throw Exception('Exam and class are required to enter results.');
    }

    final activeYear = ref.watch(activeYearProvider);
    if (activeYear == null) {
      throw Exception('No active academic year found.');
    }

    final assignments =
        await ref.watch(myTeacherAssignmentsProvider(activeYear.id).future);

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

    final students = await ref.watch(
      studentsForAttendanceProvider(
        (
          standardId: params.standardId,
          section: selectedAssignment.section,
          academicYearId: activeYear.id,
        ),
      ).future,
    );

    final subjects =
        await ref.watch(subjectsProvider(params.standardId).future);
    final exams = await ref.watch(
      examListProvider((
        studentId: null,
        academicYearId: activeYear.id,
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

    final examSubjects = subjects
        .map(
          (s) => _ExamSubject(
            id: s.id,
            name: s.name,
            code: s.code,
            maxMarks: 100,
          ),
        )
        .toList();

    return _ExamSetupData(
      examName: selectedExam?.name ?? 'Selected Exam',
      standardName: selectedAssignment.classLabel,
      students: students,
      subjects: examSubjects,
    );
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
  final Map<String, Map<String, TextEditingController>> _controllers = {};
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
    for (final studentMap in _controllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    _animCtrl.dispose();
    super.dispose();
  }

  TextEditingController _getCtrl(String studentId, String subjectId) {
    _controllers[studentId] ??= {};
    _controllers[studentId]![subjectId] ??= TextEditingController();
    return _controllers[studentId]![subjectId]!;
  }

  Future<void> _submit(_ExamSetupData examSetup) async {
    final examId = widget.examId ?? _selectedExamId;
    if (examId == null || examId.isEmpty) {
      SnackbarUtils.showError(context, 'Exam is not selected.');
      return;
    }

    final subjectMaxById = <String, double>{
      for (final subject in examSetup.subjects) subject.id: subject.maxMarks,
    };
    final entries = <Map<String, dynamic>>[];
    for (final entry in _controllers.entries) {
      final studentId = entry.key;
      for (final subEntry in entry.value.entries) {
        final subjectId = subEntry.key;
        final marks = double.tryParse(subEntry.value.text.trim());
        final maxMarks = subjectMaxById[subjectId] ?? 100;
        if (marks != null) {
          entries.add({
            'student_id': studentId,
            'subject_id': subjectId,
            'marks_obtained': marks,
            'max_marks': maxMarks,
          });
        }
      }
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
        context.pop(true);
      } else if (mounted) {
        SnackbarUtils.showError(context, 'Failed to save results.');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final resolvedExamId = widget.examId ?? _selectedExamId;
    final resolvedStandardId = widget.standardId ?? _selectedStandardId;
    final resolvedSection = widget.section ?? _selectedSection;

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
        appBar: const AppAppBar(title: 'Enter Results', showBack: true),
        body: _SelectionPanel(
          assignmentsAsync: assignmentsAsync,
          examsAsync: examsAsync,
          selectedStandardId: resolvedStandardId,
          selectedSection: resolvedSection,
          selectedExamId: resolvedExamId,
          onClassSectionChanged: (standardId, section) {
            setState(() {
              _selectedStandardId = standardId;
              _selectedSection = section;
              _selectedExamId = null;
            });
          },
          onExamChanged: (examId) => setState(() => _selectedExamId = examId),
          onCreateExam: (standardId) async {
            if (activeYear == null) return;
            final created = await _openCreateExamDialog(
              context: context,
              standardId: standardId,
              academicYearId: activeYear.id,
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
      appBar: const AppAppBar(
        title: 'Enter Results',
        showBack: true,
      ),
      body: examSetupAsync.when(
        loading: _buildShimmer,
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (examSetup) {
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
                          getController: (subjectId) =>
                              _getCtrl(student.id, subjectId),
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
  }) async {
    final nameCtrl = TextEditingController();
    ExamType selectedType = ExamType.unitTest;
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now();
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ExamType>(
                      initialValue: selectedType,
                      items: ExamType.values
                          .where((e) => e != ExamType.other)
                          .map(
                            (e) => DropdownMenuItem<ExamType>(
                              value: e,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setModalState(() => selectedType = value);
                      },
                      decoration: const InputDecoration(labelText: 'Exam Type'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
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
                                lastDate: DateTime(2100),
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
                    final created = await ref
                        .read(createExamProvider.notifier)
                        .createExam(
                          name: examName,
                          examType: selectedType.backendValue,
                          standardId: standardId,
                          academicYearId: academicYearId,
                          startDate:
                              startDate.toIso8601String().split("T").first,
                          endDate: endDate.toIso8601String().split("T").first,
                        );
                    if (!dialogContext.mounted) return;
                    if (created == null) {
                      SnackbarUtils.showError(
                        dialogContext,
                        ref.read(createExamProvider).error ??
                            'Could not create exam.',
                      );
                      return;
                    }
                    createdExam = created;
                    SnackbarUtils.showSuccess(dialogContext, 'Exam created.');
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
    required this.onCreateExam,
  });

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;
  final AsyncValue<List<ExamModel>> examsAsync;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedExamId;
  final void Function(String standardId, String section) onClassSectionChanged;
  final ValueChanged<String?> onExamChanged;
  final Future<void> Function(String standardId) onCreateExam;

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
                        child: Text('${exam.name} (${exam.examType.label})'),
                      ),
                    )
                    .toList(),
                decoration: const InputDecoration(labelText: 'Exam'),
                onChanged: onExamChanged,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: selectedStandardId == null
                      ? null
                      : () => onCreateExam(selectedStandardId!),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Create Exam'),
                ),
              ),
              if (selectedExamId == null || selectedExamId!.isEmpty)
                Text(
                  'Create or select an exam to start entering subject-wise marks.',
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
    required this.getController,
  });

  final StudentModel student;
  final List<_ExamSubject> subjects;
  final TextEditingController Function(String subjectId) getController;

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
                    controller: getController(subject.id),
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
    required this.controller,
  });

  final String subjectName;
  final double maxMarks;
  final TextEditingController controller;

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
            controller: controller,
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
        Text(
          '/${maxMarks.toStringAsFixed(0)}',
          style: AppTypography.caption.copyWith(
            color: AppColors.grey400,
            fontSize: 11,
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
