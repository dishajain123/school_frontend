import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'parent_dashboard.dart';
import 'principal_dashboard.dart';
import 'trustee_dashboard.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    switch (user.role) {
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.parent:
        return const ParentDashboard();
      case UserRole.principal:
        return const PrincipalDashboard();
      case UserRole.staffAdmin:
        return const PrincipalDashboard();
      case UserRole.trustee:
        return const TrusteeDashboard();
      case UserRole.superadmin:
        return const PrincipalDashboard();
    }
  }
}