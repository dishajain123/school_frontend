import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';

class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({
    super.key,
    this.subtitle,
    this.showBackButton = false,
  });

  final String? subtitle;
  final bool showBackButton;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static String _displayName(CurrentUser? user) {
    if (user == null) return '';
    final fullName = user.fullName?.trim() ?? '';
    if (fullName.isNotEmpty) return fullName;
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final today = DateTime.now();
    final dayStr =
        '${_dayName(today.weekday)}, ${today.day} ${_monthName(today.month)} ${today.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        AppDimensions.space24,
        AppDimensions.pageHorizontal,
        AppDimensions.space24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusXL),
          bottomRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackButton) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 20,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space12),
          ],
          Row(
            children: [
              Expanded(
                child: Text(
                  dayStr,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            _displayName(user).isEmpty
                ? '${_greeting()} 👋'
                : '${_greeting()}, ${_displayName(user)} 👋',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              subtitle!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (user != null) ...[
            const SizedBox(height: AppDimensions.space12),
            _RoleBadge(role: user.role),
          ],
        ],
      ),
    );
  }

  static String _dayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[(weekday - 1).clamp(0, 6)];
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  String get _label {
    switch (role) {
      case UserRole.superadmin:
        return 'Super Admin';
      case UserRole.principal:
        return 'Principal';
      case UserRole.staffAdmin:
        return 'Staff Admin';
      case UserRole.trustee:
        return 'Trustee';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        _label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
