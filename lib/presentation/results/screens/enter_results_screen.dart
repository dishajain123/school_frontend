import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/masters_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/result_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class EnterResultsScreen extends ConsumerStatefulWidget {
  const EnterResultsScreen({super.key});

  @override
  ConsumerState<EnterResultsScreen> createState() => _EnterResultsScreenState();
}

class _EnterResultsScreenState extends ConsumerState<EnterResultsScreen>
    with SingleTickerProviderStateMixin {
  // ── Step 1: Create exam ────────────────────────────────────────────────────
  final _examNameCtrl = TextEditingController();
  ExamType _selectedExamType = ExamType.unitTest;
  StandardModel? _selectedStandard;
  DateTime? _startDate;
  DateTime? _endDate;
  ExamModel? _createdExam;

  // ── Step 2: Enter results ──────────────────────────────────────────────────
  // Map: studentId -> subjectId -> marks
  final Map<String, Map<String, TextEditingController>> _marksControllers = {};
  double _maxMarks = 100.0;
  final _maxMarksCtrl = TextEditingController(text: '100');
  List<StudentModel> _students = [];
  List<SubjectModel> _subjects = [];
  bool _isLoadingStudents = false;

  int _step = 1;

  @override
  void dispose() {
    _examNameCtrl.dispose();
    _maxMarksCtrl.dispose();
    for (final studentMap in _marksControllers.values) {
      for (final ctrl in studentMap.values) {
        ctrl.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 3)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _createExam() async {
    if (_examNameCtrl.text.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Exam name is required');
      return;
    }
    if (_selectedStandard == null) {
      SnackbarUtils.showError(context, 'Please select a class');
      return;
    }
    if (_startDate == null || _endDate == null) {
      SnackbarUtils.showError(context, 'Please select exam dates');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      SnackbarUtils.showError(context, 'End date must be after start date');
      return;
    }

    final activeYear = ref.read(activeYearProvider);

    final exam = await ref.read(createExamProvider.notifier).createExam(
          name: _examNameCtrl.text.trim(),
          examType: _selectedExamType.backendValue,
          standardId: _selectedStandard!.id,
          startDate: DateFormatter.formatDateForApi(_startDate!),
          endDate: DateFormatter.formatDateForApi(_endDate!),
          academicYearId: activeYear?.id,
        );

    if (!mounted) return;

    if (exam != null) {
      _createdExam = exam;
      await _loadStudentsAndSubjects();
      setState(() => _step = 2);
    } else {
      final err = ref.read(createExamProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to create exam');
    }
  }

  Future<void> _loadStudentsAndSubjects() async {
    if (_selectedStandard == null) return;
    setState(() => _isLoadingStudents = true);
    try {
      // Load students for this standard
      await ref.read(studentNotifierProvider.notifier).setFilters(
            StudentFilters(standardId: _selectedStandard!.id),
          );
      final studentState = ref.read(studentNotifierProvider).valueOrNull;
      _students = studentState?.items ?? [];

      // Load subjects for this standard
      final subjects = await ref
          .read(mastersRepositoryProvider)
          .listSubjects(standardId: _selectedStandard!.id);
      _subjects = subjects;

      // Init controllers
      _marksControllers.clear();
      for (final student in _students) {
        _marksControllers[student.id] = {};
        for (final subject in _subjects) {
          _marksControllers[student.id]![subject.id] =
              TextEditingController();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
            context, 'Failed to load students: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  Future<void> _submitResults() async {
    if (_createdExam == null) return;

    final maxMarks = double.tryParse(_maxMarksCtrl.text.trim()) ?? 100.0;

    final entries = <Map<String, dynamic>>[];
    for (final student in _students) {
      for (final subject in _subjects) {
        final ctrl = _marksControllers[student.id]?[subject.id];
        if (ctrl == null || ctrl.text.trim().isEmpty) continue;
        final marks = double.tryParse(ctrl.text.trim());
        if (marks == null || marks < 0) continue;
        entries.add({
          'student_id': student.id,
          'subject_id': subject.id,
          'marks_obtained': marks,
          'max_marks': maxMarks,
        });
      }
    }

    if (entries.isEmpty) {
      SnackbarUtils.showError(
          context, 'Please enter at least one result');
      return;
    }

    final result = await ref.read(enterResultsProvider.notifier).bulkEnter(
          examId: _createdExam!.id,
          entries: entries,
        );

    if (!mounted) return;

    if (result != null) {
      SnackbarUtils.showSuccess(
          context, '${result.total} results entered successfully!');
      context.pop();
    } else {
      final err = ref.read(enterResultsProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to enter results');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: _step == 1 ? 'Create Exam' : 'Enter Results',
        showBack: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _step == 1
            ? _StepOneExamForm(
                key: const ValueKey('step1'),
                nameCtrl: _examNameCtrl,
                selectedExamType: _selectedExamType,
                selectedStandard: _selectedStandard,
                startDate: _startDate,
                endDate: _endDate,
                onExamTypeChanged: (t) =>
                    setState(() => _selectedExamType = t),
                onStandardChanged: (s) =>
                    setState(() => _selectedStandard = s),
                onPickStart: () => _pickDate(true),
                onPickEnd: () => _pickDate(false),
                onNext: _createExam,
              )
            : _isLoadingStudents
                ? AppLoading.fullPage()
                : _StepTwoResults(
                    key: const ValueKey('step2'),
                    exam: _createdExam!,
                    students: _students,
                    subjects: _subjects,
                    marksControllers: _marksControllers,
                    maxMarksCtrl: _maxMarksCtrl,
                    onSubmit: _submitResults,
                  ),
      ),
    );
  }
}

// ── Step 1 ────────────────────────────────────────────────────────────────────

class _StepOneExamForm extends ConsumerWidget {
  const _StepOneExamForm({
    super.key,
    required this.nameCtrl,
    required this.selectedExamType,
    required this.selectedStandard,
    required this.startDate,
    required this.endDate,
    required this.onExamTypeChanged,
    required this.onStandardChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onNext,
  });

  final TextEditingController nameCtrl;
  final ExamType selectedExamType;
  final StandardModel? selectedStandard;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<ExamType> onExamTypeChanged;
  final ValueChanged<StandardModel?> onStandardChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeYear = ref.watch(activeYearProvider);
    final standardsAsync = ref.watch(standardsProvider(activeYear?.id));
    final isLoading =
        ref.watch(createExamProvider.select((s) => s.isLoading));

    return Column(
      children: [
        _StepIndicator(current: 1, total: 2),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: nameCtrl,
                  label: 'Exam Name',
                  hint: 'e.g. Unit Test 1 – Science',
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppDimensions.space20),

                // Exam type chips
                Text(
                  'Exam Type',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimensions.space8),
                Wrap(
                  spacing: AppDimensions.space8,
                  runSpacing: AppDimensions.space8,
                  children: ExamType.values.map((type) {
                    final selected = selectedExamType == type;
                    return GestureDetector(
                      onTap: () => onExamTypeChanged(type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.navyDeep
                              : AppColors.surface100,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusSmall),
                          border: Border.all(
                            color: selected
                                ? AppColors.navyDeep
                                : AppColors.surface200,
                          ),
                        ),
                        child: Text(
                          type.label,
                          style: AppTypography.labelMedium.copyWith(
                            color: selected
                                ? AppColors.white
                                : AppColors.grey800,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Class selector
                Text(
                  'Class',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.grey600),
                ),
                const SizedBox(height: AppDimensions.space8),
                standardsAsync.when(
                  data: (standards) => _DropdownContainer<StandardModel>(
                    hint: 'Select class',
                    value: selectedStandard,
                    items: standards
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name,
                                  style: AppTypography.bodyMedium),
                            ))
                        .toList(),
                    onChanged: onStandardChanged,
                  ),
                  loading: () => AppLoading.card(height: 52),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Date pickers
                Row(
                  children: [
                    Expanded(
                      child: _DatePickerField(
                        label: 'Start Date',
                        value: startDate,
                        onTap: onPickStart,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: _DatePickerField(
                        label: 'End Date',
                        value: endDate,
                        onTap: onPickEnd,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space20,
            AppDimensions.space12,
            AppDimensions.space20,
            AppDimensions.space24,
          ),
          child: AppButton.primary(
            label: 'Create Exam & Continue',
            onTap: onNext,
            isLoading: isLoading,
            icon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}

// ── Step 2 ────────────────────────────────────────────────────────────────────

class _StepTwoResults extends ConsumerWidget {
  const _StepTwoResults({
    super.key,
    required this.exam,
    required this.students,
    required this.subjects,
    required this.marksControllers,
    required this.maxMarksCtrl,
    required this.onSubmit,
  });

  final ExamModel exam;
  final List<StudentModel> students;
  final List<SubjectModel> subjects;
  final Map<String, Map<String, TextEditingController>> marksControllers;
  final TextEditingController maxMarksCtrl;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading =
        ref.watch(enterResultsProvider.select((s) => s.isLoading));

    if (students.isEmpty) {
      return Column(
        children: [
          _StepIndicator(current: 2, total: 2),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.space24),
                child: Text(
                  'No students found for this class.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _StepIndicator(current: 2, total: 2),
        // Max marks field
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${students.length} students · ${subjects.length} subjects',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey400),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              SizedBox(
                width: 90,
                child: AppTextField(
                  controller: maxMarksCtrl,
                  label: 'Max Marks',
                  hint: '100',
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.surface100),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppDimensions.space64),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final subjectCtrls =
                  marksControllers[student.id] ?? {};
              return _StudentResultRow(
                student: student,
                subjects: subjects,
                controllers: subjectCtrls,
                isLast: index == students.length - 1,
              );
            },
          ),
        ),
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space20,
            AppDimensions.space12,
            AppDimensions.space20,
            AppDimensions.space24,
          ),
          child: AppButton.primary(
            label: 'Save Results',
            onTap: onSubmit,
            isLoading: isLoading,
            icon: Icons.save_outlined,
          ),
        ),
      ],
    );
  }
}

class _StudentResultRow extends StatelessWidget {
  const _StudentResultRow({
    required this.student,
    required this.subjects,
    required this.controllers,
    required this.isLast,
  });

  final StudentModel student;
  final List<SubjectModel> subjects;
  final Map<String, TextEditingController> controllers;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space8,
        AppDimensions.space16,
        0,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
              vertical: AppDimensions.space12,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.avatarBackground(
                        student.admissionNumber),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      student.initials,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.admissionNumber,
                        style: AppTypography.titleSmall,
                      ),
                      if (student.rollNumber != null)
                        Text(
                          'Roll: ${student.rollNumber}',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey400),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.surface100),
          // Subjects grid
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space12),
            child: Wrap(
              spacing: AppDimensions.space8,
              runSpacing: AppDimensions.space8,
              children: subjects.map((subject) {
                final ctrl = controllers[subject.id];
                return SizedBox(
                  width: (MediaQuery.sizeOf(context).width -
                          AppDimensions.space16 * 2 -
                          AppDimensions.space12 * 2 -
                          AppDimensions.space8) /
                      2,
                  child: AppTextField(
                    controller: ctrl,
                    label: subject.name,
                    hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    textInputAction: TextInputAction.next,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12, vertical: 10),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        AppDimensions.space12,
      ),
      child: Row(
        children: List.generate(total, (i) {
          final step = i + 1;
          final isDone = step < current;
          final isActive = step == current;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? AppColors.navyDeep
                          : AppColors.surface200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (step < total) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DropdownContainer<T> extends StatelessWidget {
  const _DropdownContainer({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.grey400)),
          style: AppTypography.bodyMedium
              .copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
              color: AppColors.surface200,
              width: AppDimensions.borderMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.grey600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormatter.formatDate(value!)
                        : 'Select date',
                    style: AppTypography.bodyMedium.copyWith(
                      color: value != null
                          ? AppColors.grey800
                          : AppColors.grey400,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppDimensions.iconSM,
                  color: AppColors.grey400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
