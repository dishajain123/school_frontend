import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateStudentScreen extends ConsumerStatefulWidget {
  const CreateStudentScreen({super.key, this.existing});

  final StudentModel? existing;

  @override
  ConsumerState<CreateStudentScreen> createState() =>
      _CreateStudentScreenState();
}

class _CreateStudentScreenState extends ConsumerState<CreateStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _admissionNumberController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _sectionController = TextEditingController();
  final _parentIdController = TextEditingController();

  StandardModel? _selectedStandard;
  DateTime? _dateOfBirth;
  DateTime? _admissionDate;
  bool _isLoading = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standardsNotifierProvider.notifier).refresh();
    });
    if (isEditing) {
      final s = widget.existing!;
      _admissionNumberController.text = s.admissionNumber;
      _rollNumberController.text = s.rollNumber ?? '';
      _sectionController.text = s.section ?? '';
      _parentIdController.text = s.parentId;
      _dateOfBirth = s.dateOfBirth;
      _admissionDate = s.admissionDate;
    }
  }

  @override
  void dispose() {
    _admissionNumberController.dispose();
    _rollNumberController.dispose();
    _sectionController.dispose();
    _parentIdController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDob) async {
    final initial = isDob ? (_dateOfBirth ?? DateTime(2010)) : (_admissionDate ?? DateTime.now());
    final first = isDob ? DateTime(1990) : DateTime(2000);
    final last = isDob ? DateTime.now() : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dateOfBirth = picked;
        } else {
          _admissionDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final payload = <String, dynamic>{};
        if (_sectionController.text.trim().isNotEmpty) {
          payload['section'] = _sectionController.text.trim();
        }
        if (_rollNumberController.text.trim().isNotEmpty) {
          payload['roll_number'] = _rollNumberController.text.trim();
        }
        if (_selectedStandard != null) {
          payload['standard_id'] = _selectedStandard!.id;
        }
        if (_dateOfBirth != null) {
          payload['date_of_birth'] =
              DateFormatter.formatDateForApi(_dateOfBirth!);
        }
        if (_admissionDate != null) {
          payload['admission_date'] =
              DateFormatter.formatDateForApi(_admissionDate!);
        }
        await ref
            .read(studentNotifierProvider.notifier)
            .updateStudent(widget.existing!.id, payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Student updated successfully.');
          context.pop(true);
        }
      } else {
        final payload = <String, dynamic>{
          'admission_number': _admissionNumberController.text.trim(),
          'parent_id': _parentIdController.text.trim(),
        };
        if (_sectionController.text.trim().isNotEmpty) {
          payload['section'] = _sectionController.text.trim();
        }
        if (_rollNumberController.text.trim().isNotEmpty) {
          payload['roll_number'] = _rollNumberController.text.trim();
        }
        if (_selectedStandard != null) {
          payload['standard_id'] = _selectedStandard!.id;
        }
        if (_dateOfBirth != null) {
          payload['date_of_birth'] =
              DateFormatter.formatDateForApi(_dateOfBirth!);
        }
        if (_admissionDate != null) {
          payload['admission_date'] =
              DateFormatter.formatDateForApi(_admissionDate!);
        }
        await ref.read(studentNotifierProvider.notifier).create(payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Student created successfully.');
          context.pop(true);
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
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? [];

    // Set default selected standard from existing
    if (isEditing && _selectedStandard == null && widget.existing!.standardId != null) {
      try {
        _selectedStandard = standards
            .firstWhere((s) => s.id == widget.existing!.standardId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Student' : 'Add Student',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),

            // Admission Number (non-editable in edit mode)
            if (!isEditing) ...[
              AppTextField(
                controller: _admissionNumberController,
                label: 'Admission Number',
                hint: 'e.g. ADM2024001',
                prefixIconData: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Admission number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.space16),

              AppTextField(
                controller: _parentIdController,
                label: 'Parent ID',
                hint: 'Parent UUID',
                prefixIconData: Icons.family_restroom_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Parent ID is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Standard selector
            Text(
              'Standard',
              style: AppTypography.labelMedium.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16),
              decoration: BoxDecoration(
                color: AppColors.surface50,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                  color: AppColors.surface200,
                  width: AppDimensions.borderMedium,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<StandardModel>(
                  value: _selectedStandard,
                  hint: Text(
                    'Select standard',
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.grey400),
                  ),
                  isExpanded: true,
                  items: standards
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.name,
                                style: AppTypography.bodyMedium),
                          ))
                      .toList(),
                  onChanged: (s) => setState(() => _selectedStandard = s),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _sectionController,
                    label: 'Section',
                    hint: 'A, B, C...',
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: AppTextField(
                    controller: _rollNumberController,
                    label: 'Roll Number',
                    hint: 'e.g. 01',
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space16),

            // Date of Birth
            Text(
              'Date of Birth',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimensions.space8),
            _DatePickerField(
              value: _dateOfBirth,
              hint: 'Select date of birth',
              onTap: () => _pickDate(true),
            ),

            const SizedBox(height: AppDimensions.space16),

            // Admission Date
            Text(
              'Admission Date',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimensions.space8),
            _DatePickerField(
              value: _admissionDate,
              hint: 'Select admission date',
              onTap: () => _pickDate(false),
            ),

            const SizedBox(height: AppDimensions.space32),

            AppButton.primary(
              label: isEditing ? 'Update Student' : 'Create Student',
              onTap: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: isEditing ? Icons.check_rounded : Icons.school_outlined,
            ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.value,
    required this.hint,
    required this.onTap,
  });

  final DateTime? value;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: AppDimensions.iconSM,
              color: AppColors.grey400,
            ),
            const SizedBox(width: AppDimensions.space12),
            Text(
              value != null ? DateFormatter.formatDate(value!) : hint,
              style: AppTypography.bodyMedium.copyWith(
                color: value != null ? AppColors.grey800 : AppColors.grey400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
