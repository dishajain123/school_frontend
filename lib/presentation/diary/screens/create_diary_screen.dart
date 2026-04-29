import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/errors/app_exception.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/diary_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart'; // myTeacherAssignmentsProvider
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class CreateDiaryScreen extends ConsumerStatefulWidget {
  const CreateDiaryScreen({super.key});

  @override
  ConsumerState<CreateDiaryScreen> createState() => _CreateDiaryScreenState();
}

class _CreateDiaryScreenState extends ConsumerState<CreateDiaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _homeworkNoteCtrl = TextEditingController();

  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedSubjectId;
  DateTime _selectedDate = _today();
  bool _isSubmitting = false;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void dispose() {
    _topicCtrl.dispose();
    _homeworkNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
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

    if (_selectedStandardId == null || _selectedStandardId!.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please select class and section');
      return;
    }
    if (_selectedSubjectId == null || _selectedSubjectId!.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please select a subject');
      return;
    }
    if (!_uuidPattern.hasMatch(_selectedStandardId!.trim())) {
      SnackbarUtils.showError(
          context, 'Invalid class selection. Please reselect.');
      return;
    }
    if (!_uuidPattern.hasMatch(_selectedSubjectId!.trim())) {
      SnackbarUtils.showError(
          context, 'Invalid subject selection. Please reselect.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(diaryRepositoryProvider);
      await repo.createDiary(
        standardId: _selectedStandardId!.trim(),
        subjectId: _selectedSubjectId!.trim(),
        topicCovered: _topicCtrl.text.trim(),
        homeworkNote: _homeworkNoteCtrl.text.trim().isEmpty
            ? null
            : _homeworkNoteCtrl.text.trim(),
        date: _toApiDate(_selectedDate),
        // academicYearId omitted — backend uses active year
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Diary entry added successfully!');
        context.pop(true); // Signal list screen to refresh
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, _readableError(e));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _readableError(Object e) {
    if (e is DioException) {
      final err = e.error;
      if (err is AppException) return err.message;
      if (e.message != null && e.message!.trim().isNotEmpty) return e.message!;
    }
    return e.toString();
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final assignmentsAsync =
        ref.watch(myTeacherAssignmentsProvider(activeYear?.id));

    return AppScaffold(
      appBar: const AppAppBar(title: 'Add Diary Entry', showBack: true),
      body: assignmentsAsync.when(
        loading: () => Center(child: AppLoading.fullPage()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Could not load your classes. Please try again.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.errorRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  e.toString(),
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (assignments) {
          if (assignments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.co_present_outlined,
                        size: 56, color: AppColors.grey400),
                    const SizedBox(height: AppDimensions.space16),
                    Text(
                      'No classes assigned',
                      style: AppTypography.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    Text(
                      "You don't have any class assignments for this academic year.",
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return _DiaryForm(
            formKey: _formKey,
            topicCtrl: _topicCtrl,
            homeworkNoteCtrl: _homeworkNoteCtrl,
            assignments: assignments,
            selectedStandardId: _selectedStandardId,
            selectedSection: _selectedSection,
            selectedSubjectId: _selectedSubjectId,
            selectedDate: _selectedDate,
            isSubmitting: _isSubmitting,
            onStandardChanged: (id) {
              setState(() {
                final parts = (id ?? '').split('::');
                _selectedStandardId = parts.isNotEmpty ? parts.first : null;
                _selectedSection = parts.length > 1 ? parts[1] : null;
                _selectedSubjectId = null; // reset subject on class change
              });
            },
            onSubjectChanged: (id) => setState(() => _selectedSubjectId = id),
            onDateTap: _pickDate,
            onSubmit: () => _submit(assignments),
          );
        },
      ),
    );
  }
}

// ── Form widget ───────────────────────────────────────────────────────────────

class _DiaryForm extends StatelessWidget {
  const _DiaryForm({
    required this.formKey,
    required this.topicCtrl,
    required this.homeworkNoteCtrl,
    required this.assignments,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedSubjectId,
    required this.selectedDate,
    required this.isSubmitting,
    required this.onStandardChanged,
    required this.onSubjectChanged,
    required this.onDateTap,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController topicCtrl;
  final TextEditingController homeworkNoteCtrl;
  final List<TeacherClassSubjectModel> assignments;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedSubjectId;
  final DateTime selectedDate;
  final bool isSubmitting;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback onDateTap;
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
          // ── Scrollable form fields ────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Class selector ──────────────────────────────
                  _SectionLabel('Class & Section'),
                  const SizedBox(height: AppDimensions.space8),
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

                  const SizedBox(height: AppDimensions.space20),

                  // ── Subject selector ────────────────────────────
                  _SectionLabel('Subject'),
                  const SizedBox(height: AppDimensions.space8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selectedStandardId == null
                        ? _DisabledField(hint: 'Select a class first')
                        : subjects.isEmpty
                            ? _DisabledField(hint: 'No subjects for this class')
                            : _StyledDropdown<String>(
                                key: ValueKey(selectedStandardId),
                                hint: 'Select subject',
                                value: selectedSubjectId,
                                items: subjects.entries
                                    .map((e) => DropdownMenuItem(
                                          value: e.key,
                                          child: Text(
                                            e.value,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                    color: AppColors.grey800),
                                          ),
                                        ))
                                    .toList(),
                                onChanged: onSubjectChanged,
                              ),
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // ── Date picker ─────────────────────────────────
                  _SectionLabel('Date'),
                  const SizedBox(height: AppDimensions.space8),
                  _DatePickerTile(
                    date: selectedDate,
                    onTap: onDateTap,
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // ── Topic Covered ───────────────────────────────
                  _SectionLabel('Topic Covered'),
                  const SizedBox(height: AppDimensions.space8),
                  AppTextField(
                    controller: topicCtrl,
                    label: '',
                    hint: 'What was taught in class today...',
                    maxLines: 4,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Topic covered cannot be empty';
                      }
                      if (v.trim().length < 3) {
                        return 'Topic description is too short';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // ── Homework Note (optional) ────────────────────
                  Row(
                    children: [
                      _SectionLabel('Homework Note'),
                      const SizedBox(width: AppDimensions.space8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface100,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          'Optional',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  AppTextField(
                    controller: homeworkNoteCtrl,
                    label: '',
                    hint:
                        'Add any homework assigned for students and parents...',
                    maxLines: 3,
                    textInputAction: TextInputAction.newline,
                  ),

                  const SizedBox(height: AppDimensions.space12),

                  // Tip banner
                  _TipBanner(
                    message:
                        'Students and parents in this class will be able to see this diary entry.',
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky submit button ──────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space20,
              AppDimensions.space12,
              AppDimensions.space20,
              AppDimensions.space24,
            ),
            child: AppButton.primary(
              label: 'Save Diary Entry',
              onTap: onSubmit,
              isLoading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelLarge.copyWith(color: AppColors.grey600),
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
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
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(hint,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({required this.date, required this.onTap});
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: AppColors.navyMedium),
            const SizedBox(width: AppDimensions.space12),
            Text(
              DateFormatter.formatDate(date),
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 16, color: AppColors.infoBlue),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.infoBlue),
            ),
          ),
        ],
      ),
    );
  }
}
