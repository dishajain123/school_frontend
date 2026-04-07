import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateAssignmentScreen extends ConsumerStatefulWidget {
  /// If non-null, this is an edit operation
  final String? editAssignmentId;

  const CreateAssignmentScreen({super.key, this.editAssignmentId});

  @override
  ConsumerState<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState
    extends ConsumerState<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _selectedStandardId;
  String? _selectedSubjectId;
  String? _selectedAcademicYearId;
  DateTime? _dueDate;
  PlatformFile? _file;
  bool _isLoading = false;

  bool get _isEdit => widget.editAssignmentId != null;

  @override
  void initState() {
    super.initState();
    final activeYear = ref.read(activeYearProvider);
    _selectedAcademicYearId = activeYear?.id;
  }

  T? _firstOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyDeep,
              onPrimary: AppColors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dueDate == null) {
      SnackbarUtils.showError(context, 'Please select a due date');
      return;
    }
    if (_selectedStandardId == null) {
      SnackbarUtils.showError(context, 'Please select a class');
      return;
    }
    if (_selectedSubjectId == null) {
      SnackbarUtils.showError(context, 'Please select a subject');
      return;
    }
    if (_selectedAcademicYearId == null) {
      SnackbarUtils.showError(context, 'Please select an academic year');
      return;
    }

    setState(() => _isLoading = true);

    try {
      MultipartFile? multipartFile;
      if (_file != null && _file!.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          _file!.bytes!,
          filename: _file!.name,
        );
      } else if (_file != null && _file!.path != null) {
        multipartFile =
            await MultipartFile.fromFile(_file!.path!, filename: _file!.name);
      }

      if (_isEdit) {
        await ref.read(assignmentsProvider.notifier).updateAssignment(
              widget.editAssignmentId!,
              title: _titleCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              dueDate: _dueDate,
            );
        await ref.read(assignmentsProvider.notifier).refresh();
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Assignment updated');
          context.pop();
        }
      } else {
        await ref.read(assignmentsProvider.notifier).createAssignment(
              title: _titleCtrl.text.trim(),
              standardId: _selectedStandardId!,
              subjectId: _selectedSubjectId!,
              dueDate: _dueDate!,
              academicYearId: _selectedAcademicYearId!,
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              file: multipartFile,
            );
        await ref.read(assignmentsProvider.notifier).refresh();
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Assignment created');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.role == UserRole.teacher;
    final activeYear = ref.watch(activeYearProvider);
    final selectedYearId = _selectedAcademicYearId ?? activeYear?.id;
    final teacherAssignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(selectedYearId));
    final standards = selectedYearId != null
        ? ref.watch(standardsProvider(selectedYearId)).valueOrNull ?? []
        : <dynamic>[];
    final subjects = _selectedStandardId != null
        ? ref.watch(subjectsProvider(_selectedStandardId!)).valueOrNull ?? []
        : <dynamic>[];
    final years = ref.watch(academicYearNotifierProvider).valueOrNull ?? [];

    final teacherAssignments = teacherAssignmentsAsync.valueOrNull ??
        const <TeacherClassSubjectModel>[];
    final teacherStandardMap = <String, String>{};
    final teacherSubjectMap = <String, String>{};
    for (final a in teacherAssignments) {
      teacherStandardMap.putIfAbsent(
          a.standardId, () => a.standardName ?? a.classLabel);
      if (_selectedStandardId != null && a.standardId == _selectedStandardId) {
        teacherSubjectMap.putIfAbsent(
            a.subjectId, () => a.subjectName ?? a.subjectLabel);
      }
    }
    final teacherStandardIds = teacherStandardMap.keys.toList();
    final teacherSubjectIds = teacherSubjectMap.keys.toList();
    final selectedTeacherStandardId =
        teacherStandardMap.containsKey(_selectedStandardId)
            ? _selectedStandardId
            : null;
    final selectedTeacherSubjectId =
        teacherSubjectMap.containsKey(_selectedSubjectId)
            ? _selectedSubjectId
            : null;

    return AppScaffold(
      appBar: AppAppBar(
        title: _isEdit ? 'Edit Assignment' : 'Create Assignment',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title ────────────────────────────────────────────────
              AppTextField(
                controller: _titleCtrl,
                label: 'Title',
                hint: 'Enter assignment title',
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppDimensions.space16),

              // ── Description ──────────────────────────────────────────
              AppTextField(
                controller: _descCtrl,
                label: 'Description (optional)',
                hint: 'Add instructions or details...',
                maxLines: 4,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: AppDimensions.space16),

              // ── Academic Year ────────────────────────────────────────
              if (!_isEdit) ...[
                _DropdownField<dynamic>(
                  label: 'Academic Year',
                  hint: 'Select year',
                  value: _firstOrNull<dynamic>(
                    years,
                    (y) => y.id == _selectedAcademicYearId,
                  ),
                  items: years,
                  itemLabel: (y) => y.name as String,
                  onChanged: (y) {
                    setState(() {
                      _selectedAcademicYearId = y?.id as String?;
                      _selectedStandardId = null;
                      _selectedSubjectId = null;
                    });
                  },
                ),
                const SizedBox(height: AppDimensions.space16),

                // ── Standard ──────────────────────────────────────────
                if (isTeacher)
                  _DropdownField<String>(
                    label: 'Class (Standard)',
                    hint: 'Select class',
                    value: selectedTeacherStandardId,
                    items: teacherStandardIds,
                    itemLabel: (id) => teacherStandardMap[id] ?? id,
                    onChanged: (s) {
                      setState(() {
                        _selectedStandardId = s;
                        _selectedSubjectId = null;
                      });
                    },
                  )
                else
                  _DropdownField<dynamic>(
                    label: 'Class (Standard)',
                    hint: 'Select class',
                    value: _firstOrNull<dynamic>(
                      standards,
                      (s) => s.id == _selectedStandardId,
                    ),
                    items: standards,
                    itemLabel: (s) => s.name as String,
                    onChanged: (s) {
                      setState(() {
                        _selectedStandardId = s?.id as String?;
                        _selectedSubjectId = null;
                      });
                    },
                  ),
                const SizedBox(height: AppDimensions.space16),

                // ── Subject ───────────────────────────────────────────
                if (isTeacher)
                  _DropdownField<String>(
                    label: 'Subject',
                    hint: _selectedStandardId == null
                        ? 'Select class first'
                        : 'Select subject',
                    value: selectedTeacherSubjectId,
                    items: teacherSubjectIds,
                    itemLabel: (id) => teacherSubjectMap[id] ?? id,
                    onChanged: _selectedStandardId == null
                        ? null
                        : (s) {
                            setState(() => _selectedSubjectId = s);
                          },
                  )
                else
                  _DropdownField<dynamic>(
                    label: 'Subject',
                    hint: _selectedStandardId == null
                        ? 'Select class first'
                        : 'Select subject',
                    value: _firstOrNull<dynamic>(
                      subjects,
                      (s) => s.id == _selectedSubjectId,
                    ),
                    items: subjects,
                    itemLabel: (s) => s.name as String,
                    onChanged: _selectedStandardId == null
                        ? null
                        : (s) {
                            setState(
                                () => _selectedSubjectId = s?.id as String?);
                          },
                  ),
                if (isTeacher) ...[
                  const SizedBox(height: AppDimensions.space8),
                  teacherAssignmentsAsync.when(
                    loading: () => Text(
                      'Loading your allocated classes...',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey600),
                    ),
                    error: (e, _) => Text(
                      'Could not load your class-subject allocation.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.errorRed),
                    ),
                    data: (items) => items.isEmpty
                        ? Text(
                            'No class-subject allocation found for selected year.',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.warningAmber),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
                const SizedBox(height: AppDimensions.space16),
              ],

              // ── Due Date ─────────────────────────────────────────────
              _LabelText('Due Date'),
              const SizedBox(height: AppDimensions.space8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.surface50,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: AppColors.grey400),
                      const SizedBox(width: AppDimensions.space12),
                      Text(
                        _dueDate == null
                            ? 'Select due date'
                            : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: _dueDate == null
                              ? AppColors.grey400
                              : AppColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space16),

              // ── File attachment ───────────────────────────────────────
              _LabelText('Attachment (optional)'),
              const SizedBox(height: AppDimensions.space8),
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.space12),
                  decoration: BoxDecoration(
                    color: AppColors.surface50,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  child: _file == null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload_outlined,
                                color: AppColors.navyLight),
                            const SizedBox(width: AppDimensions.space8),
                            Text('Tap to upload file',
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.navyLight)),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined,
                                color: AppColors.navyDeep, size: 20),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(
                              child: Text(_file!.name,
                                  style: AppTypography.titleSmall,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 18, color: AppColors.grey400),
                              onPressed: () => setState(() => _file = null),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: AppDimensions.space32),

              // ── Submit ────────────────────────────────────────────────
              AppButton.primary(
                label: _isEdit ? 'Save Changes' : 'Create Assignment',
                onTap: _submit,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.labelLarge.copyWith(color: AppColors.grey600));
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;

  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelLarge.copyWith(color: AppColors.grey600)),
        const SizedBox(height: AppDimensions.space8),
        Container(
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
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppColors.grey400),
              onChanged: onChanged,
              items: items
                  .map((item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(itemLabel(item)),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
