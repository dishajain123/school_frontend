import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

/// Reset password screen stub for FM04.
/// FM05 will wire the actual API call via [AuthProvider].
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.resetToken,
  });

  final String resetToken;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // Password strength indicators
  bool get _hasMinLength =>
      _newPasswordController.text.length >= 8;
  bool get _hasUppercase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit =>
      _newPasswordController.text.contains(RegExp(r'\d'));

  double get _strength {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasDigit) score++;
    return score / 3;
  }

  Color get _strengthColor {
    if (_strength < 0.4) return AppColors.errorRed;
    if (_strength < 0.8) return AppColors.warningAmber;
    return AppColors.successGreen;
  }

  String get _strengthLabel {
    if (_strength < 0.4) return 'Weak';
    if (_strength < 0.8) return 'Medium';
    return 'Strong';
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // FM05 will make the real API call here.
    // For now navigate to login with success.
    context.go(RouteNames.login);
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
          'New Password',
          style: AppTypography.titleLargeOnDark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.space24),

                      // Icon
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outlined,
                            size: 40,
                            color: AppColors.successGreen,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppDimensions.space24),

                      Text(
                        'Create new password',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Your new password must be at least 8 characters '
                        'with one uppercase letter and one number.',
                        style: AppTypography.bodyMedium,
                      ),

                      const SizedBox(height: AppDimensions.space32),

                      AppTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Enter new password',
                        obscureText: true,
                        prefixIconData: Icons.lock_outlined,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() {}),
                        validator: Validators.validatePassword,
                      ),

                      const SizedBox(height: AppDimensions.space12),

                      // Strength indicator
                      if (_newPasswordController.text.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusFull),
                                child: LinearProgressIndicator(
                                  value: _strength,
                                  backgroundColor: AppColors.surface200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _strengthColor),
                                  minHeight: 4,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Text(
                              _strengthLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: _strengthColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        _PasswordRequirement(
                          met: _hasMinLength,
                          label: 'At least 8 characters',
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        _PasswordRequirement(
                          met: _hasUppercase,
                          label: 'One uppercase letter',
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        _PasswordRequirement(
                          met: _hasDigit,
                          label: 'One number',
                        ),
                        const SizedBox(height: AppDimensions.space16),
                      ],

                      const SizedBox(height: AppDimensions.space8),

                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter password',
                        obscureText: true,
                        prefixIconData: Icons.lock_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        validator: (v) => Validators.validateConfirmPassword(
                          v,
                          _newPasswordController.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Pinned submit button
            Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageHorizontal,
                AppDimensions.space12,
                AppDimensions.pageHorizontal,
                AppDimensions.space24,
              ),
              child: AppButton.primary(
                label: 'Set New Password',
                onTap: _isLoading ? null : _submit,
                isLoading: _isLoading,
                icon: Icons.check_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordRequirement extends StatelessWidget {
  const _PasswordRequirement({
    required this.met,
    required this.label,
  });

  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: met ? AppColors.successGreen : AppColors.grey400,
          ),
        ),
        const SizedBox(width: AppDimensions.space4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.successGreen : AppColors.grey400,
          ),
        ),
      ],
    );
  }
}