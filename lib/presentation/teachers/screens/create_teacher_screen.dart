import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateTeacherScreen extends ConsumerStatefulWidget {
  const CreateTeacherScreen({super.key, this.existing});

  final TeacherModel? existing;

  @override
  ConsumerState<CreateTeacherScreen> createState() =>
      _CreateTeacherScreenState();
}

class _CreateTeacherScreenState extends ConsumerState<CreateTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _specializationController = TextEditingController();

  DateTime? _joinDate;
  bool _isLoading = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.existing!;
      _emailController.text = t.email ?? '';
      _phoneController.text = t.phone ?? '';
      _employeeCodeController.text = t.employeeCode;
      _specializationController.text = t.specialization ?? '';
      _joinDate = t.joinDate;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _employeeCodeController.dispose();
    _specializationController.dispose();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _joinDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final payload = <String, dynamic>{
          'employee_code': _employeeCodeController.text.trim(),
        };
        if (_specializationController.text.trim().isNotEmpty) {
          payload['specialization'] = _specializationController.text.trim();
        }
        if (_joinDate != null) {
          payload['join_date'] = DateFormatter.formatDateForApi(_joinDate!);
        }
        await ref
            .read(teacherNotifierProvider.notifier)
            .updateTeacher(widget.existing!.id, payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Teacher updated successfully.');
          context.pop(true);
        }
      } else {
        final payload = <String, dynamic>{
          'user': {
            'email': _emailController.text.trim().toLowerCase(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
          },
          'employee_code': _employeeCodeController.text.trim(),
        };
        if (_specializationController.text.trim().isNotEmpty) {
          payload['specialization'] = _specializationController.text.trim();
        }
        if (_joinDate != null) {
          payload['join_date'] = DateFormatter.formatDateForApi(_joinDate!);
        }
        await ref.read(teacherNotifierProvider.notifier).create(payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Teacher created successfully.');
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
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Teacher' : 'Add Teacher',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),

            // Section: Account Info
            if (!isEditing) ...[
              _SectionLabel(label: 'Account Information'),
              const SizedBox(height: AppDimensions.space12),
              AppTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'teacher@school.com',
                keyboardType: TextInputType.emailAddress,
                prefixIconData: Icons.email_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+91 9876543210',
                keyboardType: TextInputType.phone,
                prefixIconData: Icons.phone_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _passwordController,
                label: 'Initial Password',
                hint: 'Min 8 characters',
                obscureText: true,
                prefixIconData: Icons.lock_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            // Section: Professional Info
            _SectionLabel(label: 'Professional Details'),
            const SizedBox(height: AppDimensions.space12),
            AppTextField(
              controller: _employeeCodeController,
              label: 'Employee Code',
              hint: 'e.g. TCH001',
              prefixIconData: Icons.badge_outlined,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.characters,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Employee code is required';
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _specializationController,
              label: 'Specialization (optional)',
              hint: 'e.g. Mathematics, Science',
              prefixIconData: Icons.school_outlined,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: AppDimensions.space16),

            // Join Date picker
            Text('Join Date (optional)',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimensions.space8),
            GestureDetector(
              onTap: _pickJoinDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface50,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
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
                      _joinDate != null
                          ? DateFormatter.formatDate(_joinDate!)
                          : 'Select join date',
                      style: AppTypography.bodyMedium.copyWith(
                        color: _joinDate != null
                            ? AppColors.grey800
                            : AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space32),

            AppButton.primary(
              label: isEditing ? 'Update Teacher' : 'Create Teacher',
              onTap: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: isEditing ? Icons.check_rounded : Icons.person_add_outlined,
            ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.grey400,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}
