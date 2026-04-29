import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/homework_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class CreateHomeworkScreen extends ConsumerStatefulWidget {
  const CreateHomeworkScreen({super.key});

  @override
  ConsumerState<CreateHomeworkScreen> createState() =>
      _CreateHomeworkScreenState();
}

class _CreateHomeworkScreenState extends ConsumerState<CreateHomeworkScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();

  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedSubjectId;
  DateTime _selectedDate = _today();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() =>
          _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit(List<TeacherClassSubjectModel> assignments) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedStandardId == null) {
      SnackbarUtils.showError(context, 'Please select class and section');
      return;
    }
    if (_selectedSubjectId == null) {
      SnackbarUtils.showError(context, 'Please select a subject');
      return;
    }
    if (_descCtrl.text.trim().isEmpty && _pickedFile == null) {
      SnackbarUtils.showError(
        context,
        'Add homework text or attach a worksheet PDF/file',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(homeworkRepositoryProvider);
      MultipartFile? multipartFile;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        );
      } else if (_pickedFile != null && _pickedFile!.path != null) {
        multipartFile = await MultipartFile.fromFile(
          _pickedFile!.path!,
          filename: _pickedFile!.name,
        );
      }
      await repo.createHomework(
        standardId: _selectedStandardId!,
        subjectId: _selectedSubjectId!,
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        date: _toApiDate(_selectedDate),
        file: multipartFile,
      );
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Homework posted successfully!');
        context.pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      final message = extractMessage(
        e is DioException ? (e.error ?? e) : e,
      );
      SnackbarUtils.showError(context, message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _removeFile() {
    setState(() => _pickedFile = null);
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Post Homework', showBack: true),
      body: assignmentsAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load your classes. Please try again.',
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.errorRed),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.surface100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.co_present_outlined,
                          size: 36, color: AppColors.grey400),
                    ),
                    const SizedBox(height: 20),
                    Text('No classes assigned',
                        style: AppTypography.headlineSmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text(
                      "You don't have any class assignments for this academic year.",
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.grey500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: _HomeworkForm(
                formKey: _formKey,
                descCtrl: _descCtrl,
                assignments: assignments,
                selectedStandardId: _selectedStandardId,
                selectedSection: _selectedSection,
                selectedSubjectId: _selectedSubjectId,
                selectedDate: _selectedDate,
                pickedFile: _pickedFile,
                isSubmitting: _isSubmitting,
                onStandardChanged: (id) {
                  setState(() {
                    final parts = (id ?? '').split('::');
                    _selectedStandardId = parts.isNotEmpty ? parts.first : null;
                    _selectedSection = parts.length > 1 ? parts[1] : null;
                    _selectedSubjectId = null;
                  });
                },
                onSubjectChanged: (id) =>
                    setState(() => _selectedSubjectId = id),
                onDateTap: _pickDate,
                onPickFile: _pickFile,
                onRemoveFile: _removeFile,
                onSubmit: () => _submit(assignments),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HomeworkForm extends StatelessWidget {
  const _HomeworkForm({
    required this.formKey,
    required this.descCtrl,
    required this.assignments,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedSubjectId,
    required this.selectedDate,
    required this.pickedFile,
    required this.isSubmitting,
    required this.onStandardChanged,
    required this.onSubjectChanged,
    required this.onDateTap,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController descCtrl;
  final List<TeacherClassSubjectModel> assignments;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedSubjectId;
  final DateTime selectedDate;
  final PlatformFile? pickedFile;
  final bool isSubmitting;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onDateTap;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final VoidCallback onSubmit;

  Map<String, String> get _uniqueClassSections {
    final map = <String, String>{};
    for (final a in assignments) {
      final key = '${a.standardId}::${a.section}';
      map.putIfAbsent(key, () => a.classLabel);
    }
    return map;
  }

  Map<String, String> get _subjectsForStandard {
    if (selectedStandardId == null) return {};
    final map = <String, String>{};
    for (final a in assignments) {
      if (a.standardId == selectedStandardId && a.section == (selectedSection ?? '')) {
        map.putIfAbsent(a.subjectId, () => a.subjectLabel);
      }
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final standards = _uniqueClassSections;
    final subjects = _subjectsForStandard;

    return Form(
      key: formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FormCard(
                    title: 'Class & Subject',
                    icon: Icons.school_outlined,
                    children: [
                      _FieldLabel('Class & Section'),
                      const SizedBox(height: 8),
                      _StyledDropdown<String>(
                        hint: 'Select class',
                        value: selectedStandardId,
                        items: standards.entries
                            .map((e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value,
                                      style: AppTypography.bodyMedium
                                          .copyWith(color: AppColors.grey800)),
                                ))
                            .toList(),
                        onChanged: onStandardChanged,
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel('Subject'),
                      const SizedBox(height: 8),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: selectedStandardId == null
                            ? _DisabledField(
                                hint: 'Select a class first',
                                key: const ValueKey('no-class'))
                            : subjects.isEmpty
                                ? _DisabledField(
                                    hint: 'No subjects for this class',
                                    key: const ValueKey('no-subject'))
                                : _StyledDropdown<String>(
                                    key: ValueKey(selectedStandardId),
                                    hint: 'Select subject',
                                    value: selectedSubjectId,
                                    items: subjects.entries
                                        .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value,
                                                  style: AppTypography
                                                      .bodyMedium
                                                      .copyWith(
                                                          color: AppColors
                                                              .grey800)),
                                            ))
                                        .toList(),
                                    onChanged: onSubjectChanged,
                                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    title: 'Date',
                    icon: Icons.calendar_today_outlined,
                    children: [
                      GestureDetector(
                        onTap: onDateTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.surface200, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 16, color: AppColors.navyMedium),
                              const SizedBox(width: 10),
                              Text(
                                DateFormatter.formatDate(selectedDate),
                                style: AppTypography.bodyMedium
                                    .copyWith(color: AppColors.grey800),
                              ),
                              const Spacer(),
                              const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.grey400, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _FormCard(
                    title: 'Description',
                    icon: Icons.edit_note_rounded,
                    children: [
                      AppTextField(
                        controller: descCtrl,
                        label: '',
                        hint:
                            'Type homework instructions (optional if file attached)...',
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: onPickFile,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: pickedFile != null
                                ? AppColors.navyDeep.withValues(alpha: 0.04)
                                : AppColors.surface50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: pickedFile != null
                                  ? AppColors.navyMedium.withValues(alpha: 0.4)
                                  : AppColors.surface200,
                              width: pickedFile != null ? 1.5 : 1,
                            ),
                          ),
                          child: pickedFile == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.attach_file_rounded,
                                        color: AppColors.navyMedium, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Attach worksheet (PDF/image/doc)',
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.navyMedium,
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.navyDeep
                                            .withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                          Icons.insert_drive_file_outlined,
                                          color: AppColors.navyDeep,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        pickedFile!.name,
                                        style: AppTypography.titleSmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: onRemoveFile,
                                      child: const Icon(
                                        Icons.close_rounded,
                                        size: 18,
                                        color: AppColors.grey400,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InfoBanner(
                    message:
                        'Students and parents in this class will be notified automatically.',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _SubmitBar(isSubmitting: isSubmitting, onSubmit: onSubmit),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard(
      {required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface200, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.hint, super.key});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface100, width: 1.5),
      ),
      child: Text(hint,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 15, color: AppColors.infoBlue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoBlue,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isSubmitting, required this.onSubmit});
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: AppButton.primary(
        label: 'Post Homework',
        onTap: onSubmit,
        isLoading: isSubmitting,
        icon: Icons.send_rounded,
      ),
    );
  }
}
