class RouteNames {
  RouteNames._();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  static const String dashboard = '/dashboard';

  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  static const String notifications = '/notifications';

  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static const String createAnnouncement = '/announcements/create';

  static const String academicYears = '/academic-years';
  static const String rollover = '/academic-years/rollover';

  static const String standards = '/masters/standards';
  static const String subjects = '/masters/subjects';
  static const String gradeMaster = '/masters/grades';

  static const String teachers = '/teachers';
  static const String teacherDetail = '/teachers/:id';
  static const String createTeacher = '/teachers/create';

  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static const String createStudent = '/students/create';

  static const String parents = '/parents';
  static const String parentDetail = '/parents/:id';
  static const String createParent = '/parents/create';

  static const String attendance = '/attendance';
  static const String markAttendance = '/attendance/mark';
  static const String attendanceAnalytics = '/attendance/analytics/:studentId';
  static const String classSnapshot = '/attendance/snapshot';
  static const String belowThreshold = '/attendance/below-threshold';

  static const String assignments = '/assignments';
  static const String assignmentDetail = '/assignments/:id';
  static const String createAssignment = '/assignments/create';
  static const String submissionList = '/assignments/:id/submissions';

  static const String homework = '/homework';
  static const String createHomework = '/homework/create';

  static const String diary = '/diary';
  static const String createDiary = '/diary/create';

  static const String timetable = '/timetable';
  static const String uploadTimetable = '/timetable/upload';

  static const String examSchedules = '/exam-schedule';
  static const String examScheduleTable = '/exam-schedule/table';
  static const String createExamSeries = '/exam-schedule/create';

  static const String results = '/results';
  static const String enterResults = '/results/enter';
  static const String reportCard = '/results/report-card';

  static const String feeDashboard = '/fees';
  static const String paymentHistory = '/fees/payment-history';
  static const String recordPayment = '/fees/record-payment';
  static const String feeReceipt = '/fees/receipt';
  static const String receipt = '/fees/receipt/:id';

  static const String conversations = '/chat';
  static const String chatRoom = '/chat/:conversationId';

  static const String leaveList = '/leave';
  static const String applyLeave = '/leave/apply';
  static const String leaveBalance = '/leave/balance';
  static const String leaveDecision = '/leave/:id/decision';

  static const String galleryAlbums = '/gallery';
  static const String albumDetail = '/gallery/:id';
  static const String createAlbum = '/gallery/create';

  static const String documents = '/documents';
  static const String requestDocument = '/documents/request';

  static const String behaviourLogs = '/behaviour';
  static const String createBehaviourLog = '/behaviour/create';

  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static const String createComplaint = '/complaints/create';

  static const String schools = '/schools';
  static const String schoolDetail = '/schools/:id';
  static const String createSchool = '/schools/create';
  static const String schoolSettings = '/settings';

  // ── Path helpers ──────────────────────────────────────────────────────────
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
  static String behaviourLogsPath({String? studentId}) =>
      studentId == null ? '/behaviour' : '/behaviour?student_id=$studentId';
  static String createBehaviourLogPath({String? studentId}) => studentId == null
      ? '/behaviour/create'
      : '/behaviour/create?student_id=$studentId';
  static String complaintDetailPath(String id) => '/complaints/$id';
  static String schoolDetailPath(String id) => '/schools/$id';
}
