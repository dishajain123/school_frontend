import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _usePhone = false;
  bool _rememberMe = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;
      setState(() {
        _usePhone = _tabController.index == 1;
        _identifierController.clear();
        _formKey.currentState?.reset();
      });
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final identifier = _identifierController.text.trim();
    await ref.read(authNotifierProvider.notifier).login(
          email: _usePhone ? null : identifier.toLowerCase(),
          phone: _usePhone ? identifier : null,
          password: _passwordController.text,
        );
    // Navigation is handled by GoRouter redirect on auth state change
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email / Phone toggle
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
              labelStyle: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w600),
              unselectedLabelStyle: AppTypography.labelMedium,
              labelColor: AppColors.navyDeep,
              unselectedLabelColor: AppColors.grey400,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(3),
              tabs: const [Tab(text: 'Email'), Tab(text: 'Phone')],
            ),
          ),

          const SizedBox(height: AppDimensions.space24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _usePhone
                ? AppTextField(
                    key: const ValueKey('phone'),
                    controller: _identifierController,
                    label: 'Phone Number',
                    hint: '+91 9876543210',
                    keyboardType: TextInputType.phone,
                    prefixIconData: Icons.phone_outlined,
                    textInputAction: TextInputAction.next,
                    validator: Validators.validatePhone,
                  )
                : AppTextField(
                    key: const ValueKey('email'),
                    controller: _identifierController,
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
                  Text('Remember me', style: AppTypography.labelMedium),
                ],
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.forgotPassword),
                child: Text('Forgot password?',
                    style: AppTypography.bodyMediumLink),
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space32),

          AppButton.primary(
            label: 'Sign In',
            onTap: isLoading ? null : _submit,
            isLoading: isLoading,
            icon: Icons.login_rounded,
          ),

          const SizedBox(height: AppDimensions.space16),

          Row(
            children: [
              const Expanded(
                  child: Divider(color: AppColors.surface200)),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space12),
                child:
                    Text('Need help?', style: AppTypography.labelMedium),
              ),
              const Expanded(
                  child: Divider(color: AppColors.surface200)),
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