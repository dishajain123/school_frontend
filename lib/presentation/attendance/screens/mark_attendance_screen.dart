import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../data/models/attendance/lecture_attendance.dart';
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

List<LectureStudentEntry> _lectureEntriesOrEmpty(
  Object? lecture,
) {
  if (lecture is LectureAttendanceResponse) {
    return lecture.entries;
  }
  return const <LectureStudentEntry>[];
}

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _initActiveYear());
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
    if (picked != null)
      ref.read(markAttendanceProvider.notifier).setDate(picked);
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
          _FilterSection(
            formState: formState,
            activeYear: activeYear,
            filtersExpanded: _filtersExpanded,
            onToggle: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            onPickDate: () => _pickDate(context),
            weekdayLabel: _weekdayLabel(formState.date),
          ),
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
              onExistingLoaded: (entries) => ref
                  .read(markAttendanceProvider.notifier)
                  .preloadLectureEntries(entries),
              onSubmit: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.formState,
    required this.activeYear,
    required this.filtersExpanded,
    required this.onToggle,
    required this.onPickDate,
    required this.weekdayLabel,
  });

  final MarkAttendanceFormState formState;
  final dynamic activeYear;
  final bool filtersExpanded;
  final VoidCallback onToggle;
  final VoidCallback onPickDate;
  final String weekdayLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded,
                        size: 16, color: AppColors.navyDeep),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Filter Details',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!filtersExpanded)
                    _CollapsedSummaryPills(
                        formState: formState, activeYear: activeYear),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: filtersExpanded ? 0.5 : 0.0,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _ExpandedFilters(
              formState: formState,
              activeYear: activeYear,
              onPickDate: onPickDate,
              weekdayLabel: weekdayLabel,
            ),
            crossFadeState: filtersExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
          Container(height: 1, color: AppColors.surface100),
        ],
      ),
    );
  }
}

class _CollapsedSummaryPills extends ConsumerWidget {
  const _CollapsedSummaryPills(
      {required this.formState, required this.activeYear});
  final MarkAttendanceFormState formState;
  final dynamic activeYear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classLabel = formState.selectedAssignment?.classLabel ?? 'No class';
    return Row(
      children: [
        _Pill(label: classLabel),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.grey600,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ExpandedFilters extends ConsumerWidget {
  const _ExpandedFilters({
    required this.formState,
    required this.activeYear,
    required this.onPickDate,
    required this.weekdayLabel,
  });

  final MarkAttendanceFormState formState;
  final dynamic activeYear;
  final VoidCallback onPickDate;
  final String weekdayLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Date'),
          const SizedBox(height: 8),
          _DatePickerTile(date: formState.date, onTap: onPickDate),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_view_week_rounded,
                    size: 14, color: AppColors.grey400),
                const SizedBox(width: 8),
                Text(weekdayLabel,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.grey600)),
                if (activeYear != null) ...[
                  const SizedBox(width: 8),
                  Text('·',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey400)),
                  const SizedBox(width: 8),
                  Text(activeYear.name,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey600)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Lecture'),
          const SizedBox(height: 8),
          _LectureDropdown(
            selectedLecture: formState.selectedLectureNumber,
            onChanged: (lecture) => ref
                .read(markAttendanceProvider.notifier)
                .setLectureNumber(lecture),
          ),
          const SizedBox(height: 16),
          _FieldLabel(label: 'Class'),
          const SizedBox(height: 8),
          _ClassDropdown(
            academicYearId: formState.selectedAcademicYearId,
            selectedAssignment: formState.selectedAssignment,
            onChanged: (a) =>
                ref.read(markAttendanceProvider.notifier).setAssignment(a),
          ),
          if (formState.selectedAssignment != null) ...[
            const SizedBox(height: 16),
            _FieldLabel(label: 'Subject'),
            const SizedBox(height: 8),
            _SubjectDropdown(
              academicYearId: formState.selectedAcademicYearId,
              selectedAssignment: formState.selectedAssignment,
              selectedSubjectId: formState.selectedSubjectId,
              onChanged: (id) =>
                  ref.read(markAttendanceProvider.notifier).setSubjectId(id),
            ),
          ],
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface200, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: AppColors.navyMedium),
            const SizedBox(width: 10),
            Text(_format(date),
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.grey800)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _LectureDropdown extends StatelessWidget {
  const _LectureDropdown({
    required this.selectedLecture,
    required this.onChanged,
  });

  final int selectedLecture;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: selectedLecture,
      decoration: _inputDecoration('Select lecture'),
      items: List.generate(
        12,
        (i) => DropdownMenuItem<int>(
          value: i + 1,
          child: Text('Lecture ${i + 1}', style: AppTypography.bodyMedium),
        ),
      ),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
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
      return Text('Loading academic year...',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey400));
    }

    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(academicYearId));

    return assignmentsAsync.when(
      data: (assignments) {
        final uniqueClasses = <String, TeacherClassSubjectModel>{};
        for (final a in assignments) {
          uniqueClasses.putIfAbsent('${a.standardId}_${a.section}', () => a);
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
                (c) => '${c.standardId}_${c.section}' == selectedClassValue);
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
    if (selectedAssignment == null || academicYearId == null)
      return const SizedBox.shrink();

    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(academicYearId));

    return assignmentsAsync.when(
      data: (assignments) {
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
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onChanged(subjects.first.subjectId));
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.surface200, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.surface200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
  final void Function(String, AttendanceStatus) onStatusChanged;
  final void Function(String, bool) onSelectionChanged;
  final void Function(List<String>) onStudentsLoaded;
  final void Function(List<LectureStudentEntry>) onExistingLoaded;
  final Future<void> Function(List<String>) onSubmit;

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
    final studentsAsync = ref.watch(studentsForAttendanceProvider((
      standardId: assignment.standardId,
      section: assignment.section,
      academicYearId: formState.selectedAcademicYearId!,
    )));

    final existingDate =
        '${formState.date.year}-${formState.date.month.toString().padLeft(2, '0')}-${formState.date.day.toString().padLeft(2, '0')}';
    final lectureAsync = ref.watch(lectureAttendanceProvider((
      standardId: assignment.standardId,
      section: assignment.section,
      subjectId: formState.selectedSubjectId!,
      academicYearId: formState.selectedAcademicYearId!,
      date: existingDate,
      lectureNumber: formState.selectedLectureNumber,
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

        final needsStudentInit =
            studentIds.any((id) => !formState.attendanceMap.containsKey(id));
        if (needsStudentInit) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => onStudentsLoaded(studentIds));
        }
        lectureAsync.whenData((lecture) {
          final lectureEntries = _lectureEntriesOrEmpty(lecture);
          final hasMismatch = lectureEntries.any(
            (entry) => formState.attendanceMap[entry.studentId] != entry.status,
          );
          if (hasMismatch) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => onExistingLoaded(lectureEntries));
          }
        });

        final presentCount = formState.attendanceMap.values
            .where((s) => s == AttendanceStatus.present)
            .length;
        final absentCount = formState.attendanceMap.values
            .where((s) => s == AttendanceStatus.absent)
            .length;
        final lateCount = formState.attendanceMap.values
            .where((s) => s == AttendanceStatus.late)
            .length;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _AttendanceSummaryBar(
                total: students.length,
                present: presentCount,
                absent: absentCount,
                late: lateCount,
              ),
            ),
            SliverToBoxAdapter(
              child: _BulkActionBar(
                allSelected: allSelected,
                noneSelected: noneSelected,
                selectedCount: selectedIds.length,
                totalCount: studentIds.length,
                studentIds: studentIds,
                selectedIds: selectedIds,
              ),
            ),
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
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(16),
                child: AppButton.primary(
                  label: 'Submit Attendance (${students.length})',
                  isLoading: formState.isSubmitting,
                  onTap: () => onSubmit(studentIds),
                  icon: Icons.check_rounded,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        );
      },
      loading: () => Center(child: AppLoading.fullPage()),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentsForAttendanceProvider((
          standardId: assignment.standardId,
          section: assignment.section,
          academicYearId: formState.selectedAcademicYearId!,
        ))),
      ),
    );
  }
}

class _AttendanceSummaryBar extends StatelessWidget {
  const _AttendanceSummaryBar({
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
  });

  final int total, present, absent, late;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppColors.surface50,
      child: Row(
        children: [
          _SummaryChip(
              count: present,
              label: 'Present',
              color: AppColors.successGreen,
              bg: AppColors.successLight),
          const SizedBox(width: 8),
          _SummaryChip(
              count: absent,
              label: 'Absent',
              color: AppColors.errorRed,
              bg: AppColors.errorLight),
          const SizedBox(width: 8),
          _SummaryChip(
              count: late,
              label: 'Late',
              color: AppColors.warningAmber,
              bg: AppColors.warningLight),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$total Total',
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

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.count,
    required this.label,
    required this.color,
    required this.bg,
  });

  final int count;
  final String label;
  final Color color, bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: AppTypography.labelMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(width: 4),
          Text(label,
              style:
                  AppTypography.caption.copyWith(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}

class _BulkActionBar extends ConsumerWidget {
  const _BulkActionBar({
    required this.allSelected,
    required this.noneSelected,
    required this.selectedCount,
    required this.totalCount,
    required this.studentIds,
    required this.selectedIds,
  });

  final bool allSelected, noneSelected;
  final int selectedCount, totalCount;
  final List<String> studentIds, selectedIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => ref
                    .read(markAttendanceProvider.notifier)
                    .selectAll(studentIds),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        allSelected ? AppColors.navyDeep : AppColors.surface100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    allSelected ? 'All Selected' : 'Select All',
                    style: AppTypography.labelSmall.copyWith(
                      color: allSelected ? AppColors.white : AppColors.grey700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: noneSelected
                    ? null
                    : () => ref
                        .read(markAttendanceProvider.notifier)
                        .clearSelection(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: noneSelected
                        ? AppColors.surface50
                        : AppColors.surface100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Clear',
                    style: AppTypography.labelSmall.copyWith(
                      color:
                          noneSelected ? AppColors.grey400 : AppColors.grey700,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$selectedCount / $totalCount selected',
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (!noneSelected) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    label: 'Mark Absent',
                    isDisabled: noneSelected,
                    height: 40,
                    onTap: noneSelected
                        ? null
                        : () => ref
                            .read(markAttendanceProvider.notifier)
                            .markSelected(AttendanceStatus.absent, selectedIds),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.primary(
                    label: 'Mark Present',
                    isDisabled: noneSelected,
                    height: 40,
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
        ],
      ),
    );
  }
}
