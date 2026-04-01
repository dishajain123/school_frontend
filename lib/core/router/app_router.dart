import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/auth/screens/splash_screen.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/forgot_password_screen.dart';
import '../../presentation/auth/screens/verify_otp_screen.dart';
import '../../presentation/auth/screens/reset_password_screen.dart';
import '../../presentation/common/shell/main_shell.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/auth/current_user.dart';
import 'route_names.dart';

// ── Placeholder screen ────────────────────────────────────────────────────────

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
                  color: Color(0xFF2D3748)),
            ),
            const SizedBox(height: 8),
            const Text('Coming soon',
                style: TextStyle(fontSize: 13, color: Color(0xFF637082))),
          ],
        ),
      ),
    );
  }
}

// ── Router listenable adapter ─────────────────────────────────────────────────

/// Bridges Riverpod [AuthState] changes into a [Listenable] for GoRouter.
class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(this._ref) {
    _ref.listen<AuthState>(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;

  AuthState get state => _ref.read(authNotifierProvider);
}

// ── Router provider ───────────────────────────────────────────────────────────

final appRouterProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthStateListenable(ref);

  return GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: listenable,

    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // While still initializing, stay on splash
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
      // ── Splash ──────────────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Auth routes ───────────────────────────────────────────────────
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
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

      // ── Authenticated shell ───────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final user = ref.read(authNotifierProvider).currentUser;
          final role = user?.role.backendValue ?? '';
          return MainShell(role: role, child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (context, state) =>
                const PlaceholderScreen('Dashboard'),
          ),

          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) =>
                const PlaceholderScreen('Profile'),
            routes: [
              GoRoute(
                path: 'change-password',
                builder: (context, state) =>
                    const PlaceholderScreen('Change Password',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.notifications,
            builder: (context, state) =>
                const PlaceholderScreen('Notifications', showBack: true),
          ),

          GoRoute(
            path: RouteNames.announcements,
            builder: (context, state) =>
                const PlaceholderScreen('Announcements'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Announcement',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Announcement $id',
                      showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.academicYears,
            builder: (context, state) =>
                const PlaceholderScreen('Academic Years'),
            routes: [
              GoRoute(
                path: 'rollover',
                builder: (context, state) =>
                    const PlaceholderScreen('Rollover', showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.standards,
            builder: (context, state) =>
                const PlaceholderScreen('Standards', showBack: true),
          ),
          GoRoute(
            path: RouteNames.subjects,
            builder: (context, state) =>
                const PlaceholderScreen('Subjects', showBack: true),
          ),
          GoRoute(
            path: RouteNames.gradeMaster,
            builder: (context, state) =>
                const PlaceholderScreen('Grade Master', showBack: true),
          ),

          GoRoute(
            path: RouteNames.teachers,
            builder: (context, state) =>
                const PlaceholderScreen('Teachers'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Teacher',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Teacher $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.students,
            builder: (context, state) =>
                const PlaceholderScreen('Students'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Student',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Student $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.parents,
            builder: (context, state) =>
                const PlaceholderScreen('Parents'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Parent $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.attendance,
            builder: (context, state) =>
                const PlaceholderScreen('Attendance'),
            routes: [
              GoRoute(
                path: 'mark',
                builder: (context, state) =>
                    const PlaceholderScreen('Mark Attendance',
                        showBack: true),
              ),
              GoRoute(
                path: 'snapshot',
                builder: (context, state) =>
                    const PlaceholderScreen('Class Snapshot',
                        showBack: true),
              ),
              GoRoute(
                path: 'below-threshold',
                builder: (context, state) =>
                    const PlaceholderScreen('Below Threshold',
                        showBack: true),
              ),
              GoRoute(
                path: 'analytics/:studentId',
                builder: (context, state) {
                  final sid = state.pathParameters['studentId']!;
                  return PlaceholderScreen('Attendance Analytics $sid',
                      showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.assignments,
            builder: (context, state) =>
                const PlaceholderScreen('Assignments'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Assignment',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Assignment $id',
                      showBack: true);
                },
                routes: [
                  GoRoute(
                    path: 'submissions',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PlaceholderScreen('Submissions for $id',
                          showBack: true);
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.homework,
            builder: (context, state) =>
                const PlaceholderScreen('Homework'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Homework',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.diary,
            builder: (context, state) =>
                const PlaceholderScreen('Diary'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Diary Entry',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.timetable,
            builder: (context, state) =>
                const PlaceholderScreen('Timetable'),
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) =>
                    const PlaceholderScreen('Upload Timetable',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.examSchedules,
            builder: (context, state) =>
                const PlaceholderScreen('Exam Schedules'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Exam Series',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Exam Series $id',
                      showBack: true);
                },
                routes: [
                  GoRoute(
                    path: 'table',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return PlaceholderScreen('Schedule Table $id',
                          showBack: true);
                    },
                  ),
                ],
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.results,
            builder: (context, state) =>
                const PlaceholderScreen('Results'),
            routes: [
              GoRoute(
                path: 'enter',
                builder: (context, state) =>
                    const PlaceholderScreen('Enter Results',
                        showBack: true),
              ),
              GoRoute(
                path: 'report-card/:studentId',
                builder: (context, state) {
                  final sid = state.pathParameters['studentId']!;
                  return PlaceholderScreen('Report Card $sid',
                      showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.feeDashboard,
            builder: (context, state) =>
                const PlaceholderScreen('Fees'),
            routes: [
              GoRoute(
                path: 'payments',
                builder: (context, state) =>
                    const PlaceholderScreen('Payment History',
                        showBack: true),
              ),
              GoRoute(
                path: 'record',
                builder: (context, state) =>
                    const PlaceholderScreen('Record Payment',
                        showBack: true),
              ),
              GoRoute(
                path: 'receipt/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Receipt $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.conversations,
            builder: (context, state) =>
                const PlaceholderScreen('Messages'),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (context, state) {
                  final id = state.pathParameters['conversationId']!;
                  return PlaceholderScreen('Chat $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.leaveList,
            builder: (context, state) =>
                const PlaceholderScreen('Leave'),
            routes: [
              GoRoute(
                path: 'apply',
                builder: (context, state) =>
                    const PlaceholderScreen('Apply Leave', showBack: true),
              ),
              GoRoute(
                path: 'balance',
                builder: (context, state) =>
                    const PlaceholderScreen('Leave Balance',
                        showBack: true),
              ),
              GoRoute(
                path: ':id/decision',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Leave Decision $id',
                      showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.galleryAlbums,
            builder: (context, state) =>
                const PlaceholderScreen('Gallery'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Album', showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Album $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.documents,
            builder: (context, state) =>
                const PlaceholderScreen('Documents'),
            routes: [
              GoRoute(
                path: 'request',
                builder: (context, state) =>
                    const PlaceholderScreen('Request Document',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.behaviourLogs,
            builder: (context, state) =>
                const PlaceholderScreen('Behaviour Logs'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Log Behaviour',
                        showBack: true),
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.complaints,
            builder: (context, state) =>
                const PlaceholderScreen('Complaints'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create Complaint',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('Complaint $id',
                      showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.schools,
            builder: (context, state) =>
                const PlaceholderScreen('Schools'),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) =>
                    const PlaceholderScreen('Create School',
                        showBack: true),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PlaceholderScreen('School $id', showBack: true);
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.schoolSettings,
            builder: (context, state) =>
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
            const Text('404 — Page Not Found',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748))),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF637082)),
                textAlign: TextAlign.center),
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
