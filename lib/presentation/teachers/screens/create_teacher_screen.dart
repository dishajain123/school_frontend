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

class _CreateTeacherScreenState extends ConsumerState<CreateTeacherScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeCodeController = TextEditingController();
  final _specializationController = TextEditingController();

  DateTime? _joinDate;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

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
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickJoinDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: AppColors.white,
            surface: AppColors.white,
          ),
        ),
        child: child!,
      ),
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
      if (mounted) SnackbarUtils.showError(context, e.toString());
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
      body: FadeTransition(
        opacity: _fade,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              if (!isEditing) ...[
                _FormCard(
                  title: 'Account Information',
                  icon: Icons.person_outline_rounded,
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'Email Address',
                      hint: 'teacher@school.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIconData: Icons.email_outlined,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      hint: '+91 9876543210',
                      keyboardType: TextInputType.phone,
                      prefixIconData: Icons.phone_outlined,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Initial Password',
                      hint: 'Min 8 characters',
                      obscureText: true,
                      prefixIconData: Icons.lock_outlined,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validatePassword,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              _FormCard(
                title: 'Professional Details',
                icon: Icons.work_outline_rounded,
                children: [
                  AppTextField(
                    controller: _employeeCodeController,
                    label: 'Employee Code',
                    hint: 'e.g. TCH001',
                    prefixIconData: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Employee code is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _specializationController,
                    label: 'Specialization (optional)',
                    hint: 'e.g. Mathematics, Science',
                    prefixIconData: Icons.school_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 16),
                  _JoinDatePicker(
                    selectedDate: _joinDate,
                    onTap: _pickJoinDate,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              AppButton.primary(
                label: isEditing ? 'Update Teacher' : 'Create Teacher',
                onTap: _isLoading ? null : _submit,
                isLoading: _isLoading,
                icon: isEditing
                    ? Icons.check_rounded
                    : Icons.person_add_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Form Card ──────────────────────────────────────────────────────────────────

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
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Join Date Picker ───────────────────────────────────────────────────────────

class _JoinDatePicker extends StatelessWidget {
  const _JoinDatePicker({
    required this.selectedDate,
    required this.onTap,
  });

  final DateTime? selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Join Date (optional)',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate ? AppColors.navyMedium : AppColors.surface200,
                width: hasDate ? 1.5 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: hasDate ? AppColors.navyMedium : AppColors.grey400,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasDate
                        ? DateFormatter.formatDate(selectedDate!)
                        : 'Select join date',
                    style: AppTypography.bodyMedium.copyWith(
                      color: hasDate ? AppColors.grey800 : AppColors.grey400,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (hasDate)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Change',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.navyMedium,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  )
                else
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: AppColors.grey400),
              ],
            ),
          ),
        ),
      ],
    );
  }
}