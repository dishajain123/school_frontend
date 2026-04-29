import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // ── Base ─────────────────────────────────────────────────────────────────
  static const String androidBaseUrl =
      'http://10.0.2.2:8000'; // Android emulator
  static const String localBaseUrl =
      'http://localhost:8000'; // iOS sim / desktop
  static const String apiPrefix = '/api/v1';
  static const String apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static const String wsBaseUrlEnv = String.fromEnvironment('WS_BASE_URL');

  static String get webBaseUrl {
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    final safeHost = (host == '0.0.0.0' || host == '::') ? 'localhost' : host;
    return 'http://$safeHost:8000';
  }

  static String get resolvedBaseUrl {
    if (apiBaseUrlEnv.isNotEmpty) {
      return _applyPlatformHostFix(_normalizeBaseUrl(apiBaseUrlEnv));
    }
    if (kIsWeb) return webBaseUrl;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _applyPlatformHostFix(androidBaseUrl);
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _applyPlatformHostFix(localBaseUrl);
    }
  }

  static String get resolvedWsBaseUrl {
    if (wsBaseUrlEnv.isNotEmpty) return _normalizeBaseUrl(wsBaseUrlEnv);
    return _httpToWsBaseUrl(resolvedBaseUrl);
  }

  // ── Connect / Receive timeouts ────────────────────────────────────────────
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot-password';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resetPassword = '/auth/reset-password';
  static const String authMe = '/auth/me';

  // ── Users ─────────────────────────────────────────────────────────────────
  static const String users = '/users';
  static const String usersMe = '/users/me';
  static String userById(String id) => '/users/$id';
  static String userDeactivate(String id) => '/users/$id/deactivate';
  static String userPhoto(String id) => '/users/$id/photo';

  // ── Schools ───────────────────────────────────────────────────────────────
  static const String schools = '/schools';
  static String schoolById(String id) => '/schools/$id';
  static String schoolDeactivate(String id) => '/schools/$id/deactivate';

  // ── School Settings ───────────────────────────────────────────────────────
  static const String settings = '/settings';

  // ── Academic Years ────────────────────────────────────────────────────────
  static const String academicYears = '/academic-years';
  static String academicYearById(String id) => '/academic-years/$id';
  static String academicYearActivate(String id) =>
      '/academic-years/$id/activate';
  static String academicYearRollover(String id) =>
      '/academic-years/$id/rollover';

  // ── Masters ───────────────────────────────────────────────────────────────
  static const String standards = '/masters/standards';
  static String standardById(String id) => '/masters/standards/$id';
  static const String subjects = '/masters/subjects';
  static String subjectById(String id) => '/masters/subjects/$id';
  static const String grades = '/masters/grades';
  static String gradeById(String id) => '/masters/grades/$id';
  static const String gradesLookup = '/masters/grades/lookup';

  // ── Teacher Assignments ───────────────────────────────────────────────────
  static const String teacherAssignments = '/teacher-assignments';
  static String teacherAssignmentById(String id) => '/teacher-assignments/$id';

  // ── Teachers ──────────────────────────────────────────────────────────────
  static const String teachers = '/teachers';
  static String teacherById(String id) => '/teachers/$id';

  // ── Students ──────────────────────────────────────────────────────────────
  static const String students = '/students';
  static const String studentsMe = '/students/me';
  static const String studentSections = '/students/sections';
  static String studentById(String id) => '/students/$id';
  static String studentPromotionStatus(String id) =>
      '/students/$id/promotion-status';
  static const String studentBulkPromotionStatus =
      '/students/promotion-status/bulk';
  static const String studentSectionPromotionStatus =
      '/students/promotion-status/section';

  // ── Parents ───────────────────────────────────────────────────────────────
  static const String parents = '/parents';
  static String parentById(String id) => '/parents/$id';
  static const String myChildren = '/parents/me/children';
  static const String myChildrenLink = '/parents/me/children/link';
  static String parentChildren(String id) => '/parents/$id/children';

  // ── Attendance ────────────────────────────────────────────────────────────
  static const String attendance = '/attendance';
  static const String attendanceLecture = '/attendance/lecture';
  static String attendanceStudentDetail(String studentId) =>
      '/attendance/student/$studentId';
  static String attendanceStudentAnalytics(String studentId) =>
      '/attendance/analytics/student/$studentId';
  static const String attendanceBelowThreshold =
      '/attendance/analytics/below-threshold';
  static const String attendanceDashboardAnalytics =
      '/attendance/analytics/dashboard';

  // ── Assignments ───────────────────────────────────────────────────────────
  static const String assignments = '/assignments';
  static String assignmentById(String id) => '/assignments/$id';

  // ── Submissions ───────────────────────────────────────────────────────────
  static const String submissions = '/submissions';
  static String submissionGrade(String id) => '/submissions/$id/grade';

  // ── Homework ──────────────────────────────────────────────────────────────
  static const String homework = '/homework';

  // ── Diary ─────────────────────────────────────────────────────────────────
  static const String diary = '/diary';

  // ── Timetable ─────────────────────────────────────────────────────────────
  static const String timetable = '/timetable';
  static String timetableByStandard(String standardId) =>
      '/timetable/$standardId';
  static String timetableSections(String standardId) =>
      '/timetable/$standardId/sections';

  // ── Exam Schedule ─────────────────────────────────────────────────────────
  static const String examSchedule = '/exam-schedule';
  static String examScheduleById(String id) => '/exam-schedule/$id';
  static String examScheduleEntries(String seriesId) =>
      '/exam-schedule/$seriesId/entries';
  static String examSchedulePublish(String seriesId) =>
      '/exam-schedule/$seriesId/publish';
  static String examScheduleEntryCancel(String entryId) =>
      '/exam-schedule/entries/$entryId/cancel';

  // ── Results ───────────────────────────────────────────────────────────────
  static const String resultsExams = '/results/exams';
  static const String resultsEntries = '/results/entries';
  static const String results = '/results';
  static String resultsExamPublish(String examId) =>
      '/results/exams/$examId/publish';
  static String reportCard(String studentId) =>
      '/results/report-card/$studentId';
  static const String reportCardUpload = '/results/report-card/upload';

  // ── Fees ──────────────────────────────────────────────────────────────────
  static const String feeStructures = '/fees/structures/batch';
  static const String feeLedgerGenerate = '/fees/ledger/generate';
  static const String feePayments = '/fees/payments';
  static const String feeDashboard = '/fees';
  static String feePaymentReceipt(String paymentId) =>
      '/fees/payments/$paymentId/receipt';
  static String feeReceiptUrl(String paymentId) =>
      '/fees/payments/$paymentId/receipt';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsMarkRead = '/notifications/mark-read';
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
  static const String notificationsClearRead = '/notifications/clear-read';

  // ── Announcements ─────────────────────────────────────────────────────────
  static const String announcements = '/announcements';
  static String announcementById(String id) => '/announcements/$id';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String chatConversations = '/chat/conversations';
  static String chatConversationById(String conversationId) =>
      '/chat/conversations/$conversationId';
  static const String chatUsers = '/chat/users';
  static String chatMessages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String chatMarkRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';
  static String chatUploadFile(String conversationId) =>
      '/chat/conversations/$conversationId/files';
  static String chatMessageReaction(String messageId) =>
      '/chat/messages/$messageId/reaction';
  static String chatWebSocket(String token, String conversationId) =>
      '$resolvedWsBaseUrl$apiPrefix/ws/chat?${Uri(queryParameters: {
            'token': token,
            'conversation_id': conversationId,
          }).query}';

  // ── Leave ─────────────────────────────────────────────────────────────────
  static const String leaveApply = '/leave/apply';
  static const String leave = '/leave';
  static String leaveDecision(String id) => '/leave/$id/decision';
  static const String leaveBalance = '/leave/balance';
  static String leaveTeacherBalance(String teacherId) =>
      '/leave/balance/teacher/$teacherId';

  // ── Gallery ───────────────────────────────────────────────────────────────
  static const String galleryAlbums = '/gallery/albums';
  static String galleryAlbumById(String id) => '/gallery/albums/$id';
  static String galleryAlbumPhotos(String albumId) =>
      '/gallery/albums/$albumId/photos';
  static String galleryPhotoFeature(String photoId) =>
      '/gallery/photos/$photoId/feature';
  static String galleryPhotoInteractions(String photoId) =>
      '/gallery/photos/$photoId/interactions';
  static String galleryPhotoReaction(String photoId) =>
      '/gallery/photos/$photoId/reaction';
  static String galleryPhotoComments(String photoId) =>
      '/gallery/photos/$photoId/comments';
  static String galleryPhotoCommentById(String photoId, String commentId) =>
      '/gallery/photos/$photoId/comments/$commentId';

  // ── Documents ─────────────────────────────────────────────────────────────
  static const String documentRequest = '/documents/request';
  static const String documentUpload = '/documents/upload';
  static const String documents = '/documents';
  static const String documentRequirements = '/documents/requirements';
  static const String documentRequirementStatus =
      '/documents/requirements/status';
  static const String documentReviewQueue = '/documents/review-queue';
  static String documentDownload(String id) => '/documents/$id/download';
  static String documentVerify(String id) => '/documents/$id/verify';

  // ── Audit Logs ────────────────────────────────────────────────────────────
  static const String auditLogs = '/audit-logs';
  static const String auditLogActions = '/audit-logs/actions';
  static const String auditLogEntityTypes = '/audit-logs/entity-types';

  // ── Behaviour ─────────────────────────────────────────────────────────────
  static const String behaviour = '/behaviour';

  // ── Complaints ────────────────────────────────────────────────────────────
  static const String complaints = '/complaints';
  static String complaintStatus(String id) => '/complaints/$id/status';
  static const String feedback = '/complaints/feedback';
  // ── Enrollment ────────────────────────────────────────────────────────────
  static const String enrollmentMappings = '/enrollments/mappings';
  static String enrollmentMappingById(String id) => '/enrollments/mappings/$id';
  static String enrollmentExit(String id) => '/enrollments/mappings/$id/exit';
  static String enrollmentComplete(String id) =>
      '/enrollments/mappings/$id/complete';
  static const String enrollmentRoster = '/enrollments/roster';
  static const String enrollmentRollNumbers = '/enrollments/roll-numbers/assign';
  static String enrollmentHistory(String studentId) =>
      '/enrollments/history/$studentId';

  // ── Promotion ──────────────────────────────────────────────────────────────
  static const String promotionPreview = '/promotions/preview';
  static const String promotionExecute = '/promotions/execute';
  static String promotionReenroll(String studentId) =>
      '/promotions/reenroll/$studentId';
  static const String promotionCopyAssignments =
      '/promotions/copy-teacher-assignments';
  static String _normalizeBaseUrl(String raw) {
    if (raw.endsWith('/')) return raw.substring(0, raw.length - 1);
    return raw;
  }


    // ── My Class ──────────────────────────────────────────────────────────────
  // Decision #4: parent access uses ?child_id= query param
  static const String myClassSubjects = '/my-class/subjects';
  static const String myClassChapters = '/my-class/chapters';
  static String myClassChapterById(String id) => '/my-class/chapters/$id';
  static const String myClassTopics = '/my-class/topics';
  static String myClassTopicById(String id) => '/my-class/topics/$id';
  static const String myClassContent = '/my-class/content';
  static String myClassContentById(String id) => '/my-class/content/$id';
  static const String myClassQuizzes = '/my-class/quizzes';
  static String myClassQuizById(String id) => '/my-class/quizzes/$id';
  static const String myClassQuestions = '/my-class/questions';
  static String myClassQuestionById(String id) => '/my-class/questions/$id';
  static String myClassQuizAttempt(String quizId) =>
      '/my-class/quizzes/$quizId/attempt';
  static String myClassMyAttempts(String quizId) =>
      '/my-class/quizzes/$quizId/attempts/mine';
  static String myClassAllAttempts(String quizId) =>
      '/my-class/quizzes/$quizId/attempts';

  static String _httpToWsBaseUrl(String httpBaseUrl) {
    final normalized = _normalizeBaseUrl(httpBaseUrl);
    if (normalized.startsWith('https://')) {
      return normalized.replaceFirst('https://', 'wss://');
    }
    if (normalized.startsWith('http://')) {
      return normalized.replaceFirst('http://', 'ws://');
    }
    return normalized;
  }

  static String _applyPlatformHostFix(String baseUrl) {
    if (kIsWeb) return baseUrl;
    if (defaultTargetPlatform != TargetPlatform.android) return baseUrl;
    try {
      final uri = Uri.parse(baseUrl);
      final host = uri.host.toLowerCase();
      final isLoopback = host == 'localhost' || host == '127.0.0.1';
      if (!isLoopback) return baseUrl;
      return uri.replace(host: '10.0.2.2').toString();
    } catch (_) {
      return baseUrl;
    }
  }
}
