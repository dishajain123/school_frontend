import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';

/// Displays a user role as a styled chip with role-specific color and icon.
///
/// Usage:
/// ```dart
/// RoleChip(role: UserRole.teacher)
/// RoleChip(role: UserRole.principal, small: true)
/// ```
class RoleChip extends StatelessWidget {
  const RoleChip({
    super.key,
    required this.role,
    this.small = false,
    this.showIcon = true,
  });

  final UserRole role;
  final bool small;
  final bool showIcon;

  _RoleStyle get _style => _roleStyles[role] ?? _roleStyles[UserRole.student]!;

  static final Map<UserRole, _RoleStyle> _roleStyles = {
    UserRole.superadmin: _RoleStyle(
      label: 'Super Admin',
      icon: Icons.admin_panel_settings_rounded,
      bg: const Color(0xFFF0F0FF),
      fg: const Color(0xFF4040C0),
    ),
    UserRole.principal: _RoleStyle(
      label: 'Principal',
      icon: Icons.school_rounded,
      bg: const Color(0xFFF0F7FF),
      fg: AppColors.navyDeep,
    ),
    UserRole.staffAdmin: _RoleStyle(
      label: 'Staff Admin',
      icon: Icons.admin_panel_settings_outlined,
      bg: const Color(0xFFE8EAF6),
      fg: const Color(0xFF3949AB),
    ),
    UserRole.trustee: _RoleStyle(
      label: 'Trustee',
      icon: Icons.account_balance_rounded,
      bg: const Color(0xFFFFF8E6),
      fg: const Color(0xFF996600),
    ),
    UserRole.teacher: _RoleStyle(
      label: 'Teacher',
      icon: Icons.person_rounded,
      bg: const Color(0xFFE8F5E9),
      fg: const Color(0xFF2E7D32),
    ),
    UserRole.parent: _RoleStyle(
      label: 'Parent',
      icon: Icons.family_restroom_rounded,
      bg: const Color(0xFFFCE4EC),
      fg: const Color(0xFFC62828),
    ),
    UserRole.student: _RoleStyle(
      label: 'Student',
      icon: Icons.menu_book_rounded,
      bg: const Color(0xFFE3F2FD),
      fg: const Color(0xFF1565C0),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final vPad = small ? 3.0 : 5.0;
    final hPad = small ? 8.0 : 10.0;
    final iconSize = small ? 11.0 : 13.0;
    final textStyle = small
        ? AppTypography.labelSmall
        : AppTypography.labelMedium;

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              style.icon,
              size: iconSize,
              color: style.fg,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            style.label,
            style: textStyle.copyWith(
              color: style.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleStyle {
  const _RoleStyle({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
  });

  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
}