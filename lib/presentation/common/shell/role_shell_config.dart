import 'package:flutter/material.dart';
import '../../../core/router/route_names.dart';

/// Configuration model for a single bottom navigation tab.
class ShellTabItem {
  const ShellTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.rootPath,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// The root route this tab navigates to.
  final String rootPath;
}

/// Defines which navigation tabs are shown per role.
abstract final class RoleShellConfig {
  static const List<ShellTabItem> superadminTabs = [
    ShellTabItem(
      icon: Icons.business_outlined,
      activeIcon: Icons.business,
      label: 'Schools',
      rootPath: RouteNames.schools,
    ),
    ShellTabItem(
      icon: Icons.tune_outlined,
      activeIcon: Icons.tune,
      label: 'Settings',
      rootPath: RouteNames.schoolSettings,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  static const List<ShellTabItem> principalTabs = [
    ShellTabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      rootPath: RouteNames.dashboard,
    ),
    ShellTabItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Students',
      rootPath: RouteNames.students,
    ),
    ShellTabItem(
      icon: Icons.co_present_outlined,
      activeIcon: Icons.co_present,
      label: 'Teachers',
      rootPath: RouteNames.teachers,
    ),
    ShellTabItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reports',
      rootPath: RouteNames.principalReportDetails,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  static const List<ShellTabItem> trusteeTabs = [
    ShellTabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      rootPath: RouteNames.dashboard,
    ),
    ShellTabItem(
      icon: Icons.school_outlined,
      activeIcon: Icons.school,
      label: 'Students',
      rootPath: RouteNames.students,
    ),
    ShellTabItem(
      icon: Icons.co_present_outlined,
      activeIcon: Icons.co_present,
      label: 'Teachers',
      rootPath: RouteNames.teachers,
    ),
    ShellTabItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Reports',
      rootPath: RouteNames.attendance,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  static const List<ShellTabItem> teacherTabs = [
    ShellTabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      rootPath: RouteNames.dashboard,
    ),
    ShellTabItem(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
      label: 'Attendance',
      rootPath: RouteNames.attendance,
    ),
    ShellTabItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Assignments',
      rootPath: RouteNames.assignments,
    ),
    ShellTabItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Diary',
      rootPath: RouteNames.diary,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  static const List<ShellTabItem> studentTabs = [
    ShellTabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      rootPath: RouteNames.dashboard,
    ),
    ShellTabItem(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
      label: 'Attendance',
      rootPath: RouteNames.attendance,
    ),
    ShellTabItem(
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment,
      label: 'Assignments',
      rootPath: RouteNames.assignments,
    ),
    ShellTabItem(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Diary',
      rootPath: RouteNames.diary,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  static const List<ShellTabItem> parentTabs = [
    ShellTabItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      rootPath: RouteNames.dashboard,
    ),
    ShellTabItem(
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check,
      label: 'Attendance',
      rootPath: RouteNames.attendance,
    ),
    ShellTabItem(
      icon: Icons.home_work_outlined,
      activeIcon: Icons.home_work,
      label: 'Homework',
      rootPath: RouteNames.homework,
    ),
    ShellTabItem(
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet,
      label: 'Fees',
      rootPath: RouteNames.feeDashboard,
    ),
    ShellTabItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      rootPath: RouteNames.profile,
    ),
  ];

  /// Returns the tab config for the given role string.
  static List<ShellTabItem> tabsForRole(String role) {
    switch (role.toUpperCase()) {
      case 'SUPERADMIN':
        return superadminTabs;
      case 'PRINCIPAL':
        return principalTabs;
      case 'TRUSTEE':
        return trusteeTabs;
      case 'TEACHER':
        return teacherTabs;
      case 'STUDENT':
        return studentTabs;
      case 'PARENT':
        return parentTabs;
      default:
        return studentTabs;
    }
  }

  /// Returns the index for a given route path in the tab list.
  static int indexForPath(List<ShellTabItem> tabs, String location) {
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].rootPath)) return i;
    }
    return 0;
  }
}
