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
import '../../presentation/parents/screens/parent_list_screen.dart';
import '../../presentation/parents/screens/parent_detail_screen.dart';
import '../../presentation/parents/screens/create_parent_screen.dart';
import '../../presentation/attendance/screens/attendance_list_screen.dart';
import '../../presentation/attendance/screens/mark_attendance_screen.dart';
import '../../presentation/attendance/screens/class_snapshot_screen.dart';
import '../../presentation/attendance/screens/below_threshold_screen.dart';
import '../../presentation/attendance/screens/attendance_analytics_screen.dart';
import '../../presentation/assignments/screens/assignment_list_screen.dart';
import '../../presentation/assignments/screens/create_assignment_screen.dart';
import '../../presentation/assignments/screens/assignment_detail_screen.dart';
import '../../presentation/assignments/screens/submission_list_screen.dart';
import '../../presentation/homework/screens/homework_list_screen.dart';
import '../../presentation/homework/screens/create_homework_screen.dart';
import '../../presentation/diary/screens/diary_list_screen.dart';
import '../../presentation/diary/screens/create_diary_screen.dart';
import '../../presentation/timetable/screens/timetable_view_screen.dart';
import '../../presentation/timetable/screens/upload_timetable_screen.dart';
import '../../presentation/exam_schedule/screens/exam_schedule_list_screen.dart';
import '../../presentation/exam_schedule/screens/create_series_screen.dart';
import '../../presentation/exam_schedule/screens/exam_schedule_table_screen.dart';
import '../../presentation/results/screens/result_list_screen.dart';
import '../../presentation/results/screens/enter_results_screen.dart';
import '../../presentation/results/screens/report_card_screen.dart';
import '../../presentation/results/screens/principal_results_distribution_screen.dart';
import '../../presentation/reports/screens/principal_report_details_screen.dart';
import '../../presentation/documents/screens/document_list_screen.dart';
import '../../presentation/documents/screens/request_document_screen.dart';
import '../../presentation/fees/screens/fee_dashboard_screen.dart';
import '../../presentation/fees/screens/payment_history_screen.dart';
import '../../presentation/fees/screens/record_payment_screen.dart';
import '../../presentation/fees/screens/receipt_screen.dart';
// FM23 — Chat
import '../../presentation/chat/screens/conversation_list_screen.dart';
import '../../presentation/chat/screens/chat_screen.dart';
// FM24 — Teacher Leave
import '../../presentation/leave/screens/leave_list_screen.dart';
import '../../presentation/leave/screens/apply_leave_screen.dart';
import '../../presentation/leave/screens/leave_balance_screen.dart';
import '../../presentation/leave/screens/leave_decision_screen.dart';
import '../../presentation/gallery/screens/album_list_screen.dart';
import '../../presentation/gallery/screens/create_album_screen.dart';
import '../../presentation/gallery/screens/album_detail_screen.dart';
import '../../presentation/behaviour/screens/behaviour_log_list_screen.dart';
import '../../presentation/behaviour/screens/create_behaviour_log_screen.dart';
import '../../presentation/superadmin/screens/schools_list_screen.dart';
import '../../presentation/superadmin/screens/create_school_screen.dart';
import '../../presentation/superadmin/screens/school_detail_screen.dart';
import '../../presentation/settings/screens/school_settings_screen.dart';
import '../../presentation/complaints/screens/complaint_list_screen.dart';
import '../../presentation/complaints/screens/create_complaint_screen.dart';
import '../../presentation/complaints/screens/complaint_detail_screen.dart';
import '../../data/models/announcement/announcement_model.dart';
import '../../data/models/chat/conversation_model.dart';
import '../../data/models/leave/leave_model.dart';
import '../../data/models/gallery/album_model.dart';
import '../../data/models/complaint/complaint_model.dart';
import '../../data/models/school/school_model.dart';
import '../../data/models/teacher/teacher_model.dart';
import '../../data/models/student/student_model.dart';
import '../../data/models/parent/parent_model.dart';
import '../../data/models/auth/current_user.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
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
              style: AppTypography.titleLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.grey600,
              ),
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

      // Splash must never be terminal: once init is complete, route onward.
      if (!isAuthenticated && location == RouteNames.splash) {
        return RouteNames.login;
      }

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
                  return AnnouncementDetailScreen(announcement: announcement);
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
            builder: (context, state) {
              final studentId = state.uri.queryParameters['student_id'];
              if (studentId != null && studentId.isNotEmpty) {
                return AttendanceListScreen(studentId: studentId);
              }

              final user = ref.read(currentUserProvider);
              final role = user?.role;

              if (role == UserRole.teacher) {
                return const MarkAttendanceScreen();
              }

              if (role == UserRole.principal ||
                  role == UserRole.trustee ||
                  role == UserRole.superadmin) {
                return const ClassSnapshotScreen();
              }

              return AttendanceListScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: 'mark',
                builder: (_, __) => const MarkAttendanceScreen(),
              ),
              GoRoute(
                path: 'snapshot',
                builder: (_, __) => const ClassSnapshotScreen(),
              ),
              GoRoute(
                path: 'below-threshold',
                builder: (_, __) => const BelowThresholdScreen(),
              ),
              GoRoute(
                path: 'analytics/:studentId',
                builder: (context, state) {
                  final studentId = state.pathParameters['studentId'];
                  return AttendanceAnalyticsScreen(studentId: studentId);
                },
              ),
            ],
          ),

          // ── Assignments ────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.assignments,
            builder: (_, __) => const AssignmentListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final extra = state.extra;
                  final editId = extra is Map<String, dynamic>
                      ? extra['editId'] as String?
                      : null;
                  return CreateAssignmentScreen(editAssignmentId: editId);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => AssignmentDetailScreen(
                  assignmentId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => CreateAssignmentScreen(
                      editAssignmentId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'submissions',
                    builder: (context, state) => SubmissionListScreen(
                      assignmentId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Homework ───────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.homework,
            builder: (_, __) => const HomeworkListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateHomeworkScreen(),
              ),
            ],
          ),

          // ── Diary ──────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.diary,
            builder: (_, __) => const DiaryListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateDiaryScreen(),
              ),
            ],
          ),

          // ── Timetable ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.timetable,
            builder: (context, state) {
              final standardId = state.uri.queryParameters['standard_id'];
              final section = state.uri.queryParameters['section'];
              return TimetableViewScreen(
                standardId: (standardId == null || standardId.isEmpty)
                    ? null
                    : standardId,
                section: (section == null || section.trim().isEmpty)
                    ? null
                    : section,
              );
            },
            routes: [
              GoRoute(
                path: 'upload',
                builder: (context, state) => UploadTimetableScreen(
                  initialStandardId: state.uri.queryParameters['standard_id'],
                  initialSection: state.uri.queryParameters['section'],
                ),
              ),
            ],
          ),

          // ── Exam Schedule ──────────────────────────────────────────────
          GoRoute(
            path: RouteNames.examSchedules,
            builder: (_, __) => const ExamScheduleListScreen(),
            routes: [
              GoRoute(
                path: "create",
                builder: (context, state) {
                  final extra = state.extra;
                  final standardIdFromExtra = extra is Map<String, dynamic>
                      ? extra["standard_id"] as String?
                      : null;
                  final standardId = state.uri.queryParameters["standard_id"] ??
                      standardIdFromExtra;
                  if (standardId == null || standardId.isEmpty) {
                    return const PlaceholderScreen("Select Class First",
                        showBack: true);
                  }
                  return CreateSeriesScreen(standardId: standardId);
                },
              ),
              GoRoute(
                path: "table",
                builder: (context, state) {
                  final extra = state.extra;
                  final standardIdFromExtra = extra is Map<String, dynamic>
                      ? extra["standard_id"] as String?
                      : null;
                  final standardId = state.uri.queryParameters["standard_id"] ??
                      standardIdFromExtra;
                  if (standardId == null || standardId.isEmpty) {
                    return const PlaceholderScreen("Select Class First",
                        showBack: true);
                  }
                  return ExamScheduleTableScreen(
                    standardId: standardId,
                    seriesId: null,
                  );
                },
              ),
              GoRoute(
                path: ":id/table",
                builder: (context, state) {
                  final extra = state.extra;
                  final standardIdFromExtra = extra is Map<String, dynamic>
                      ? extra["standard_id"] as String?
                      : null;
                  final standardId = state.uri.queryParameters["standard_id"] ??
                      standardIdFromExtra;
                  if (standardId == null || standardId.isEmpty) {
                    return const PlaceholderScreen("Select Class First",
                        showBack: true);
                  }
                  return ExamScheduleTableScreen(
                    standardId: standardId,
                    seriesId: state.pathParameters["id"]!,
                  );
                },
              ),
            ],
          ),

          // ── Results ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.results,
            builder: (context, state) {
              final studentId = state.uri.queryParameters["student_id"];
              return ResultListScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: "enter",
                builder: (context, state) => EnterResultsScreen(
                  examId: state.uri.queryParameters["exam_id"],
                  standardId: state.uri.queryParameters["standard_id"],
                  section: state.uri.queryParameters["section"],
                ),
              ),
              GoRoute(
                path: "report-card",
                builder: (context, state) {
                  final extra = state.extra;
                  final extraMap = extra is Map<String, dynamic> ? extra : null;
                  final studentId = extraMap?["studentId"] as String? ??
                      state.uri.queryParameters["student_id"];
                  final examId = extraMap?["examId"] as String? ??
                      state.uri.queryParameters["exam_id"];

                  if (studentId == null || examId == null) {
                    return const PlaceholderScreen("Report Card",
                        showBack: true);
                  }

                  return ReportCardScreen(studentId: studentId, examId: examId);
                },
              ),
              GoRoute(
                path: "report-card/:studentId",
                builder: (context, state) {
                  final extra = state.extra;
                  final extraMap = extra is Map<String, dynamic> ? extra : null;
                  final studentId = state.pathParameters["studentId"] ??
                      extraMap?["studentId"] as String?;
                  final examId = extraMap?["examId"] as String? ??
                      state.uri.queryParameters["exam_id"];

                  if (studentId == null || examId == null) {
                    return const PlaceholderScreen("Report Card",
                        showBack: true);
                  }

                  return ReportCardScreen(studentId: studentId, examId: examId);
                },
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.principalResultsDistribution,
            builder: (_, __) => const PrincipalResultsDistributionScreen(),
          ),
          GoRoute(
            path: RouteNames.principalReportDetails,
            builder: (context, state) {
              final metric =
                  state.uri.queryParameters['metric'] ?? 'student_attendance';
              return PrincipalReportDetailsScreen(initialMetric: metric);
            },
          ),

          // ── Fees ───────────────────────────────────────────────────────
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
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return PaymentHistoryScreen.fromExtras(extra);
            },
          ),
          GoRoute(
            path: RouteNames.recordPayment,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return RecordPaymentScreen.fromExtras(extra);
            },
          ),
          GoRoute(
            path: RouteNames.feeReceipt,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ReceiptScreen.fromExtras(extra);
            },
          ),

          // ── Chat (FM23) ────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.conversations,
            builder: (_, __) => const ConversationListScreen(),
            routes: [
              GoRoute(
                path: ':conversationId',
                builder: (context, state) {
                  final conversationId =
                      state.pathParameters['conversationId']!;
                  final conversation = state.extra as ConversationModel?;
                  return ChatScreen(
                    conversationId: conversationId,
                    conversation: conversation,
                  );
                },
              ),
            ],
          ),

          // ── Leave (FM24) ───────────────────────────────────────────────
          GoRoute(
            path: RouteNames.leaveList,
            builder: (_, __) => const LeaveListScreen(),
            routes: [
              GoRoute(
                path: 'apply',
                builder: (_, __) => const ApplyLeaveScreen(),
              ),
              GoRoute(
                path: 'balance',
                builder: (_, __) => const LeaveBalanceScreen(),
              ),
              GoRoute(
                path: ':id/decision',
                builder: (context, state) {
                  final leaveId = state.pathParameters['id']!;
                  final leave = state.extra as LeaveModel?;
                  return LeaveDecisionScreen(
                    leaveId: leaveId,
                    leave: leave,
                  );
                },
              ),
            ],
          ),

          // ── Gallery ────────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.galleryAlbums,
            builder: (_, __) => const AlbumListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) => const CreateAlbumScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final album = state.extra as AlbumModel?;
                  return AlbumDetailScreen(
                    albumId: state.pathParameters['id']!,
                    initialAlbum: album,
                  );
                },
              ),
            ],
          ),

          // ── Documents ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.documents,
            builder: (context, state) {
              final studentId = state.uri.queryParameters["student_id"];
              return DocumentListScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: "request",
                builder: (context, state) {
                  final extra = state.extra;
                  final studentId = extra is Map<String, dynamic>
                      ? extra["studentId"] as String?
                      : state.uri.queryParameters["student_id"];
                  if (studentId == null || studentId.isEmpty) {
                    return const PlaceholderScreen("Request Document",
                        showBack: true);
                  }
                  return RequestDocumentScreen(studentId: studentId);
                },
              ),
            ],
          ),

          // ── Behaviour ──────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.behaviourLogs,
            builder: (context, state) {
              final studentId = state.uri.queryParameters['student_id'];
              return BehaviourLogListScreen(studentId: studentId);
            },
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final studentId = state.uri.queryParameters['student_id'];
                  return CreateBehaviourLogScreen(initialStudentId: studentId);
                },
              ),
            ],
          ),

          // ── Complaints ─────────────────────────────────────────────────
          GoRoute(
            path: RouteNames.complaints,
            builder: (_, __) => const ComplaintListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (_, __) {
                  final user = ref.read(authNotifierProvider).currentUser;
                  if (user?.role == UserRole.principal) {
                    return const PlaceholderScreen(
                      'Principal Cannot Raise Complaint',
                      showBack: true,
                    );
                  }
                  return const CreateComplaintScreen();
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final complaint = state.extra as ComplaintModel?;
                  return ComplaintDetailScreen(
                    complaintId: state.pathParameters['id']!,
                    initialComplaint: complaint,
                  );
                },
              ),
            ],
          ),

          // ── Schools (Superadmin) ───────────────────────────────────────
          GoRoute(
            path: RouteNames.schools,
            builder: (_, __) => const SchoolsListScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) {
                  final existing = state.extra as SchoolModel?;
                  return CreateSchoolScreen(existingSchool: existing);
                },
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final school = state.extra as SchoolModel?;
                  return SchoolDetailScreen(
                    schoolId: state.pathParameters['id']!,
                    initialSchool: school,
                  );
                },
              ),
            ],
          ),

          GoRoute(
            path: RouteNames.schoolSettings,
            builder: (_, __) => const SchoolSettingsScreen(),
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
            Text(
              '404 — Page Not Found',
              style: AppTypography.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error?.toString() ?? 'Unknown error',
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                color: AppColors.grey600,
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
