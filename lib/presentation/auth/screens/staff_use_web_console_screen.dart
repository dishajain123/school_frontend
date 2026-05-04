import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';

/// Staff Admin (STAFF_ADMIN) uses the web Admin Console for school operations.
class StaffUseWebConsoleScreen extends ConsumerWidget {
  const StaffUseWebConsoleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).currentUser;
    return Scaffold(
      backgroundColor: AppColors.navyDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Icon(Icons.desktop_windows_outlined,
                  size: 56, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(height: 24),
              Text(
                'Admin Console',
                style: AppTypography.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'School administration is done in the web Admin Console. '
                'This mobile app is for principals, teachers, trustees, parents, and students.',
                style: AppTypography.bodyLarge.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
              if ((user?.email ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  user!.email!.trim(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: () =>
                    ref.read(authNotifierProvider.notifier).logout(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navyDeep,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
