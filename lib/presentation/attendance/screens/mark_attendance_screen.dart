import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../widgets/student_attendance_tile.dart';

class MarkAttendanceScreen extends ConsumerStatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  ConsumerState<MarkAttendanceScreen> createState() =>
      _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends ConsumerState<MarkAttendanceScreen> {
  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  bool _filtersExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initActiveYear();
    });
  }

  void _initActiveYear() {
    final activeYear = ref.read(activeYearProvider);
    if (activeYear != null) {
      ref.read(markAttendanceProvider.notifier).setAcademicYear(activeYear.id);
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final state = ref.read(markAttendanceProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.date,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(markAttendanceProvider.notifier).setDate(picked);
    }
  }

  Future<void> _submit(List<String> studentIds) async {
    final success = await ref
        .read(markAttendanceProvider.notifier)
        .submit(orderedStudentIds: studentIds);
    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, 'Attendance marked successfully');
    } else {
      final err = ref.read(markAttendanceProvider).submitError ?? 'Failed';
      SnackbarUtils.showError(context, err);
    }
  }

  String _weekdayLabel(DateTime date) => _weekdayNames[date.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(markAttendanceProvider);
    final activeYear = ref.watch(activeYearProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Mark Attendance', showBack: true),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: InkWell(
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space12,
                  AppDimensions.space16,
                  AppDimensions.space12,
                ),
                child: Row(
                  children: [
                    Text(
                      'Filter Details',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _filtersExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.grey600,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space8,
                AppDimensions.space16,
                AppDimensions.space16,
              ),
              child: _CollapsedFiltersSummary(
                date: formState.date,
                day: _weekdayLabel(formState.date),
                academicYearName: activeYear?.name,
                assignment: formState.selectedAssignment,
                subjectId: formState.selectedSubjectId,
              ),
            ),
            secondChild: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date picker row
                  const _SectionLabel(label: 'Date'),
                  const SizedBox(height: AppDimensions.space8),
                  _DatePickerTile(
                    date: formState.date,
                    onTap: () => _pickDate(context),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _InfoRow(label: 'Day', value: _weekdayLabel(formState.date)),
                  const SizedBox(height: AppDimensions.space16),

                  // Academic year (read-only from active year)
                  if (activeYear == null)
                    AppLoading.listTile()
                  else
                    _InfoRow(label: 'Academic Year', value: activeYear.name),
                  const SizedBox(height: AppDimensions.space16),

                  // Class selector
                  const _SectionLabel(label: 'Class'),
                  const SizedBox(height: AppDimensions.space8),
                  _ClassDropdown(
                    academicYearId: formState.selectedAcademicYearId,
                    selectedAssignment: formState.selectedAssignment,
                    onChanged: (assignment) => ref
                        .read(markAttendanceProvider.notifier)
                        .setAssignment(assignment),
                  ),

                  if (formState.selectedAssignment != null) ...[
                    const SizedBox(height: AppDimensions.space16),
                    // Subject selector (filtered by selected assignment)
                    const _SectionLabel(label: 'Subject'),
                    const SizedBox(height: AppDimensions.space8),
                    _SubjectDropdown(
                      academicYearId: formState.selectedAcademicYearId,
                      selectedAssignment: formState.selectedAssignment,
                      selectedSubjectId: formState.selectedSubjectId,
                      onChanged: (subjectId) => ref
                          .read(markAttendanceProvider.notifier)
                          .setSubjectId(subjectId),
                    ),
                  ],
                ],
              ),
            ),
            crossFadeState: _filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
          const Divider(height: 1, color: AppColors.surface100),

          // ── Student List ─────────────────────────────────────────────
          Expanded(
            child: _StudentList(
              formState: formState,
              onStatusChanged: (studentId, status) => ref
                  .read(markAttendanceProvider.notifier)
                  .setStudentStatus(studentId, status),
              onSelectionChanged: (studentId, selected) => ref
                  .read(markAttendanceProvider.notifier)
                  .toggleStudentSelection(studentId, selected),
              onStudentsLoaded: (ids) =>
                  ref.read(markAttendanceProvider.notifier).initStudents(ids),
              onExistingLoaded: (records) => ref
                  .read(markAttendanceProvider.notifier)
                  .preloadExisting(records),
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: AppTypography.labelMedium.copyWith(color: AppColors.grey600));
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label: ',
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey400)),
        Text(value,
            style: AppTypography.titleSmall.copyWith(
                color: AppColors.navyDeep, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  String _format(DateTime d) {
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.navyMedium),
            const SizedBox(width: AppDimensions.space8),
            Text(_format(date),
                style:
                    AppTypography.bodyLarge.copyWith(color: AppColors.grey800)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class _CollapsedFiltersSummary extends StatelessWidget {
  const _CollapsedFiltersSummary({
    required this.date,
    required this.day,
    required this.academicYearName,
    required this.assignment,
    required this.subjectId,
  });

  final DateTime date;
  final String day;
  final String? academicYearName;
  final TeacherClassSubjectModel? assignment;
  final String? subjectId;

  @override
  Widget build(BuildContext context) {
    final subjectText = assignment != null && subjectId != null
        ? assignment!.subjectLabel
        : 'Not selected';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters are optional. Tap above to expand.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: AppDimensions.space8),
        Wrap(
          spacing: AppDimensions.space8,
          runSpacing: AppDimensions.space8,
          children: [
            _SummaryPill(label: 'Day: $day'),
            _SummaryPill(
              label: assignment?.classLabel ?? 'Class: Not selected',
            ),
            _SummaryPill(label: 'Subject: $subjectText'),
            if (academicYearName != null)
              _SummaryPill(label: 'Year: $academicYearName'),
          ],
        ),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.grey600,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ClassDropdown extends ConsumerWidget {
  const _ClassDropdown({
    required this.academicYearId,
    required this.selectedAssignment,
    required this.onChanged,
  });

  final String? academicYearId;
  final TeacherClassSubjectModel? selectedAssignment;
  final ValueChanged<TeacherClassSubjectModel?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (academicYearId == null) {
      return Text(
        'Loading academic year...',
        style: AppTypography.bodySmall.copyWith(color: AppColors.grey400),
      );
    }

    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(academicYearId));

    return assignmentsAsync.when(
      data: (assignments) {
        // Deduplicate by standardId+section
        final uniqueClasses = <String, TeacherClassSubjectModel>{};
        for (final a in assignments) {
          final key = '${a.standardId}_${a.section}';
          uniqueClasses.putIfAbsent(key, () => a);
        }
        final classes = uniqueClasses.values.toList();

        if (classes.isEmpty) {
          return Text('No classes assigned',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.grey400));
        }

        final selectedClassValue = selectedAssignment != null
            ? '${selectedAssignment!.standardId}_${selectedAssignment!.section}'
            : null;
        final hasSelectedClass = selectedClassValue != null &&
            classes.any(
              (c) => '${c.standardId}_${c.section}' == selectedClassValue,
            );
        final safeClassValue = hasSelectedClass ? selectedClassValue : null;
        if (selectedClassValue != null && !hasSelectedClass) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
        }

        return DropdownButtonFormField<String>(
          key: ValueKey<String?>('class-$safeClassValue'),
          initialValue: safeClassValue,
          decoration: _inputDecoration('Select class'),
          items: classes
              .map((c) => DropdownMenuItem(
                    value: '${c.standardId}_${c.section}',
                    child: Text(c.classLabel, style: AppTypography.bodyMedium),
                  ))
              .toList(),
          onChanged: (val) {
            if (val == null) {
              onChanged(null);
              return;
            }
            final found = classes.firstWhere(
                (c) => '${c.standardId}_${c.section}' == val,
                orElse: () => classes.first);
            onChanged(found);
          },
        );
      },
      loading: () => AppLoading.listTile(),
      error: (e, _) => Text('Could not load classes: $e',
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed)),
    );
  }
}

class _SubjectDropdown extends ConsumerWidget {
  const _SubjectDropdown({
    required this.academicYearId,
    required this.selectedAssignment,
    required this.selectedSubjectId,
    required this.onChanged,
  });

  final String? academicYearId;
  final TeacherClassSubjectModel? selectedAssignment;
  final String? selectedSubjectId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedAssignment == null || academicYearId == null) {
      return const SizedBox.shrink();
    }

    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(academicYearId));

    return assignmentsAsync.when(
      data: (assignments) {
        // Filter subjects for selected class
        final subjects = assignments
            .where((a) =>
                a.standardId == selectedAssignment!.standardId &&
                a.section == selectedAssignment!.section)
            .toList();

        if (subjects.isEmpty) {
          return Text('No subjects found',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.grey400));
        }

        final hasSelectedSubject = selectedSubjectId != null &&
            subjects.any((s) => s.subjectId == selectedSubjectId);
        final safeSubjectId = hasSelectedSubject ? selectedSubjectId : null;

        if (selectedSubjectId != null && !hasSelectedSubject) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onChanged(null));
        } else if (safeSubjectId == null && subjects.length == 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(subjects.first.subjectId);
          });
        }

        return DropdownButtonFormField<String>(
          key: ValueKey<String?>(
              'subject-${selectedAssignment!.standardId}-${selectedAssignment!.section}-$safeSubjectId'),
          initialValue: safeSubjectId,
          decoration: _inputDecoration('Select subject'),
          items: subjects
              .map((s) => DropdownMenuItem(
                    value: s.subjectId,
                    child:
                        Text(s.subjectLabel, style: AppTypography.bodyMedium),
                  ))
              .toList(),
          onChanged: onChanged,
        );
      },
      loading: () => AppLoading.listTile(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.surface50,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide:
              const BorderSide(color: AppColors.navyMedium, width: 1.5)),
    );

class _StudentList extends ConsumerWidget {
  const _StudentList({
    required this.formState,
    required this.onStatusChanged,
    required this.onSelectionChanged,
    required this.onStudentsLoaded,
    required this.onExistingLoaded,
    required this.onSubmit,
  });

  final MarkAttendanceFormState formState;
  final void Function(String studentId, AttendanceStatus) onStatusChanged;
  final void Function(String studentId, bool selected) onSelectionChanged;
  final void Function(List<String> ids) onStudentsLoaded;
  final void Function(List<AttendanceModel> records) onExistingLoaded;
  final Future<void> Function(List<String> studentIds) onSubmit;

  bool get _canLoad =>
      formState.selectedAssignment != null &&
      formState.selectedSubjectId != null &&
      formState.selectedAcademicYearId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canLoad) {
      return const AppEmptyState(
        icon: Icons.checklist_outlined,
        title: 'Select class and subject',
        subtitle: 'Choose a class and subject above to load the student list.',
      );
    }

    final assignment = formState.selectedAssignment!;
    final studentsAsync = ref.watch(
      studentsForAttendanceProvider((
        standardId: assignment.standardId,
        section: assignment.section,
        academicYearId: formState.selectedAcademicYearId!,
      )),
    );

    // Also load existing attendance to prefill
    final existingDate =
        '${formState.date.year}-${formState.date.month.toString().padLeft(2, '0')}-${formState.date.day.toString().padLeft(2, '0')}';
    final existingAsync = ref.watch(attendanceListProvider((
      standardId: assignment.standardId,
      section: assignment.section,
      academicYearId: formState.selectedAcademicYearId,
      date: existingDate,
      subjectId: formState.selectedSubjectId,
      studentId: null,
      month: null,
      year: null,
    )));

    return studentsAsync.when(
      data: (students) {
        if (students.isEmpty) {
          return const AppEmptyState(
            icon: Icons.person_off_outlined,
            title: 'No students found',
            subtitle: 'No students enrolled in this class.',
          );
        }

        final studentIds = students.map((s) => s.id).toList();
        final selectedIds = formState.selectedStudentIds
            .where((id) => studentIds.contains(id))
            .toList();
        final allSelected =
            studentIds.isNotEmpty && selectedIds.length == studentIds.length;
        final noneSelected = selectedIds.isEmpty;

        // One-time initialization per loaded class/section/subject/date:
        // 1) ensure every student has a local status,
        // 2) then preload existing backend records once.
        final needsStudentInit =
            studentIds.any((id) => !formState.attendanceMap.containsKey(id));
        if (needsStudentInit) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onStudentsLoaded(studentIds);
          });
        }
        existingAsync.whenData((existing) {
          if (existing.items.isNotEmpty && formState.attendanceMap.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onExistingLoaded(existing.items);
            });
          }
        });

        Widget actionButtons() => Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space8,
                AppDimensions.space16,
                AppDimensions.space8,
              ),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: AppDimensions.space8,
                    spacing: AppDimensions.space8,
                    children: [
                      AppButton.small(
                        label: allSelected ? 'Selected All' : 'Select All',
                        onTap: () => ref
                            .read(markAttendanceProvider.notifier)
                            .selectAll(studentIds),
                        fullWidth: false,
                      ),
                      AppButton.small(
                        label: 'Clear Selection',
                        onTap: noneSelected
                            ? null
                            : () => ref
                                .read(markAttendanceProvider.notifier)
                                .clearSelection(),
                        fullWidth: false,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface100,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          'Selected ${selectedIds.length}/${studentIds.length}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyMedium,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Mark Selected Absent',
                          isDisabled: noneSelected,
                          onTap: noneSelected
                              ? null
                              : () => ref
                                  .read(markAttendanceProvider.notifier)
                                  .markSelected(
                                      AttendanceStatus.absent, selectedIds),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: AppButton.primary(
                          label: 'Mark Selected Present',
                          isDisabled: noneSelected,
                          onTap: noneSelected
                              ? null
                              : () => ref
                                  .read(markAttendanceProvider.notifier)
                                  .markSelected(
                                      AttendanceStatus.present, selectedIds),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

        Widget submitButton() => Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: AppButton.primary(
                label: 'Final Submit (${students.length})',
                isLoading: formState.isSubmitting,
                onTap: () => onSubmit(studentIds),
              ),
            );

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _AttendanceSummaryBar(
                total: students.length,
                statusMap: formState.attendanceMap,
              ),
            ),
            SliverToBoxAdapter(child: actionButtons()),
            SliverList.builder(
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                final status = formState.attendanceMap[student.id] ??
                    AttendanceStatus.absent;
                return StudentAttendanceTile(
                  key: ValueKey(student.id),
                  studentId: student.id,
                  studentName: student.studentName,
                  admissionNumber: student.admissionNumber,
                  rollNumber: student.rollNumber,
                  section: student.section,
                  currentStatus: status,
                  onStatusChanged: (s) => onStatusChanged(student.id, s),
                  isSelected: formState.selectedStudentIds.contains(student.id),
                  onSelectionChanged: (selected) =>
                      onSelectionChanged(student.id, selected),
                  isLast: index == students.length - 1,
                );
              },
            ),
            SliverToBoxAdapter(child: submitButton()),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppDimensions.space16),
            ),
          ],
        );
      },
      loading: () => Center(child: AppLoading.fullPage()),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(
          studentsForAttendanceProvider((
            standardId: assignment.standardId,
            section: assignment.section,
            academicYearId: formState.selectedAcademicYearId!,
          )),
        ),
      ),
    );
  }
}

class _AttendanceSummaryBar extends StatelessWidget {
  const _AttendanceSummaryBar({
    required this.total,
    required this.statusMap,
  });

  final int total;
  final Map<String, AttendanceStatus> statusMap;

  int get _presentCount =>
      statusMap.values.where((s) => s == AttendanceStatus.present).length;
  int get _absentCount =>
      statusMap.values.where((s) => s == AttendanceStatus.absent).length;
  int get _lateCount =>
      statusMap.values.where((s) => s == AttendanceStatus.late).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16, vertical: AppDimensions.space12),
      decoration: const BoxDecoration(
        color: AppColors.surface50,
        border: Border(bottom: BorderSide(color: AppColors.surface100)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppDimensions.space8,
        runSpacing: AppDimensions.space8,
        children: [
          _SummaryChip(
            count: _presentCount,
            label: 'Present',
            color: AppColors.successGreen,
            bg: AppColors.successLight,
          ),
          _SummaryChip(
            count: _absentCount,
            label: 'Absent',
            color: AppColors.errorRed,
            bg: AppColors.errorLight,
          ),
          _SummaryChip(
            count: _lateCount,
            label: 'Late',
            color: AppColors.warningAmber,
            bg: AppColors.warningLight,
          ),
          _SummaryChip(
            count: total,
            label: 'Total',
            color: AppColors.navyMedium,
            bg: AppColors.surface100,
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  final int count;
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12, vertical: AppDimensions.space4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: AppTypography.labelLarge
                .copyWith(color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(label, style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
