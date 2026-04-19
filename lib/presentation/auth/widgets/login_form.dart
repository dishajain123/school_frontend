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
          _SectionLabel(label: 'Sign in with'),
          const SizedBox(height: 10),
          _TabToggle(
            controller: _tabController,
            tabs: const ['Email', 'Phone'],
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
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
          const SizedBox(height: 16),
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
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RememberMe(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
              ),
              GestureDetector(
                onTap: () => context.push(RouteNames.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.navyMedium,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          AppButton.primary(
            label: 'Sign In',
            onTap: isLoading ? null : _submit,
            isLoading: isLoading,
            icon: Icons.login_rounded,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.surface200, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Need help?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey400,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.surface200, thickness: 1)),
            ],
          ),
          const SizedBox(height: 16),
          AppButton.secondary(
            label: 'Contact Administrator',
            onTap: () {},
            icon: Icons.support_agent_outlined,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey500,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.controller, required this.tabs});
  final TabController controller;
  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: AppTypography.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(
          fontSize: 13,
        ),
        labelColor: AppColors.navyDeep,
        unselectedLabelColor: AppColors.grey400,
        dividerColor: Colors.transparent,
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}

class _RememberMe extends StatelessWidget {
  const _RememberMe({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: value ? AppColors.navyDeep : AppColors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: value ? AppColors.navyDeep : AppColors.surface200,
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: AppColors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Remember me',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}