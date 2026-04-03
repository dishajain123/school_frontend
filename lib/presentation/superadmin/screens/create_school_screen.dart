import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
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
  ConsumerState<CreateSchoolScreen> createState() => _CreateSchoolScreenState();
}

class _CreateSchoolScreenState extends ConsumerState<CreateSchoolScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  SubscriptionPlan _plan = SubscriptionPlan.basic;

  bool get _isEditMode => widget.existingSchool != null;

  @override
  void initState() {
    super.initState();
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
        _isEditMode
            ? 'School updated successfully'
            : 'School created successfully',
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _nameController,
              label: 'School Name',
              hint: 'Green Valley School',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'School name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _emailController,
              label: 'Contact Email',
              hint: 'admin@school.edu',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return 'Contact email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _phoneController,
              label: 'Contact Phone',
              hint: '+91 9876543210',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'School full address',
              maxLines: 3,
            ),
            const SizedBox(height: AppDimensions.space16),
            DropdownButtonFormField<SubscriptionPlan>(
              initialValue: _plan,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Subscription Plan',
                filled: true,
                fillColor: AppColors.surface50,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.surface200,
                    width: AppDimensions.borderMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.surface200,
                    width: AppDimensions.borderMedium,
                  ),
                ),
              ),
              items: SubscriptionPlan.values
                  .map(
                    (plan) => DropdownMenuItem(
                      value: plan,
                      child: Text(plan.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _plan = value);
              },
            ),
            const SizedBox(height: AppDimensions.space32),
            AppButton.primary(
              label: _isEditMode ? 'Save Changes' : 'Create School',
              onTap: isSubmitting ? null : _submit,
              isLoading: isSubmitting,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}
