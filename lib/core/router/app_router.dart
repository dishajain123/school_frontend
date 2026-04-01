import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/verify_otp_screen.dart';
import '../../presentation/auth/screens/reset_password_screen.dart';
import '../../presentation/common/shell/main_shell.dart';
import 'route_names.dart';

// ── Placeholder screens ───────────────────────────────────────────────────────
// These are replaced by the real implementations in FM05+.
// They must NOT be null so the router can compile and the shell renders.

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen(this.title, {this.showBack = false});
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

// ── Auth state notifier (lightweight) ─────────────────────────────────────────
// FM05 will replace this with the full AuthProvider. This version reads from
// SecureStorage directly so FM04 routing works without FM05.

/// Simple auth state holder used exclusively by the router redirect.
/// FM05 will override this with a full AsyncNotifier.
class _RouterAuthState extends ChangeNotifier {
  bool _isAuthenticated = false;
  String _role = '';

  bool get isAuthenticated => _isAuthenticated;
  String get role => _role;

  void setAuthenticated({required bool value, String role = ''}) {
    _isAuthenticated = value;
    _role = role;
    notifyListeners();
  }
}

/// Notifier that FM05 will override. Provides minimal auth state for routing.
final routerAuthStateProvider =
    ChangeNotifierProvider<_RouterAuthState>((_) => _RouterAuthState());

/// The [GoRouter] instance. Watches [routerAuthStateProvider] so it refreshes
/// when auth state changes. FM05 will hook into this via [refreshListenable].
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(routerAuthStateProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: authState,

    // ── Auth redirect ─────────────────────────────────────────────────────
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      final isOnAuthRoute = location == RouteNames.login ||
          location == RouteNames.forgotPassword ||
          location == RouteNames.verifyOtp ||
          location == RouteNames.resetPassword ||
          location == RouteNames.splash;

      // Not authenticated → always push to login (except auth routes).
      if (!isAuthenticated && !isOnAuthRoute) {
        return RouteNames.login;
      }

      // Authenticated → don't allow staying on auth screens.
      if (isAuthenticated && location == RouteNames.login) {
        return RouteNames.dashboard;
      }

      return null; // No redirect needed.
    },

    routes: [
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth routes (outside shell) ───────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        name: 'verifyOtp',
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
        name: 'resetPassword',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ResetPasswordScreen(
            resetToken: extra?['resetToken'] as String? ?? '',
          );
        },
      ),

      // ── Authenticated shell ───────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final role = authState.role;
          return MainShell(
            role: role,
            child: child,
          );
        },
        routes: [
          // Dashboard
          GoRoute(
            path: RouteNames.dashboard,
            name: 'dashboard',
            builder: (context, state) =>
                const _PlaceholderScreen('Dashboard'),
          ),

          // Profile
          GoRoute(
            path: RouteNames.profile,
            name: 'profile',
            builder: (context, state) =>
                const _PlaceholderScreen('Profile'),
            routes: [
              GoRoute(
                path: 'change-password',
                name: 'changePassword',
                builder: (context, state) =>
                    const _PlaceholderScreen('Change Password',
                        showBack: true),
              ),
            ],
          ),

          // Notifications
          GoRoute(
            path: RouteNames.notifications,
            name: 'notifications',
            builder: (context, state) =>
                const _PlaceholderScreen('Notifications', showBack: true),
          ),

          // Announcements
          GoRoute(
            path: RouteNames.announcements,
            name: 'announcements',
            builder: (context, state) =>
                const _PlaceholderScreen('Announcements'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createAnnouncement',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Announcement',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'announcementDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Announcement $id',
                      showBack: true);
                },
              ),
            ],
          ),

          // Academic Years
          GoRoute(
            path: RouteNames.academicYears,
            name: 'academicYears',
            builder: (context, state) =>
                const _PlaceholderScreen('Academic Years'),
            routes: [
              GoRoute(
                path: 'rollover',
                name: 'rollover',
                builder: (context, state) =>
                    const _PlaceholderScreen('Rollover', showBack: true),
              ),
            ],
          ),

          // Masters
          GoRoute(
            path: RouteNames.standards,
            name: 'standards',
            builder: (context, state) =>
                const _PlaceholderScreen('Standards', showBack: true),
          ),
          GoRoute(
            path: RouteNames.subjects,
            name: 'subjects',
            builder: (context, state) =>
                const _PlaceholderScreen('Subjects', showBack: true),
          ),
          GoRoute(
            path: RouteNames.gradeMaster,
            name: 'gradeMaster',
            builder: (context, state) =>
                const _PlaceholderScreen('Grade Master', showBack: true),
          ),

          // Teachers
          GoRoute(
            path: RouteNames.teachers,
            name: 'teachers',
            builder: (context, state) =>
                const _PlaceholderScreen('Teachers'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createTeacher',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Teacher',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'teacherDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Teacher $id', showBack: true);
                },
              ),
            ],
          ),

          // Students
          GoRoute(
            path: RouteNames.students,
            name: 'students',
            builder: (context, state) =>
                const _PlaceholderScreen('Students'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createStudent',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Student',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'studentDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Student $id', showBack: true);
                },
              ),
            ],
          ),

          // Parents
          GoRoute(
            path: RouteNames.parents,
            name: 'parents',
            builder: (context, state) =>
                const _PlaceholderScreen('Parents'),
            routes: [
              GoRoute(
                path: ':id',
                name: 'parentDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Parent $id', showBack: true);
                },
              ),
            ],
          ),

          // Attendance
          GoRoute(
            path: RouteNames.attendance,
            name: 'attendance',
            builder: (context, state) =>
                const _PlaceholderScreen('Attendance'),
            routes: [
              GoRoute(
                path: 'mark',
                name: 'markAttendance',
                builder: (context, state) =>
                    const _PlaceholderScreen('Mark Attendance',
                        showBack: true),
              ),
              GoRoute(
                path: 'snapshot',
                name: 'classSnapshot',
                builder: (context, state) =>
                    const _PlaceholderScreen('Class Snapshot',
                        showBack: true),
              ),
              GoRoute(
                path: 'below-threshold',
                name: 'belowThreshold',
                builder: (context, state) =>
                    const _PlaceholderScreen('Below Threshold',
                        showBack: true),
              ),
              GoRoute(
                path: 'analytics/:studentId',
                name: 'attendanceAnalytics',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  return _PlaceholderScreen(
                      'Attendance Analytics $studentId',
                      showBack: true);
                },
              ),
            ],
          ),

          // Assignments
          GoRoute(
            path: RouteNames.assignments,
            name: 'assignments',
            builder: (context, state) =>
                const _PlaceholderScreen('Assignments'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createAssignment',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Assignment',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'assignmentDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Assignment $id',
                      showBack: true);
                },
                routes: [
                  GoRoute(
                    path: 'submissions',
                    name: 'submissionList',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _PlaceholderScreen(
                          'Submissions for $id',
                          showBack: true);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Homework
          GoRoute(
            path: RouteNames.homework,
            name: 'homework',
            builder: (context, state) =>
                const _PlaceholderScreen('Homework'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createHomework',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Homework',
                        showBack: true),
              ),
            ],
          ),

          // Diary
          GoRoute(
            path: RouteNames.diary,
            name: 'diary',
            builder: (context, state) => const _PlaceholderScreen('Diary'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createDiary',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Diary Entry',
                        showBack: true),
              ),
            ],
          ),

          // Timetable
          GoRoute(
            path: RouteNames.timetable,
            name: 'timetable',
            builder: (context, state) =>
                const _PlaceholderScreen('Timetable'),
            routes: [
              GoRoute(
                path: 'upload',
                name: 'uploadTimetable',
                builder: (context, state) =>
                    const _PlaceholderScreen('Upload Timetable',
                        showBack: true),
              ),
            ],
          ),

          // Exam Schedule
          GoRoute(
            path: RouteNames.examSchedules,
            name: 'examSchedules',
            builder: (context, state) =>
                const _PlaceholderScreen('Exam Schedules'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createExamSeries',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Exam Series',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'examScheduleDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Exam Series $id',
                      showBack: true);
                },
                routes: [
                  GoRoute(
                    path: 'table',
                    name: 'examScheduleTable',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return _PlaceholderScreen('Schedule Table $id',
                          showBack: true);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Results
          GoRoute(
            path: RouteNames.results,
            name: 'results',
            builder: (context, state) =>
                const _PlaceholderScreen('Results'),
            routes: [
              GoRoute(
                path: 'enter',
                name: 'enterResults',
                builder: (context, state) =>
                    const _PlaceholderScreen('Enter Results',
                        showBack: true),
              ),
              GoRoute(
                path: 'report-card/:studentId',
                name: 'reportCard',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId']!;
                  return _PlaceholderScreen('Report Card $studentId',
                      showBack: true);
                },
              ),
            ],
          ),

          // Fees
          GoRoute(
            path: RouteNames.feeDashboard,
            name: 'feeDashboard',
            builder: (context, state) =>
                const _PlaceholderScreen('Fees'),
            routes: [
              GoRoute(
                path: 'payments',
                name: 'paymentHistory',
                builder: (context, state) =>
                    const _PlaceholderScreen('Payment History',
                        showBack: true),
              ),
              GoRoute(
                path: 'record',
                name: 'recordPayment',
                builder: (context, state) =>
                    const _PlaceholderScreen('Record Payment',
                        showBack: true),
              ),
              GoRoute(
                path: 'receipt/:id',
                name: 'receipt',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Receipt $id', showBack: true);
                },
              ),
            ],
          ),

          // Chat
          GoRoute(
            path: RouteNames.conversations,
            name: 'conversations',
            builder: (context, state) =>
                const _PlaceholderScreen('Messages'),
            routes: [
              GoRoute(
                path: ':conversationId',
                name: 'chatRoom',
                // Chat room is full-screen, but stays in shell for nav bar.
                builder: (context, state) {
                  final id = state.pathParameters['conversationId']!;
                  return _PlaceholderScreen('Chat $id', showBack: true);
                },
              ),
            ],
          ),

          // Leave
          GoRoute(
            path: RouteNames.leaveList,
            name: 'leaveList',
            builder: (context, state) =>
                const _PlaceholderScreen('Leave'),
            routes: [
              GoRoute(
                path: 'apply',
                name: 'applyLeave',
                builder: (context, state) =>
                    const _PlaceholderScreen('Apply Leave', showBack: true),
              ),
              GoRoute(
                path: 'balance',
                name: 'leaveBalance',
                builder: (context, state) =>
                    const _PlaceholderScreen('Leave Balance',
                        showBack: true),
              ),
              GoRoute(
                path: ':id/decision',
                name: 'leaveDecision',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Leave Decision $id',
                      showBack: true);
                },
              ),
            ],
          ),

          // Gallery
          GoRoute(
            path: RouteNames.galleryAlbums,
            name: 'galleryAlbums',
            builder: (context, state) =>
                const _PlaceholderScreen('Gallery'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createAlbum',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Album', showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'albumDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Album $id', showBack: true);
                },
              ),
            ],
          ),

          // Documents
          GoRoute(
            path: RouteNames.documents,
            name: 'documents',
            builder: (context, state) =>
                const _PlaceholderScreen('Documents'),
            routes: [
              GoRoute(
                path: 'request',
                name: 'requestDocument',
                builder: (context, state) =>
                    const _PlaceholderScreen('Request Document',
                        showBack: true),
              ),
            ],
          ),

          // Behaviour
          GoRoute(
            path: RouteNames.behaviourLogs,
            name: 'behaviourLogs',
            builder: (context, state) =>
                const _PlaceholderScreen('Behaviour Logs'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createBehaviourLog',
                builder: (context, state) =>
                    const _PlaceholderScreen('Log Behaviour',
                        showBack: true),
              ),
            ],
          ),

          // Complaints
          GoRoute(
            path: RouteNames.complaints,
            name: 'complaints',
            builder: (context, state) =>
                const _PlaceholderScreen('Complaints'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createComplaint',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create Complaint',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'complaintDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('Complaint $id',
                      showBack: true);
                },
              ),
            ],
          ),

          // Superadmin — Schools
          GoRoute(
            path: RouteNames.schools,
            name: 'schools',
            builder: (context, state) =>
                const _PlaceholderScreen('Schools'),
            routes: [
              GoRoute(
                path: 'create',
                name: 'createSchool',
                builder: (context, state) =>
                    const _PlaceholderScreen('Create School',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                name: 'schoolDetail',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _PlaceholderScreen('School $id', showBack: true);
                },
              ),
            ],
          ),

          // School Settings
          GoRoute(
            path: RouteNames.schoolSettings,
            name: 'schoolSettings',
            builder: (context, state) =>
                const _PlaceholderScreen('Settings'),
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
                fontSize: 13,
                color: Color(0xFF637082),
              ),
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