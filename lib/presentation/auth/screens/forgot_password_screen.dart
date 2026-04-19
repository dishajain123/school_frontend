import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _usePhone = false;

  late AnimationController _animController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.push(RouteNames.verifyOtp, extra: {
      _usePhone ? 'phone' : 'email': _emailController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: Column(
        children: [
          _ForgotHeader(onBack: () => context.pop()),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _IconHeader(
                          icon: Icons.lock_reset_rounded,
                          color: AppColors.navyDeep,
                          bgColor:
                              AppColors.navyDeep.withValues(alpha: 0.08),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Forgot your password?',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            color: AppColors.grey800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No worries! Enter your ${_usePhone ? 'phone number' : 'email address'} '
                          'and we\'ll send you a one-time verification code.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _ToggleRow(
                          usePhone: _usePhone,
                          onToggle: () => setState(
                              () => _usePhone = !_usePhone),
                        ),
                        const SizedBox(height: 20),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: AppTextField(
                            key: ValueKey(_usePhone),
                            controller: _emailController,
                            label: _usePhone
                                ? 'Phone Number'
                                : 'Email Address',
                            hint: _usePhone
                                ? '+91 9876543210'
                                : 'you@school.com',
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
                        ),
                        const SizedBox(height: 32),
                        AppButton.primary(
                          label: 'Send OTP',
                          onTap: _isLoading ? null : _submit,
                          isLoading: _isLoading,
                          icon: Icons.send_rounded,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Back to sign in',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.navyMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotHeader extends StatelessWidget {
  const _ForgotHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Reset Password',
            style: AppTypography.titleLargeOnDark.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.usePhone, required this.onToggle});
  final bool usePhone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            usePhone ? Icons.email_outlined : Icons.phone_outlined,
            size: 14,
            color: AppColors.navyMedium,
          ),
          const SizedBox(width: 6),
          Text(
            usePhone ? 'Use email instead' : 'Use phone instead',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.navyMedium,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconHeader extends StatelessWidget {
  const _IconHeader({
    required this.icon,
    required this.color,
    required this.bgColor,
  });
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, size: 28, color: color),
    );
  }
}