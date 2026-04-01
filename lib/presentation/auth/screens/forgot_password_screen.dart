import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

/// Forgot password screen stub for FM04.
/// FM05 will wire the actual API call.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _usePhone = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to OTP screen with the identifier.
    context.push(RouteNames.verifyOtp, extra: {
      _usePhone ? 'phone' : 'email': _emailController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Forgot Password',
          style: AppTypography.titleLargeOnDark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.space24),

                // Illustration
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      size: 40,
                      color: AppColors.navyDeep,
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.space24),

                Text(
                  'Reset your password',
                  style: AppTypography.headlineSmall,
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Enter your ${_usePhone ? 'phone number' : 'email address'} '
                  'and we\'ll send you a one-time code.',
                  style: AppTypography.bodyMedium,
                ),

                const SizedBox(height: AppDimensions.space16),

                // Toggle email/phone
                Row(
                  children: [
                    Text(
                      'Use ',
                      style: AppTypography.bodySmall,
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _usePhone = !_usePhone),
                      child: Text(
                        _usePhone ? 'email instead' : 'phone instead',
                        style: AppTypography.bodyMediumLink,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space24),

                AppTextField(
                  controller: _emailController,
                  label: _usePhone ? 'Phone Number' : 'Email Address',
                  hint: _usePhone ? '+91 9876543210' : 'you@school.com',
                  keyboardType: _usePhone
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  prefixIconData: _usePhone
                      ? Icons.phone_outlined
                      : Icons.email_outlined,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return _usePhone
                          ? 'Phone number is required'
                          : 'Email is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppDimensions.space32),

                AppButton.primary(
                  label: 'Send OTP',
                  onTap: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}