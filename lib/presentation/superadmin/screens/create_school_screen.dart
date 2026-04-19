import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/school/school_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/school_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class CreateSchoolScreen extends ConsumerStatefulWidget {
  const CreateSchoolScreen({super.key, this.existingSchool});
  final SchoolModel? existingSchool;

  @override
  ConsumerState<CreateSchoolScreen> createState() =>
      _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends ConsumerState<CreateSchoolScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  SubscriptionPlan _plan = SubscriptionPlan.basic;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool get _isEditMode => widget.existingSchool != null;

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

    final existing = widget.existingSchool;
    if (existing != null) {
      _nameController.text = existing.name;
      _emailController.text = existing.contactEmail;
      _phoneController.text = existing.contactPhone ?? '';
      _addressController.text = existing.address ?? '';
      _plan = existing.subscriptionPlan;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'contact_email': _emailController.text.trim(),
      'subscription_plan': _plan.backendValue,
      if (_phoneController.text.trim().isNotEmpty)
        'contact_phone': _phoneController.text.trim(),
      if (_addressController.text.trim().isNotEmpty)
        'address': _addressController.text.trim(),
    };
    final notifier = ref.read(schoolNotifierProvider.notifier);
    final SchoolModel? result;
    if (_isEditMode) {
      result = await notifier.updateSchool(
        schoolId: widget.existingSchool!.id,
        payload: payload,
      );
    } else {
      result = await notifier.create(payload);
    }
    if (!mounted) return;
    if (result != null) {
      SnackbarUtils.showSuccess(
        context,
        _isEditMode ? 'School updated successfully' : 'School created successfully',
      );
      context.pop(true);
    } else {
      final error = ref.read(schoolNotifierProvider).valueOrNull?.error ??
          (_isEditMode ? 'Failed to update school' : 'Failed to create school');
      SnackbarUtils.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isSubmitting =
        ref.watch(schoolNotifierProvider).valueOrNull?.isSubmitting ?? false;

    if (user?.role != UserRole.superadmin) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School', showBack: true),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only superadmin can manage schools.',
        ),
      );
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: _isEditMode ? 'Edit School' : 'Create School',
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
                      _FormCard(
                        title: 'School Information',
                        icon: Icons.business_outlined,
                        children: [
                          AppTextField(
                            controller: _nameController,
                            label: 'School Name',
                            hint: 'Green Valley School',
                            prefixIconData: Icons.school_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'School name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _addressController,
                            label: 'Address',
                            hint: 'School full address',
                            prefixIconData: Icons.location_on_outlined,
                            maxLines: 2,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Contact Information',
                        icon: Icons.contact_mail_outlined,
                        children: [
                          AppTextField(
                            controller: _emailController,
                            label: 'Contact Email',
                            hint: 'admin@school.edu',
                            prefixIconData: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Contact email is required';
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                                  .hasMatch(val)) {
                                return 'Enter a valid email address';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _phoneController,
                            label: 'Contact Phone',
                            hint: '+91 9876543210',
                            prefixIconData: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Subscription Plan',
                        icon: Icons.card_membership_outlined,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SubscriptionPlan.values.map((plan) {
                              final isSelected = _plan == plan;
                              final color = _planColor(plan);
                              return GestureDetector(
                                onTap: () => setState(() => _plan = plan),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.1)
                                        : AppColors.surface50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.5)
                                          : AppColors.surface200,
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: color
                                                  .withValues(alpha: 0.15),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    plan.label,
                                    style: AppTypography.labelMedium.copyWith(
                                      color: isSelected
                                          ? color
                                          : AppColors.grey700,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _SubmitBar(
                  isEditMode: _isEditMode,
                  isSubmitting: isSubmitting,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _planColor(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.basic:
        return AppColors.infoBlue;
      case SubscriptionPlan.standard:
        return AppColors.warningAmber;
      case SubscriptionPlan.premium:
        return AppColors.successGreen;
    }
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
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isEditMode,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool isEditMode;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: isEditMode ? 'Save Changes' : 'Create School',
        onTap: isSubmitting ? null : onSubmit,
        isLoading: isSubmitting,
        icon: isEditMode
            ? Icons.save_outlined
            : Icons.check_circle_outline_rounded,
      ),
    );
  }
}