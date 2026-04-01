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

/// Login form widget.
///
/// FM05 will connect this to [AuthProvider.login].
/// For now the form validates and shows a loading state.
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _usePhone = false;
  bool _rememberMe = false;
  String? _errorMessage;

  // Tab animation
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _usePhone = _tabController.index == 1;
        _errorMessage = null;
        _emailController.clear();
      });
    });
  }

  @override
  void dispose() {
    _formKey.currentState?.reset();
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // FM05 will call AuthProvider.login here.
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // For FM04 stub: show placeholder error (FM05 replaces this).
    setState(() => _errorMessage =
        'Authentication not yet implemented. FM05 will wire this up.');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email / Phone tab switch
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface100,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.white,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall - 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0B1F3A),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTypography.labelMedium,
              labelColor: AppColors.navyDeep,
              unselectedLabelColor: AppColors.grey400,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: const [
                Tab(text: 'Email'),
                Tab(text: 'Phone'),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.space24),

          // Email or Phone field
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _usePhone
                ? AppTextField(
                    key: const ValueKey('phone'),
                    controller: _emailController,
                    label: 'Phone Number',
                    hint: '+91 9876543210',
                    keyboardType: TextInputType.phone,
                    prefixIconData: Icons.phone_outlined,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validatePhone,
                  )
                : AppTextField(
                    key: const ValueKey('email'),
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'you@school.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIconData: Icons.email_outlined,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.none,
                    validator: Validators.validateEmail,
                  ),
          ),

          const SizedBox(height: AppDimensions.space16),

          AppTextField(
            controller: _passwordController,
            label: 'Password',
            hint: 'Enter your password',
            obscureText: true,
            prefixIconData: Icons.lock_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              return null;
            },
          ),

          const SizedBox(height: AppDimensions.space12),

          // Remember me + Forgot password
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                      activeColor: AppColors.navyDeep,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.space4),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Text(
                    'Remember me',
                    style: AppTypography.labelMedium,
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.bodyMediumLink,
                ),
              ),
            ],
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: AppDimensions.space16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(
                    color: AppColors.errorRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      size: 16, color: AppColors.errorRed),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.errorDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppDimensions.space32),

          AppButton.primary(
            label: 'Sign In',
            onTap: _isLoading ? null : _submit,
            isLoading: _isLoading,
            icon: Icons.login_rounded,
          ),

          const SizedBox(height: AppDimensions.space16),

          // Divider
          Row(
            children: [
              const Expanded(
                child: Divider(color: AppColors.surface200),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12),
                child: Text(
                  'Need help?',
                  style: AppTypography.labelMedium,
                ),
              ),
              const Expanded(
                child: Divider(color: AppColors.surface200),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space16),

          AppButton.secondary(
            label: 'Contact Administrator',
            onTap: () {},
            icon: Icons.support_agent_outlined,
          ),
        ],
      ),
    );
  }
}