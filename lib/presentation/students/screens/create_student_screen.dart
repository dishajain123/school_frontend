import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/parent_repository.dart';
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

class _CreateStudentScreenState extends ConsumerState<CreateStudentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _admissionNumberController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _sectionController = TextEditingController();
  final _parentIdController = TextEditingController();
  final _parentEmailController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentPasswordController = TextEditingController();
  final _parentOccupationController = TextEditingController();

  StandardModel? _selectedStandard;
  RelationType _selectedRelation = RelationType.guardian;
  bool _createParentInline = false;
  DateTime? _dateOfBirth;
  DateTime? _admissionDate;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

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
    _parentEmailController.dispose();
    _parentPhoneController.dispose();
    _parentPasswordController.dispose();
    _parentOccupationController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isDob) async {
    final initial = isDob
        ? (_dateOfBirth ?? DateTime(2010))
        : (_admissionDate ?? DateTime.now());
    final first = isDob ? DateTime(1990) : DateTime(2000);
    final last = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
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
        if (_sectionController.text.trim().isNotEmpty)
          payload['section'] = _sectionController.text.trim();
        if (_rollNumberController.text.trim().isNotEmpty)
          payload['roll_number'] = _rollNumberController.text.trim();
        if (_selectedStandard != null)
          payload['standard_id'] = _selectedStandard!.id;
        if (_dateOfBirth != null)
          payload['date_of_birth'] =
              DateFormatter.formatDateForApi(_dateOfBirth!);
        if (_admissionDate != null)
          payload['admission_date'] =
              DateFormatter.formatDateForApi(_admissionDate!);
        await ref
            .read(studentNotifierProvider.notifier)
            .updateStudent(widget.existing!.id, payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Student updated successfully.');
          context.pop(true);
        }
      } else {
        String parentId = _parentIdController.text.trim();
        if (_createParentInline) {
          final parentPayload = <String, dynamic>{
            'user': {
              'email': _parentEmailController.text.trim().toLowerCase(),
              'phone': _parentPhoneController.text.trim(),
              'password': _parentPasswordController.text,
            },
            'relation': _selectedRelation.backendValue,
            if (_parentOccupationController.text.trim().isNotEmpty)
              'occupation': _parentOccupationController.text.trim(),
          };
          final createdParent =
              await ref.read(parentRepositoryProvider).create(parentPayload);
          parentId = createdParent.id;
        }
        final payload = <String, dynamic>{
          'admission_number': _admissionNumberController.text.trim(),
          'parent_id': parentId,
        };
        if (_sectionController.text.trim().isNotEmpty)
          payload['section'] = _sectionController.text.trim();
        if (_rollNumberController.text.trim().isNotEmpty)
          payload['roll_number'] = _rollNumberController.text.trim();
        if (_selectedStandard != null)
          payload['standard_id'] = _selectedStandard!.id;
        if (_dateOfBirth != null)
          payload['date_of_birth'] =
              DateFormatter.formatDateForApi(_dateOfBirth!);
        if (_admissionDate != null)
          payload['admission_date'] =
              DateFormatter.formatDateForApi(_admissionDate!);
        await ref.read(studentNotifierProvider.notifier).create(payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Student created successfully.');
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? [];

    if (isEditing &&
        _selectedStandard == null &&
        widget.existing!.standardId != null) {
      try {
        _selectedStandard =
            standards.firstWhere((s) => s.id == widget.existing!.standardId);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Student' : 'Add Student',
        showBack: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!isEditing) ...[
                        _FormCard(
                          title: 'Identity',
                          icon: Icons.badge_outlined,
                          children: [
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
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.surface50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.surface200,
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.link_rounded,
                                        size: 18,
                                        color: AppColors.navyDeep,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Parent Linking',
                                        style:
                                            AppTypography.titleSmall.copyWith(
                                          color: AppColors.navyDeep,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SwitchListTile.adaptive(
                                    value: _createParentInline,
                                    onChanged: (v) =>
                                        setState(() => _createParentInline = v),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      _createParentInline
                                          ? 'Create parent now and auto-link'
                                          : 'Use existing parent ID',
                                      style: AppTypography.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (!_createParentInline)
                                    AppTextField(
                                      controller: _parentIdController,
                                      label: 'Parent ID',
                                      hint: 'Parent UUID',
                                      prefixIconData:
                                          Icons.family_restroom_outlined,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) {
                                        if (!_createParentInline &&
                                            (v == null || v.trim().isEmpty)) {
                                          return 'Parent ID is required';
                                        }
                                        return null;
                                      },
                                    )
                                  else
                                    Column(
                                      children: [
                                        AppTextField(
                                          controller: _parentEmailController,
                                          label: 'Parent Email',
                                          hint: 'parent@example.com',
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          prefixIconData: Icons.email_outlined,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => _createParentInline
                                              ? Validators.validateEmail(v)
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        AppTextField(
                                          controller: _parentPhoneController,
                                          label: 'Parent Phone',
                                          hint: '+91 9876543210',
                                          keyboardType: TextInputType.phone,
                                          prefixIconData: Icons.phone_outlined,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => _createParentInline
                                              ? Validators.validatePhone(v)
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        AppTextField(
                                          controller: _parentPasswordController,
                                          label: 'Parent Initial Password',
                                          hint: 'Minimum 8 characters',
                                          obscureText: true,
                                          prefixIconData:
                                              Icons.lock_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                          validator: (v) => _createParentInline
                                              ? Validators.validatePassword(v)
                                              : null,
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface50,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppColors.surface200,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<RelationType>(
                                              value: _selectedRelation,
                                              isExpanded: true,
                                              icon: const Icon(
                                                Icons
                                                    .keyboard_arrow_down_rounded,
                                                color: AppColors.grey400,
                                              ),
                                              items: RelationType.values
                                                  .map(
                                                    (r) => DropdownMenuItem(
                                                      value: r,
                                                      child: Text(
                                                        r.label,
                                                        style: AppTypography
                                                            .bodyMedium,
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                              onChanged: (v) {
                                                if (v != null) {
                                                  setState(() =>
                                                      _selectedRelation = v);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        AppTextField(
                                          controller:
                                              _parentOccupationController,
                                          label: 'Parent Occupation (optional)',
                                          hint: 'e.g. Engineer',
                                          prefixIconData:
                                              Icons.work_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _FormCard(
                        title: 'Academic Details',
                        icon: Icons.school_outlined,
                        children: [
                          _FieldLabel('Standard'),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surface50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.surface200, width: 1.5),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<StandardModel>(
                                value: _selectedStandard,
                                hint: Text('Select standard',
                                    style: AppTypography.bodyMedium
                                        .copyWith(color: AppColors.grey400)),
                                isExpanded: true,
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.grey400),
                                items: standards
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s.name,
                                              style: AppTypography.bodyMedium),
                                        ))
                                    .toList(),
                                onChanged: (s) =>
                                    setState(() => _selectedStandard = s),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: AppTextField(
                                  controller: _sectionController,
                                  label: 'Section',
                                  hint: 'A, B, C...',
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  textInputAction: TextInputAction.next,
                                ),
                              ),
                              const SizedBox(width: 12),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Personal Details',
                        icon: Icons.person_outline_rounded,
                        children: [
                          _FieldLabel('Date of Birth'),
                          const SizedBox(height: 8),
                          _DatePickerField(
                            value: _dateOfBirth,
                            hint: 'Select date of birth',
                            onTap: () => _pickDate(true),
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Admission Date'),
                          const SizedBox(height: 8),
                          _DatePickerField(
                            value: _admissionDate,
                            hint: 'Select admission date',
                            onTap: () => _pickDate(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _SubmitBar(
                  isEditing: isEditing,
                  isLoading: _isLoading,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value != null
                ? AppColors.navyMedium.withValues(alpha: 0.5)
                : AppColors.surface200,
            width: value != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: value != null ? AppColors.navyMedium : AppColors.grey400,
            ),
            const SizedBox(width: 10),
            Text(
              value != null ? DateFormatter.formatDate(value!) : hint,
              style: AppTypography.bodyMedium.copyWith(
                color: value != null ? AppColors.grey800 : AppColors.grey400,
              ),
            ),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isEditing,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isEditing;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: AppButton.primary(
        label: isEditing ? 'Update Student' : 'Create Student',
        onTap: isLoading ? null : onSubmit,
        isLoading: isLoading,
        icon: isEditing ? Icons.check_rounded : Icons.school_outlined,
      ),
    );
  }
}
