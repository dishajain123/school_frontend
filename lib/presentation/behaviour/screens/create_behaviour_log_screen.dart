import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/behaviour/behaviour_log_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/behaviour_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class CreateBehaviourLogScreen extends ConsumerStatefulWidget {
  const CreateBehaviourLogScreen({super.key, this.initialStudentId});

  final String? initialStudentId;

  @override
  ConsumerState<CreateBehaviourLogScreen> createState() =>
      _CreateBehaviourLogScreenState();
}

class _CreateBehaviourLogScreenState
    extends ConsumerState<CreateBehaviourLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String? _selectedStudentId;
  String? _selectedClassKey;
  IncidentType _incidentType = IncidentType.neutral;
  IncidentSeverity _severity = IncidentSeverity.medium;
  DateTime _incidentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.initialStudentId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickIncidentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedStudentId == null || _selectedStudentId!.isEmpty) {
      SnackbarUtils.showError(context, 'Please select a student');
      return;
    }

    final payload = <String, dynamic>{
      'student_id': _selectedStudentId,
      'incident_type': _incidentType.backendValue,
      'severity': _severity.backendValue,
      'description': _descriptionController.text.trim(),
      'incident_date': DateFormatter.formatDateForApi(_incidentDate),
    };

    final created =
        await ref.read(behaviourActionProvider.notifier).create(payload);

    if (!mounted) return;
    if (created != null) {
      SnackbarUtils.showSuccess(context, 'Behaviour log created successfully');
      context.pop(true);
    } else {
      final err = ref.read(behaviourActionProvider).error ??
          'Failed to create behaviour log';
      SnackbarUtils.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final actionState = ref.watch(behaviourActionProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    final canCreate = user?.hasPermission('behaviour_log:create') ?? false;
    final isTeacher = user?.role == UserRole.teacher;
    if (!canCreate || !isTeacher) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Log Behaviour', showBack: true),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only teachers can create behaviour logs.',
        ),
      );
    }

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Log Behaviour',
        showBack: true,
      ),
      body: assignmentsAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Text(
              'Could not load your classes. Please try again.\n$e',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.errorRed,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return const AppEmptyState(
              icon: Icons.co_present_outlined,
              title: 'No class assignments',
              subtitle:
                  'You do not have assigned classes for the active academic year.',
            );
          }

          final classes = _uniqueClasses(assignments);
          final selectedClass = _selectedClass(classes);

          final studentsAsync = selectedClass == null
              ? null
              : ref.watch(
                  studentsForAttendanceProvider(
                    (
                      standardId: selectedClass.standardId,
                      section: selectedClass.section,
                      academicYearId: selectedClass.academicYearId,
                    ),
                  ),
                );

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              children: [
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Class',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                _DropdownField<String>(
                  hint: 'Select class',
                  value: _selectedClassKey,
                  items: classes
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2.classLabel),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedClassKey = value;
                      _selectedStudentId = null;
                    });
                  },
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Student',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                if (studentsAsync == null)
                  const _DisabledBox(hint: 'Select class first')
                else
                  studentsAsync.when(
                    loading: () => AppLoading.listTile(),
                    error: (e, _) => _DisabledBox(
                      hint: 'Could not load students: $e',
                    ),
                    data: (students) => _DropdownField<String>(
                      hint: students.isEmpty
                          ? 'No students found'
                          : 'Select student',
                      value: students.any((s) => s.id == _selectedStudentId)
                          ? _selectedStudentId
                          : null,
                      items: students
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(_studentLabel(s)),
                            ),
                          )
                          .toList(),
                      onChanged: students.isEmpty
                          ? null
                          : (value) {
                              setState(() => _selectedStudentId = value);
                            },
                    ),
                  ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Incident Type',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                _DropdownField<IncidentType>(
                  hint: 'Select type',
                  value: _incidentType,
                  items: IncidentType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(type.icon,
                                  size: AppDimensions.iconSM,
                                  color: type.color),
                              const SizedBox(width: AppDimensions.space8),
                              Text(type.label),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _incidentType = value);
                  },
                ),
                const SizedBox(height: AppDimensions.space16),
                Text(
                  'Severity',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                _DropdownField<IncidentSeverity>(
                  hint: 'Select severity',
                  value: _severity,
                  items: IncidentSeverity.values
                      .map(
                        (severity) => DropdownMenuItem(
                          value: severity,
                          child: Text(severity.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _severity = value);
                  },
                ),
                const SizedBox(height: AppDimensions.space16),
                GestureDetector(
                  onTap: _pickIncidentDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: AppDimensions.space12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface50,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                      border: Border.all(color: AppColors.surface200),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.navyMedium,
                          size: AppDimensions.iconSM,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        Text(
                          DateFormatter.formatDate(_incidentDate),
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey800,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppColors.grey400,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Feedback (Optional)',
                  hint: 'Add remarks/context (optional)',
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppDimensions.space32),
                AppButton.primary(
                  label: 'Create Behaviour Log',
                  onTap: actionState.isSubmitting ? null : _submit,
                  isLoading: actionState.isSubmitting,
                  icon: Icons.check_circle_outline_rounded,
                ),
                const SizedBox(height: AppDimensions.space40),
              ],
            ),
          );
        },
      ),
    );
  }

  List<(String, TeacherClassSubjectModel)> _uniqueClasses(
      List<TeacherClassSubjectModel> assignments) {
    final map = <String, TeacherClassSubjectModel>{};
    for (final a in assignments) {
      final key = '${a.standardId}_${a.section}';
      map.putIfAbsent(key, () => a);
    }
    return map.entries.map((entry) => (entry.key, entry.value)).toList();
  }

  TeacherClassSubjectModel? _selectedClass(
    List<(String, TeacherClassSubjectModel)> classes,
  ) {
    if (_selectedClassKey == null) return null;
    for (final entry in classes) {
      if (entry.$1 == _selectedClassKey) {
        return entry.$2;
      }
    }
    return null;
  }

  String _studentLabel(StudentModel student) {
    final name = student.studentName?.trim();
    final roll = student.rollNumber;
    if (name != null && name.isNotEmpty) {
      if (roll != null && roll.trim().isNotEmpty) {
        return '$name · Roll $roll';
      }
      return name;
    }
    if (roll != null && roll.trim().isNotEmpty) {
      return '${student.admissionNumber} · Roll $roll';
    }
    return student.admissionNumber;
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.items,
    this.value,
    this.onChanged,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}

class _DisabledBox extends StatelessWidget {
  const _DisabledBox({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Text(
        hint,
        style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
      ),
    );
  }
}
