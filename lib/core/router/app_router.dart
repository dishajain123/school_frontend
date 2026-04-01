import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/verify_otp_screen.dart';
import '../../presentation/auth/screens/reset_password_screen.dart';
import '../../presentation/common/shell/main_shell.dart';
import '../../presentation/dashboard/screens/dashboard_screen.dart';
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
import '../../data/models/announcement/announcement_model.dart';
import '../../data/models/teacher/teacher_model.dart';
import '../../data/models/student/student_model.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/auth/current_user.dart';
import 'route_names.dart';

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen(this.title, {this.showBack = false, super.key});
  final String title;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        title: Text(title),
        automaticallyImplyLeading: showBack,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 48, color: Color(0xFF9BA5B4)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming soon',
              style: TextStyle(fontSize: 13, color: Color(0xFF637082)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  AuthState get state => _ref.read(authNotifierProvider);
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,

    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (location == RouteNames.splash) return null;
        return RouteNames.splash;
      }

      final isAuthenticated = authState.isAuthenticated;
      final isOnAuthRoute = location == RouteNames.login ||
          location == RouteNames.forgotPassword ||
          location.startsWith('/verify-otp') ||
          location.startsWith('/reset-password') ||
          location == RouteNames.splash;

      if (!isAuthenticated && !isOnAuthRoute) return RouteNames.login;
      if (isAuthenticated && location == RouteNames.splash) {
        return RouteNames.dashboard;
      }
      if (isAuthenticated && location == RouteNames.login) {
        return RouteNames.dashboard;
      }
      return null;
    },

    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginScreen(),
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
          return ResetPasswordScreen(
            resetToken: extra?['resetToken'] as String? ?? '',
          );
        },
      ),

      ShellRoute(
        builder: (context, state, child) {
          final user = ref.read(authNotifierProvider).currentUser;
          final role = user?.role.backendValue ?? '';
          return MainShell(role: role, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),

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

          // ── Notifications ──────────────────────────────────────────────
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
                  if (announcement == null) {
                    return const PlaceholderScreen('Announcement',
                        showBack: true);
                  }
                  return AnnouncementDetailScreen(
                      announcement: announcement);
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
                ],
              ),
            ],
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

          // ── Parents ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.parents,
            builder: (_, __) =>
                const PlaceholderScreen('Parents'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => PlaceholderScreen(
                    'Parent ${state.pathParameters['id']}',
                    showBack: true),
              ),
            ],
          ),

          // ── Attendance ─────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.attendance,
            builder: (_, __) =>
                const PlaceholderScreen('Attendance'),
            routes: [
              GoRoute(
                path: 'mark',
                builder: (_, __) => const PlaceholderScreen(
                    'Mark Attendance',
                    showBack: true),
              ),
              GoRoute(
                path: 'snapshot',
                builder: (_, __) => const PlaceholderScreen(
                    'Class Snapshot',
                    showBack: true),
              ),
              GoRoute(
                path: 'below-threshold',
                builder: (_, __) => const PlaceholderScreen(
                    'Below Threshold',
                    showBack: true),
              ),
              GoRoute(
                path: 'analytics/:studentId',
                builder: (context, state) => const PlaceholderScreen(
                    'Attendance Analytics',
                    showBack: true),
              ),
            ],
          ),

          // ── Assignments ────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.assignments,
            builder: (_, __) =>
                const PlaceholderScreen('Assignments'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Assignment',
                    showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PlaceholderScreen(
                    'Assignment ${state.pathParameters['id']}',
                    showBack: true),
                routes: [
                  GoRoute(
                    path: 'submissions',
                    builder: (context, state) => const PlaceholderScreen(
                        'Submissions',
                        showBack: true),
                  ),
                ],
              ),
            ],
          ),

          // ── Homework ───────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.homework,
            builder: (_, __) =>
                const PlaceholderScreen('Homework'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Homework',
                    showBack: true),
              ),
            ],
          ),

          // ── Diary ──────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.diary,
            builder: (_, __) => const PlaceholderScreen('Diary'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Diary Entry',
                    showBack: true),
              ),
            ],
          ),

          // ── Timetable ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.timetable,
            builder: (_, __) =>
                const PlaceholderScreen('Timetable'),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (_, __) => const PlaceholderScreen(
                    'Upload Timetable',
                    showBack: true),
              ),
            ],
          ),

          // ── Exam Schedule ──────────────────────────────────────────────
          GoRoute(
            path: RouteNames.examSchedules,
            builder: (_, __) =>
                const PlaceholderScreen('Exam Schedules'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Exam Series',
                    showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => PlaceholderScreen(
                    'Exam Series ${state.pathParameters['id']}',
                    showBack: true),
                routes: [
                  GoRoute(
                    path: 'table',
                    builder: (context, state) => const PlaceholderScreen(
                        'Schedule Table',
                        showBack: true),
                  ),
                ],
              ),
            ],
          ),

          // ── Results ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.results,
            builder: (_, __) =>
                const PlaceholderScreen('Results'),
            routes: [
              GoRoute(
                path: 'enter',
                builder: (_, __) => const PlaceholderScreen(
                    'Enter Results',
                    showBack: true),
              ),
              GoRoute(
                path: 'report-card/:studentId',
                builder: (context, state) =>
                    const PlaceholderScreen('Report Card',
                        showBack: true),
              ),
            ],
          ),

          // ── Fees ───────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.feeDashboard,
            builder: (_, __) => const PlaceholderScreen('Fees'),
            routes: [
              GoRoute(
                path: 'payments',
                builder: (_, __) => const PlaceholderScreen(
                    'Payment History',
                    showBack: true),
              ),
              GoRoute(
                path: 'record',
                builder: (_, __) => const PlaceholderScreen(
                    'Record Payment',
                    showBack: true),
              ),
              GoRoute(
                path: 'receipt/:id',
                builder: (context, state) => PlaceholderScreen(
                    'Receipt ${state.pathParameters['id']}',
                    showBack: true),
              ),
            ],
          ),

          // ── Chat ───────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.conversations,
            builder: (_, __) =>
                const PlaceholderScreen('Messages'),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (context, state) =>
                    const PlaceholderScreen('Chat', showBack: true),
              ),
            ],
          ),

          // ── Leave ──────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.leaveList,
            builder: (_, __) => const PlaceholderScreen('Leave'),
            routes: [
              GoRoute(
                path: 'apply',
                builder: (_, __) => const PlaceholderScreen(
                    'Apply Leave',
                    showBack: true),
              ),
              GoRoute(
                path: 'balance',
                builder: (_, __) => const PlaceholderScreen(
                    'Leave Balance',
                    showBack: true),
              ),
              GoRoute(
                path: ':id/decision',
                builder: (context, state) =>
                    const PlaceholderScreen('Leave Decision',
                        showBack: true),
              ),
            ],
          ),

          // ── Gallery ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.galleryAlbums,
            builder: (_, __) =>
                const PlaceholderScreen('Gallery'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Album',
                    showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    const PlaceholderScreen('Album', showBack: true),
              ),
            ],
          ),

          // ── Documents ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.documents,
            builder: (_, __) =>
                const PlaceholderScreen('Documents'),
            routes: [
              GoRoute(
                path: 'request',
                builder: (_, __) => const PlaceholderScreen(
                    'Request Document',
                    showBack: true),
              ),
            ],
          ),

          // ── Behaviour ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.behaviourLogs,
            builder: (_, __) =>
                const PlaceholderScreen('Behaviour Logs'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Log Behaviour',
                    showBack: true),
              ),
            ],
          ),

          // ── Complaints ─────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.complaints,
            builder: (_, __) =>
                const PlaceholderScreen('Complaints'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create Complaint',
                    showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    const PlaceholderScreen('Complaint',
                        showBack: true),
              ),
            ],
          ),

          // ── Schools (Superadmin) ───────────────────────────────────────
          GoRoute(
            path: RouteNames.schools,
            builder: (_, __) =>
                const PlaceholderScreen('Schools'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const PlaceholderScreen(
                    'Create School',
                    showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    const PlaceholderScreen('School',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.schoolSettings,
            builder: (_, __) =>
                const PlaceholderScreen('Settings'),
          ),
        ],
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1F3A),
        foregroundColor: Colors.white,
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Color(0xFFEF4444)),
            const SizedBox(height: 16),
            const Text(
              '404 — Page Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF637082)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.dashboard),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});