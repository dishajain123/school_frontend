// lib/core/router/app_router.dart  [Mobile App]
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/auth/screens/enrollment_pending_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/verify_otp_screen.dart';
import '../../presentation/auth/screens/reset_password_screen.dart';
import '../../presentation/common/shell/main_shell.dart';
import '../../presentation/dashboard/screens/dashboard_screen.dart';
import '../../presentation/teachers/screens/teacher_analytics_screen.dart';
import '../../presentation/profile/screens/profile_screen.dart';
import '../../presentation/profile/screens/change_password_screen.dart';
import '../../presentation/notifications/screens/notification_inbox_screen.dart';
import '../../presentation/announcements/screens/announcement_list_screen.dart';
import '../../presentation/announcements/screens/announcement_detail_screen.dart';
import '../../presentation/announcements/screens/create_announcement_screen.dart';
import '../../presentation/academic_year/screens/academic_year_list_screen.dart';
import '../../presentation/academic_year/screens/rollover_screen.dart';
import '../../presentation/masters/screens/standards_screen.dart';
import '../../presentation/masters/screens/subjects_screen.dart';
import '../../presentation/masters/screens/grade_master_screen.dart';
import '../../presentation/teachers/screens/teacher_list_screen.dart';
import '../../presentation/teachers/screens/teacher_detail_screen.dart';
import '../../presentation/teachers/screens/create_teacher_screen.dart';
import '../../presentation/students/screens/student_list_screen.dart';
import '../../presentation/students/screens/student_detail_screen.dart';
import '../../presentation/students/screens/create_student_screen.dart';
import '../../presentation/parents/screens/parent_list_screen.dart';
import '../../presentation/parents/screens/parent_detail_screen.dart';
import '../../presentation/parents/screens/create_parent_screen.dart';
import '../../presentation/attendance/screens/attendance_list_screen.dart';
import '../../presentation/academic_year/screens/student_academic_history_screen.dart';
import '../../presentation/teacher_schedule/screens/teacher_schedule_screen.dart';
import '../../presentation/my_class/screens/subject_list_screen.dart';
import '../../presentation/my_class/screens/teacher_my_class_screen.dart';
import '../../presentation/my_class/screens/classroom_monitor_screen.dart';
import '../../presentation/fees/screens/fee_dashboard_screen.dart';
import '../../presentation/fees/screens/payment_history_screen.dart';
import '../../presentation/fees/screens/record_payment_screen.dart';
import '../../presentation/fees/screens/fee_receipt_screen.dart';
import '../../presentation/audit/screens/audit_logs_screen.dart';
import '../../data/models/announcement/announcement_model.dart';
import '../../data/models/auth/current_user.dart';
import '../../data/models/teacher/teacher_model.dart';
import '../../data/models/student/student_model.dart';
import '../../data/models/parent/parent_model.dart';
import '../../providers/auth_provider.dart';
import 'route_names.dart';

// Placeholder for screens not yet fully extracted but referenced in routing.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {super.key, this.showBack = false});
  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        automaticallyImplyLeading: showBack,
      ),
      body: Center(child: Text('$title — coming soon')),
    );
  }
}

String _roleToBackendValue(UserRole role) {
  switch (role) {
    case UserRole.superadmin:
      return 'SUPERADMIN';
    case UserRole.principal:
      return 'PRINCIPAL';
    case UserRole.trustee:
      return 'TRUSTEE';
    case UserRole.teacher:
      return 'TEACHER';
    case UserRole.student:
      return 'STUDENT';
    case UserRole.parent:
      return 'PARENT';
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild router when auth state changes so redirect logic re-evaluates.
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final loc = state.matchedLocation;
      final enrollmentPending = authState.currentUser?.enrollmentPending ?? false;

      final publicRoutes = {
        RouteNames.splash,
        RouteNames.login,
        RouteNames.register,
        RouteNames.enrollmentPending,
        RouteNames.forgotPassword,
        RouteNames.verifyOtp,
        RouteNames.resetPassword,
      };

      if (!isLoggedIn && !publicRoutes.contains(loc)) {
        return RouteNames.login;
      }
      // Always leave splash after auth initialization completes.
      if (loc == RouteNames.splash && authState.isInitialized) {
        if (!isLoggedIn) return RouteNames.login;
        return enrollmentPending ? RouteNames.enrollmentPending : RouteNames.dashboard;
      }
      if (isLoggedIn && enrollmentPending && loc != RouteNames.enrollmentPending) {
        return RouteNames.enrollmentPending;
      }
      if (isLoggedIn && !enrollmentPending && loc == RouteNames.enrollmentPending) {
        return RouteNames.dashboard;
      }
      if (isLoggedIn &&
          publicRoutes.contains(loc) &&
          loc != RouteNames.splash &&
          loc != RouteNames.enrollmentPending) {
        return RouteNames.dashboard;
      }
      return null;
    },
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: RouteNames.enrollmentPending,
        builder: (_, __) => const EnrollmentPendingScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VerifyOtpScreen(
            email: extra?['email'] as String?,
            phone: extra?['phone'] as String?,
          );
        },
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final token = extra?['resetToken'] as String? ?? '';
          return ResetPasswordScreen(resetToken: token);
        },
      ),

      // ── Shell (bottom nav) ────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final user = ref.read(authNotifierProvider).currentUser;
          final role = user == null ? '' : _roleToBackendValue(user.role);
          return MainShell(role: role, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),

          // ── Profile ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.profile,
            builder: (_, __) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'change-password',
                builder: (_, __) => const ChangePasswordScreen(),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.notifications,
            builder: (_, __) => const NotificationInboxScreen(),
          ),

          // ── Announcements ──────────────────────────────────────────────
          GoRoute(
            path: RouteNames.announcements,
            builder: (_, __) => const AnnouncementListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final existing = state.extra as AnnouncementModel?;
                  return CreateAnnouncementScreen(existing: existing);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final announcement = state.extra as AnnouncementModel?;
                  return AnnouncementDetailScreen(
                    announcementId: state.pathParameters['id']!,
                    initialAnnouncement: announcement,
                  );
                },
              ),
            ],
          ),

          // ── Academic Years ─────────────────────────────────────────────
          GoRoute(
            path: RouteNames.academicYears,
            builder: (_, __) => const AcademicYearListScreen(),
            routes: [
              GoRoute(
                path: 'rollover',
                builder: (_, __) => const RolloverScreen(),
              ),
            ],
          ),

          // ── Masters ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.standards,
            builder: (_, __) => const StandardsScreen(),
          ),
          GoRoute(
            path: RouteNames.subjects,
            builder: (_, __) => const SubjectsScreen(),
          ),
          GoRoute(
            path: RouteNames.gradeMaster,
            builder: (_, __) => const GradeMasterScreen(),
          ),

          // ── Teachers ───────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.teachers,
            builder: (_, __) => const TeacherListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateTeacherScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final teacher = state.extra as TeacherModel?;
                  return TeacherDetailScreen(
                    teacherId: state.pathParameters['id']!,
                    initialTeacher: teacher,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final teacher = state.extra as TeacherModel?;
                      return CreateTeacherScreen(existing: teacher);
                    },
                  ),
                  GoRoute(
                    path: 'analytics',
                    builder: (_, __) => const TeacherAnalyticsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ── Teacher Schedule (Phase 4 — wired to admin assignments) ───
          GoRoute(
            path: RouteNames.mySchedule,
            builder: (_, __) => const TeacherScheduleScreen(),
          ),

          // ── My Class (Student/Parent read view) ───────────────────────
          GoRoute(
            path: RouteNames.myClass,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return MyClassSubjectListScreen(
                childId: extra?['childId'] as String?,
                initialStandardId: extra?['standardId'] as String?,
                initialSectionId: extra?['sectionId'] as String?,
                initialSectionName: extra?['sectionName'] as String?,
                initialAcademicYearId: extra?['academicYearId'] as String?,
              );
            },
          ),

          // ── Teacher My Class (content management) ─────────────────────
          GoRoute(
            path: RouteNames.teacherMyClass,
            builder: (_, __) => const TeacherMyClassScreen(),
          ),
          GoRoute(
            path: RouteNames.classroomMonitor,
            builder: (_, __) => const ClassroomMonitorScreen(),
          ),

          // ── Students ───────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.students,
            builder: (_, __) => const StudentListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateStudentScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final student = state.extra as StudentModel?;
                  return StudentDetailScreen(
                    studentId: state.pathParameters['id']!,
                    initialStudent: student,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final student = state.extra as StudentModel?;
                      return CreateStudentScreen(existing: student);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Academic History (Phase 7/14) ──────────────────────────────
          // Accessible by: STUDENT (own), PARENT (child), TEACHER/PRINCIPAL (any)
          // Navigation: context.push('/academic-history/$studentId')
          GoRoute(
            path: '/academic-history/:studentId',
            builder: (context, state) {
              final studentId = state.pathParameters['studentId']!;
              return StudentAcademicHistoryScreen(studentId: studentId);
            },
          ),

          // ── Parents ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.parents,
            builder: (_, __) => const ParentListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateParentScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final parent = state.extra as ParentModel?;
                  return ParentDetailScreen(
                    parentId: state.pathParameters['id']!,
                    initialParent: parent,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final parent = state.extra as ParentModel?;
                      return CreateParentScreen(existing: parent);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ── Attendance ─────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.attendance,
            builder: (_, __) => const AttendanceListScreen(),
          ),

          // ── All other screens (placeholders kept for backward compat) ──
          GoRoute(
            path: RouteNames.assignments,
            builder: (_, __) => const PlaceholderScreen('Assignments'),
          ),
          GoRoute(
            path: RouteNames.homework,
            builder: (_, __) => const PlaceholderScreen('Homework'),
          ),
          GoRoute(
            path: RouteNames.diary,
            builder: (_, __) => const PlaceholderScreen('Diary'),
          ),
          GoRoute(
            path: RouteNames.timetable,
            builder: (_, __) => const PlaceholderScreen('Timetable'),
          ),
          GoRoute(
            path: RouteNames.examSchedules,
            builder: (_, __) => const PlaceholderScreen('Exam Schedule'),
          ),
          GoRoute(
            path: RouteNames.results,
            builder: (_, __) => const PlaceholderScreen('Results'),
          ),
          GoRoute(
            path: RouteNames.feeDashboard,
            builder: (context, state) {
              final studentId = state.uri.queryParameters['student_id'];
              return FeeDashboardScreen(studentId: studentId);
            },
          ),
          GoRoute(
            path: RouteNames.paymentHistory,
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return PaymentHistoryScreen.fromExtras(extra);
              }
              final ledgerId = state.uri.queryParameters['ledger_id'] ?? '';
              return PaymentHistoryScreen(ledgerId: ledgerId);
            },
          ),
          GoRoute(
            path: RouteNames.recordPayment,
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return RecordPaymentScreen.fromExtras(extra);
              }
              final studentId = state.uri.queryParameters['student_id'] ?? '';
              final ledgerId = state.uri.queryParameters['ledger_id'];
              return RecordPaymentScreen(studentId: studentId, ledgerId: ledgerId);
            },
          ),
          GoRoute(
            path: RouteNames.feeReceipt,
            builder: (context, state) {
              final extra = state.extra;
              if (extra is Map<String, dynamic>) {
                return FeeReceiptScreen.fromExtras(extra);
              }
              final paymentId = state.uri.queryParameters['payment_id'] ?? '';
              return FeeReceiptScreen(paymentId: paymentId);
            },
          ),
          GoRoute(
            path: RouteNames.conversations,
            builder: (_, __) => const PlaceholderScreen('Chat'),
          ),
          GoRoute(
            path: RouteNames.leaveList,
            builder: (_, __) => const PlaceholderScreen('Leave'),
          ),
          GoRoute(
            path: RouteNames.galleryAlbums,
            builder: (_, __) => const PlaceholderScreen('Gallery'),
          ),
          GoRoute(
            path: RouteNames.documents,
            builder: (_, __) => const PlaceholderScreen('Documents'),
          ),
          GoRoute(
            path: RouteNames.auditLogs,
            builder: (_, __) => const AuditLogsScreen(),
          ),
          GoRoute(
            path: RouteNames.complaints,
            builder: (_, __) => const PlaceholderScreen('Complaints'),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(state.error?.toString() ?? 'Navigation error'),
      ),
    ),
  );
});

GoRouter buildAppRouter(ProviderContainer container) {
  return container.read(appRouterProvider);
}
