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
import '../../../providers/student_provider.dart';
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
      ref
          .read(markAttendanceProvider.notifier)
          .setAcademicYear(activeYear.id);
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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(markAttendanceProvider);
    final activeYear = ref.watch(activeYearProvider);

    return AppScaffold(
      appBar: const AppAppBar(title: 'Mark Attendance', showBack: true),
      body: Column(
        children: [
          // ── Form Header ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date picker row
                _SectionLabel(label: 'Date'),
                const SizedBox(height: AppDimensions.space8),
                _DatePickerTile(
                  date: formState.date,
                  onTap: () => _pickDate(context),
                ),
                const SizedBox(height: AppDimensions.space16),

                // Academic year (read-only from active year)
                if (activeYear == null)
                  AppLoading.listTile()
                else
                  _InfoRow(label: 'Academic Year', value: activeYear.name),
                const SizedBox(height: AppDimensions.space16),

                // Class selector
                _SectionLabel(label: 'Class'),
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
                  _SectionLabel(label: 'Subject'),
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
          const Divider(height: 1, color: AppColors.surface100),

          // ── Student List ─────────────────────────────────────────────
          Expanded(
            child: _StudentList(
              formState: formState,
              onStatusChanged: (studentId, status) => ref
                  .read(markAttendanceProvider.notifier)
                  .setStudentStatus(studentId, status),
              onStudentsLoaded: (ids) => ref
                  .read(markAttendanceProvider.notifier)
                  .initStudents(ids),
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
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
                style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.grey800)),
            const Spacer(),
            const Icon(Icons.arrow_drop_down,
                color: AppColors.grey400),
          ],
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
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey400));
        }

        return DropdownButtonFormField<String>(
          value: selectedAssignment != null
              ? '${selectedAssignment!.standardId}_${selectedAssignment!.section}'
              : null,
          decoration: _inputDecoration('Select class'),
          items: classes
              .map((c) => DropdownMenuItem(
                    value: '${c.standardId}_${c.section}',
                    child: Text(c.classLabel,
                        style: AppTypography.bodyMedium),
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
    if (selectedAssignment == null) return const SizedBox.shrink();

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
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey400));
        }

        return DropdownButtonFormField<String>(
          value: selectedSubjectId,
          decoration: _inputDecoration('Select subject'),
          items: subjects
              .map((s) => DropdownMenuItem(
                    value: s.subjectId,
                    child: Text(s.subjectLabel,
                        style: AppTypography.bodyMedium),
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
      hintStyle:
          AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
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
    required this.onStudentsLoaded,
    required this.onExistingLoaded,
    required this.onSubmit,
  });

  final MarkAttendanceFormState formState;
  final void Function(String studentId, AttendanceStatus) onStatusChanged;
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

        // Preload existing if available
        existingAsync.whenData((existing) {
          if (existing.items.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onExistingLoaded(existing.items);
            });
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onStudentsLoaded(studentIds);
            });
          }
        });

        return Column(
          children: [
            // Summary bar
            _AttendanceSummaryBar(
              total: students.length,
              statusMap: formState.attendanceMap,
            ),
            // Student list
            Expanded(
              child: ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final status = formState.attendanceMap[student.id] ??
                      AttendanceStatus.absent;
                  return StudentAttendanceTile(
                    key: ValueKey(student.id),
                    studentId: student.id,
                    admissionNumber: student.admissionNumber,
                    section: student.section,
                    currentStatus: status,
                    onStatusChanged: (s) =>
                        onStatusChanged(student.id, s),
                    isLast: index == students.length - 1,
                  );
                },
              ),
            ),
            // Submit button
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: AppButton.primary(
                label: 'Submit Attendance (${students.length})',
                isLoading: formState.isSubmitting,
                onTap: () => onSubmit(studentIds),
              ),
            ),
          ],
        );
      },
      loading: () => Expanded(child: Center(child: AppLoading.fullPage())),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(studentsForAttendanceProvider),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryChip(
              count: _presentCount,
              label: 'Present',
              color: AppColors.successGreen,
              bg: AppColors.successLight),
          _SummaryChip(
              count: _absentCount,
              label: 'Absent',
              color: AppColors.errorRed,
              bg: AppColors.errorLight),
          _SummaryChip(
              count: _lateCount,
              label: 'Late',
              color: AppColors.warningAmber,
              bg: AppColors.warningLight),
          _SummaryChip(
              count: total,
              label: 'Total',
              color: AppColors.navyMedium,
              bg: AppColors.surface100),
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
            style: AppTypography.labelLarge.copyWith(
                color: color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.labelSmall.copyWith(color: color)),
        ],
      ),
    );
  }
}
