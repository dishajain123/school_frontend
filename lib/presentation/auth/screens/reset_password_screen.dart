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
    extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool get _hasMinLength => _newPasswordController.text.length >= 8;
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isLoading = false);

    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: Column(
        children: [
          _ResetHeader(onBack: () => context.pop()),
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
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_outlined,
                            size: 28,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Create new password',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                            color: AppColors.grey800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your password must be at least 8 characters with one uppercase letter and one number.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey500,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
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
                        if (_newPasswordController.text.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _StrengthIndicator(
                            strength: _strength,
                            color: _strengthColor,
                            label: _strengthLabel,
                          ),
                          const SizedBox(height: 10),
                          _RequirementsList(
                            hasMinLength: _hasMinLength,
                            hasUppercase: _hasUppercase,
                            hasDigit: _hasDigit,
                          ),
                          const SizedBox(height: 4),
                        ] else
                          const SizedBox(height: 16),
                        AppTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          obscureText: true,
                          prefixIconData: Icons.lock_outlined,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          validator: (v) =>
                              Validators.validateConfirmPassword(
                            v,
                            _newPasswordController.text,
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _BottomAction(
            isLoading: _isLoading,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _ResetHeader extends StatelessWidget {
  const _ResetHeader({required this.onBack});
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
            'New Password',
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

class _StrengthIndicator extends StatelessWidget {
  const _StrengthIndicator({
    required this.strength,
    required this.color,
    required this.label,
  });
  final double strength;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: LinearProgressIndicator(
                value: strength,
                backgroundColor: AppColors.surface200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          child: Text(label),
        ),
      ],
    );
  }
}

class _RequirementsList extends StatelessWidget {
  const _RequirementsList({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasDigit,
  });
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasDigit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        children: [
          _Requirement(met: hasMinLength, label: 'At least 8 characters'),
          const SizedBox(height: 6),
          _Requirement(met: hasUppercase, label: 'One uppercase letter'),
          const SizedBox(height: 6),
          _Requirement(met: hasDigit, label: 'One number'),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.met, required this.label});
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            key: ValueKey(met),
            size: 14,
            color: met ? AppColors.successGreen : AppColors.grey400,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: met ? AppColors.successGreen : AppColors.grey400,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({required this.isLoading, required this.onSubmit});
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        16,
        AppDimensions.pageHorizontal,
        bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(color: AppColors.surface100, width: 1),
        ),
      ),
      child: AppButton.primary(
        label: 'Set New Password',
        onTap: isLoading ? null : onSubmit,
        isLoading: isLoading,
        icon: Icons.check_rounded,
      ),
    );
  }
}
