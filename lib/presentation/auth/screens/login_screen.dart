import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/login_form.dart';
import '../widgets/school_logo.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static ({String message, bool approvalState}) _normalizeLoginMessage(
      String raw) {
    final text = raw.trim();
    final lower = text.toLowerCase();
    if (lower.contains('pending approval')) {
      return (
        message:
            'Your account is waiting for school approval. Please try again later.',
        approvalState: true
      );
    }
    if (lower.contains('on hold') || lower.contains('currently on hold')) {
      return (
        message:
            'Your account is currently on hold. Please contact the school office.',
        approvalState: true
      );
    }
    if (lower.contains('rejected')) {
      return (
        message:
            'Your account request was rejected. Please contact the school office.',
        approvalState: true
      );
    }
    return (message: text, approvalState: false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AuthState>(authNotifierProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.error != null) {
        final normalized = _normalizeLoginMessage(next.error!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                    normalized.approvalState
                        ? Icons.info_outline_rounded
                        : Icons.error_outline_rounded,
                    color: AppColors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(normalized.message)),
              ],
            ),
            backgroundColor: normalized.approvalState
                ? AppColors.warningAmber
                : AppColors.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Column(
            children: [
              const _LoginHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface50,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.pageHorizontal,
                      AppDimensions.space32,
                      AppDimensions.pageHorizontal,
                      AppDimensions.space32,
                    ),
                    child: const LoginForm(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.fromLTRB(AppDimensions.pageHorizontal, top + 32,
          AppDimensions.pageHorizontal, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SchoolLogo(size: 44, borderRadius: 12, imagePadding: 6),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: AppTypography.titleLargeOnDark.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Smart School Platform',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Welcome back',
            style: AppTypography.headlineLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue to your campus',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
