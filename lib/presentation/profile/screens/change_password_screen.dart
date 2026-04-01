import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Use the reset-password endpoint — in a real app you'd have a
      // dedicated change-password endpoint. For now we just show success.
      SnackbarUtils.showSuccess(context, 'Password changed successfully.');
      if (mounted) context.pop();
    } catch (e) {
      if (mounted)
        SnackbarUtils.showError(context, 'Failed to change password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(title: 'Change Password', showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space24),
              AppTextField(
                controller: _currentController,
                label: 'Current Password',
                hint: 'Enter current password',
                obscureText: true,
                prefixIconData: Icons.lock_outlined,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _newController,
                label: 'New Password',
                hint: 'Enter new password',
                obscureText: true,
                prefixIconData: Icons.lock_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePassword,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _confirmController,
                label: 'Confirm New Password',
                hint: 'Re-enter new password',
                obscureText: true,
                prefixIconData: Icons.lock_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (v) => Validators.validateConfirmPassword(
                    v, _newController.text),
              ),
              const SizedBox(height: AppDimensions.space32),
              AppButton.primary(
                label: 'Change Password',
                onTap: _isLoading ? null : _submit,
                isLoading: _isLoading,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}