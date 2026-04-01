/// Named route constants used throughout the app.
class RouteNames {
  RouteNames._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // ── Shell / Dashboard ─────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ── Profile ───────────────────────────────────────────────────────────────
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';

  // ── Announcements ─────────────────────────────────────────────────────────
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static const String createAnnouncement = '/announcements/create';

  // ── Academic Years ────────────────────────────────────────────────────────
  static const String academicYears = '/academic-years';
  static const String rollover = '/academic-years/rollover';

  // ── Masters ───────────────────────────────────────────────────────────────
  static const String standards = '/masters/standards';
  static const String subjects = '/masters/subjects';
  static const String gradeMaster = '/masters/grades';

  // ── Teachers ──────────────────────────────────────────────────────────────
  static const String teachers = '/teachers';
  static const String teacherDetail = '/teachers/:id';
  static const String createTeacher = '/teachers/create';

  // ── Students ──────────────────────────────────────────────────────────────
  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static const String createStudent = '/students/create';

  // ── Parents ───────────────────────────────────────────────────────────────
  static const String parents = '/parents';
  static const String parentDetail = '/parents/:id';

  // ── Attendance ────────────────────────────────────────────────────────────
  static const String attendance = '/attendance';
  static const String markAttendance = '/attendance/mark';
  static const String attendanceAnalytics = '/attendance/analytics/:studentId';
  static const String classSnapshot = '/attendance/snapshot';
  static const String belowThreshold = '/attendance/below-threshold';

  // ── Assignments ───────────────────────────────────────────────────────────
  static const String assignments = '/assignments';
  static const String assignmentDetail = '/assignments/:id';
  static const String createAssignment = '/assignments/create';
  static const String submissionList = '/assignments/:id/submissions';

  // ── Homework ──────────────────────────────────────────────────────────────
  static const String homework = '/homework';
  static const String createHomework = '/homework/create';

  // ── Diary ─────────────────────────────────────────────────────────────────
  static const String diary = '/diary';
  static const String createDiary = '/diary/create';

  // ── Timetable ─────────────────────────────────────────────────────────────
  static const String timetable = '/timetable';
  static const String uploadTimetable = '/timetable/upload';

  // ── Exam Schedule ─────────────────────────────────────────────────────────
  static const String examSchedules = '/exam-schedule';
  static const String examScheduleTable = '/exam-schedule/:id/table';
  static const String createExamSeries = '/exam-schedule/create';

  // ── Results ───────────────────────────────────────────────────────────────
  static const String results = '/results';
  static const String enterResults = '/results/enter';
  static const String reportCard = '/results/report-card/:studentId';

  // ── Fees ──────────────────────────────────────────────────────────────────
  static const String feeDashboard = '/fees';
  static const String paymentHistory = '/fees/payments';
  static const String recordPayment = '/fees/record';
  static const String receipt = '/fees/receipt/:id';

  // ── Chat ──────────────────────────────────────────────────────────────────
  static const String conversations = '/chat';
  static const String chatRoom = '/chat/:conversationId';

  // ── Leave ─────────────────────────────────────────────────────────────────
  static const String leaveList = '/leave';
  static const String applyLeave = '/leave/apply';
  static const String leaveBalance = '/leave/balance';
  static const String leaveDecision = '/leave/:id/decision';

  // ── Gallery ───────────────────────────────────────────────────────────────
  static const String galleryAlbums = '/gallery';
  static const String albumDetail = '/gallery/:id';
  static const String createAlbum = '/gallery/create';

  // ── Documents ─────────────────────────────────────────────────────────────
  static const String documents = '/documents';
  static const String requestDocument = '/documents/request';

  // ── Behaviour ─────────────────────────────────────────────────────────────
  static const String behaviourLogs = '/behaviour';
  static const String createBehaviourLog = '/behaviour/create';

  // ── Complaints ────────────────────────────────────────────────────────────
  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static const String createComplaint = '/complaints/create';

  // ── Superadmin ────────────────────────────────────────────────────────────
  static const String schools = '/schools';
  static const String schoolDetail = '/schools/:id';
  static const String createSchool = '/schools/create';
  static const String schoolSettings = '/settings';

  // ── Helpers: build parameterized paths ───────────────────────────────────
  static String announcementDetailPath(String id) => '/announcements/$id';
  static String teacherDetailPath(String id) => '/teachers/$id';
  static String studentDetailPath(String id) => '/students/$id';
  static String parentDetailPath(String id) => '/parents/$id';
  static String attendanceAnalyticsPath(String studentId) =>
      '/attendance/analytics/$studentId';
  static String assignmentDetailPath(String id) => '/assignments/$id';
  static String submissionListPath(String assignmentId) =>
      '/assignments/$assignmentId/submissions';
  static String examScheduleTablePath(String id) => '/exam-schedule/$id/table';
  static String reportCardPath(String studentId) =>
      '/results/report-card/$studentId';
  static String receiptPath(String id) => '/fees/receipt/$id';
  static String chatRoomPath(String conversationId) => '/chat/$conversationId';
  static String leaveDecisionPath(String id) => '/leave/$id/decision';
  static String albumDetailPath(String id) => '/gallery/$id';
  static String complaintDetailPath(String id) => '/complaints/$id';
  static String schoolDetailPath(String id) => '/schools/$id';
}