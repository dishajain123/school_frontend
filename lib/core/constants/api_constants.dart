class ApiConstants {
  ApiConstants._();

  // ── Base ─────────────────────────────────────────────────────────────────
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator
  // static const String baseUrl = 'http://localhost:8000'; // iOS simulator
  static const String apiPrefix = '/api/v1';

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
  static String academicYearActivate(String id) => '/academic-years/$id/activate';
  static String academicYearRollover(String id) => '/academic-years/$id/rollover';

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
  static String studentById(String id) => '/students/$id';
  static String studentPromotionStatus(String id) => '/students/$id/promotion-status';

  // ── Parents ───────────────────────────────────────────────────────────────
  static const String parents = '/parents';
  static String parentById(String id) => '/parents/$id';
  static const String myChildren = '/parents/me/children';
  static String parentChildren(String id) => '/parents/$id/children';

  // ── Attendance ────────────────────────────────────────────────────────────
  static const String attendance = '/attendance';
  static String attendanceStudentAnalytics(String studentId) =>
      '/attendance/analytics/student/$studentId';
  static String attendanceClassSnapshot(String standardId) =>
      '/attendance/analytics/class/$standardId';
  static const String attendanceBelowThreshold = '/attendance/analytics/below-threshold';

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
  static String timetableByStandard(String standardId) => '/timetable/$standardId';

  // ── Exam Schedule ─────────────────────────────────────────────────────────
  static const String examSchedule = '/exam-schedule';
  static String examScheduleById(String id) => '/exam-schedule/$id';
  static String examScheduleEntries(String seriesId) => '/exam-schedule/$seriesId/entries';
  static String examSchedulePublish(String seriesId) => '/exam-schedule/$seriesId/publish';
  static String examScheduleEntryCancel(String entryId) => '/exam-schedule/entries/$entryId/cancel';

  // ── Results ───────────────────────────────────────────────────────────────
  static const String resultsExams = '/api/v1/results/exams';
  static const String resultsEntries = '/api/v1/results/entries';
  static const String results = '/api/v1/results';
  static String resultsExamPublish(String examId) =>
      '/api/v1/results/exams/$examId/publish';
  static String reportCard(String studentId) =>
      '/api/v1/results/report-card/$studentId';

  // ── Fees ──────────────────────────────────────────────────────────────────
  static const String feeStructures = '/fees/structures';
  static const String feeLedgerGenerate = '/fees/ledger/generate';
  static const String feePayments = '/fees/payments';
  static const String feeDashboard = '/fees';
  static String feeReceiptUrl(String paymentId) => '/fees/payments/$paymentId/receipt';

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
  static String chatMessages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String chatMarkRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';
  static String chatUploadFile(String conversationId) =>
      '/chat/conversations/$conversationId/files';
  static String chatWebSocket(String token, String conversationId) =>
      '${baseUrl.replaceFirst('http', 'ws')}/api/v1/ws/chat?token=$token&conversation_id=$conversationId';

  // ── Leave ─────────────────────────────────────────────────────────────────
  static const String leaveApply = '/leave/apply';
  static const String leave = '/leave';
  static String leaveDecision(String id) => '/leave/$id/decision';
  static const String leaveBalance = '/leave/balance';

  // ── Gallery ───────────────────────────────────────────────────────────────
  static const String galleryAlbums = '/gallery/albums';
  static String galleryAlbumById(String id) => '/gallery/albums/$id';
  static String galleryAlbumPhotos(String albumId) => '/gallery/albums/$albumId/photos';
  static String galleryPhotoFeature(String photoId) => '/gallery/photos/$photoId/feature';

  // ── Documents ─────────────────────────────────────────────────────────────
  static const String documentRequest = '/documents/request';
  static const String documents = '/documents';
  static String documentDownload(String id) => '/documents/$id/download';

  // ── Behaviour ─────────────────────────────────────────────────────────────
  static const String behaviour = '/behaviour';

  // ── Complaints ────────────────────────────────────────────────────────────
  static const String complaints = '/complaints';
  static String complaintStatus(String id) => '/complaints/$id/status';
  static const String feedback = '/complaints/feedback';
}

