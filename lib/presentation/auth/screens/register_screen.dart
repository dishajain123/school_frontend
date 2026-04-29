import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _teacherIdentifierController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  final _childAdmissionNumbersController = TextEditingController();
  final _fullNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _teacherIdentifierFocus = FocusNode();
  final _childAdmissionNumbersFocus = FocusNode();
  final _studentAdmissionFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  UserRole _selectedRole = UserRole.teacher;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teacherIdentifierController.dispose();
    _admissionNumberController.dispose();
    _childAdmissionNumbersController.dispose();
    _fullNameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _teacherIdentifierFocus.dispose();
    _childAdmissionNumbersFocus.dispose();
    _studentAdmissionFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final submittedData = <String, dynamic>{};
      if (_selectedRole == UserRole.student) {
        submittedData['admission_number'] =
            _admissionNumberController.text.trim();
      }
      if (_selectedRole == UserRole.teacher) {
        submittedData['teacher_identifier'] =
            _teacherIdentifierController.text.trim();
      }
      if (_selectedRole == UserRole.parent) {
        final tokens = _childAdmissionNumbersController.text
            .split(RegExp(r'[\n,]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        submittedData['student_admission_number'] = tokens.first;
        submittedData['child_admission_numbers'] = tokens;
      }

      await ref.read(authRepositoryProvider).registerSelf(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            submittedData: submittedData.isEmpty ? null : submittedData,
          );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Request submitted'),
          content: const Text(
            'Your account request has been submitted successfully. '
            'Please wait for school approval, then sign in from Welcome Back.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go(RouteNames.login);
    } catch (e) {
      final message = _errorMessage(e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _errorMessage(Object e) {
    if (e is AppException) return e.message;
    if (e is DioException) {
      final nested = e.error;
      if (nested is AppException) return nested.message;
      if (e.message != null && e.message!.trim().isNotEmpty) {
        return e.message!.trim();
      }
    }
    return 'Could not submit registration. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: const Text('Apply for Access'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New User Registration',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your details. Your account will stay pending until approved by school admin.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    UserRole.teacher,
                    UserRole.student,
                    UserRole.parent,
                    UserRole.principal,
                    UserRole.trustee,
                  ]
                      .map(
                        (role) => DropdownMenuItem<UserRole>(
                          value: role,
                          child: Text(_staticRoleLabel(role)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedRole = value);
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _fullNameController,
                  focusNode: _fullNameFocus,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIconData: Icons.person_outline,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_emailFocus),
                  validator: (v) => Validators.validateRequired(v, 'Full name'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email Address',
                  hint: 'you@school.com',
                  keyboardType: TextInputType.emailAddress,
                  prefixIconData: Icons.email_outlined,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_phoneFocus),
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  label: 'Phone Number',
                  hint: '+91 9876543210',
                  keyboardType: TextInputType.phone,
                  prefixIconData: Icons.phone_outlined,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) {
                    if (_selectedRole == UserRole.parent) {
                      FocusScope.of(context).requestFocus(_childAdmissionNumbersFocus);
                    } else if (_selectedRole == UserRole.teacher) {
                      FocusScope.of(context).requestFocus(_teacherIdentifierFocus);
                    } else if (_selectedRole == UserRole.student) {
                      FocusScope.of(context).requestFocus(_studentAdmissionFocus);
                    } else {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    }
                  },
                  validator: Validators.validatePhone,
                ),
                if (_selectedRole == UserRole.parent) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _childAdmissionNumbersController,
                    focusNode: _childAdmissionNumbersFocus,
                    label: 'Child Admission Number(s)',
                    hint: 'Example: ADM-2025-1001, ADM-2025-1002',
                    prefixIconData: Icons.badge_outlined,
                    maxLines: 3,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    helperText:
                        'Add one or multiple admission IDs separated by comma or new line.',
                    validator: (v) => Validators.validateRequired(
                      v,
                      'Child admission number(s)',
                    ),
                  ),
                ],
                if (_selectedRole == UserRole.teacher) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _teacherIdentifierController,
                    focusNode: _teacherIdentifierFocus,
                    label: 'Teacher Identifier',
                    hint: 'Example: TCH-2025-0104',
                    prefixIconData: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    validator: (v) => Validators.validateRequired(
                      v,
                      'Teacher identifier',
                    ),
                  ),
                ],
                if (_selectedRole == UserRole.student) ...[
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _admissionNumberController,
                    focusNode: _studentAdmissionFocus,
                    label: 'Student Admission Number',
                    hint: 'Example: ADM-2025-1001',
                    prefixIconData: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) =>
                        FocusScope.of(context).requestFocus(_passwordFocus),
                    validator: (v) => Validators.validateRequired(
                      v,
                      'Student admission number',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppTextField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: 'Password',
                  hint: 'Create password',
                  obscureText: true,
                  prefixIconData: Icons.lock_outline,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confirmPasswordFocus),
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  obscureText: true,
                  prefixIconData: Icons.lock_outline,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) =>
                      Validators.validateConfirmPassword(v, _passwordController.text),
                ),
                const SizedBox(height: 24),
                AppButton.primary(
                  label: 'Submit for Approval',
                  onTap: _submitting ? null : _submit,
                  isLoading: _submitting,
                ),
                const SizedBox(height: 10),
                AppButton.text(
                  label: 'Back to Welcome Back',
                  onTap: () => context.go(RouteNames.login),
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _staticRoleLabel(UserRole role) {
  switch (role) {
    case UserRole.teacher:
      return 'Teacher';
    case UserRole.student:
      return 'Student';
    case UserRole.parent:
      return 'Parent';
    case UserRole.principal:
      return 'Principal';
    case UserRole.superadmin:
      return 'Superadmin';
    case UserRole.trustee:
      return 'Trustee';
  }
}
