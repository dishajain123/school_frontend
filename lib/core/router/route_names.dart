// lib/core/router/route_names.dart  [Mobile App]
class RouteNames {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String enrollmentPending = '/enrollment-pending';
  static const String forgotPassword = '/forgot-password';
  static const String verifyOtp = '/verify-otp';
  static const String resetPassword = '/reset-password';

  // Shell (bottom nav)
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';
  static const String notifications = '/notifications';

  // Announcements
  static const String announcements = '/announcements';
  static const String announcementDetail = '/announcements/:id';
  static String announcementDetailPath(String id) => '/announcements/$id';
  static const String createAnnouncement = '/announcements/create';

  // Academic Years
  static const String academicYears = '/academic-years';
  static const String rollover = '/academic-years/rollover';

  // Masters
  static const String standards = '/standards';
  static const String subjects = '/subjects';
  static const String gradeMaster = '/grade-master';

  // Teachers
  static const String teachers = '/teachers';
  static const String teacherDetail = '/teachers/:id';
  static String teacherDetailPath(String id) => '/teachers/$id';
  static const String createTeacher = '/teachers/create';
  static const String teacherAnalytics = '/teacher-analytics';

  // Students
  static const String students = '/students';
  static const String studentDetail = '/students/:id';
  static String studentDetailPath(String id) => '/students/$id';
  static const String createStudent = '/students/create';

  // Parents
  static const String parents = '/parents';
  static const String parentDetail = '/parents/:id';
  static String parentDetailPath(String id) => '/parents/$id';
  static const String createParent = '/parents/create';

  // Academic History (Phase 7/14)
  static const String academicHistory = '/academic-history';
  static const String academicHistoryDetail = '/academic-history/:studentId';
  static String academicHistoryDetailPath(String id) => '/academic-history/$id';
  static const String reenrollment = '/enrollment/reenroll/:studentId';
  static String reenrollmentPath(String studentId) =>
      '/enrollment/reenroll/$studentId';

  // Teacher Schedule (Phase 4)
  static const String mySchedule = '/my-schedule';

  // 🔥 NEW — My Class (student/parent read view)
  static const String myClass = '/my-class';

  // 🔥 NEW — Teacher My Class (teacher content management)
  // Decision #5: separate route (NOT inside schedule screen)
  static const String teacherMyClass = '/teacher/my-class';
  static const String classroomMonitor = '/classroom-monitor';

  // Attendance
  static const String attendance = '/attendance';
  static const String attendanceDetail = '/attendance/:id';
  static const String markAttendance = '/attendance/mark';
  static const String attendanceOverview = '/attendance/overview';

  // Assignments
  static const String assignments = '/assignments';
  static const String assignmentDetail = '/assignments/:id';
  static String assignmentDetailPath(String id) => '/assignments/$id';
  static const String createAssignment = '/assignments/create';
  static const String submissionList = '/assignments/:id/submissions';
  static String submissionListPath(String assignmentId) =>
      '/assignments/$assignmentId/submissions';

  // Homework
  static const String homework = '/homework';
  static const String homeworkDetail = '/homework/:id';
  static String homeworkDetailPath(String id) => '/homework/$id';
  static const String createHomework = '/homework/create';

  // Diary
  static const String diary = '/diary';
  static const String createDiary = '/diary/create';

  // Behaviour
  static const String behaviourLogs = '/behaviour';
  static String behaviourLogsPath({String? studentId}) =>
      studentId == null ? '/behaviour' : '/behaviour?student_id=$studentId';
  static String createBehaviourLogPath({String? studentId}) => studentId == null
      ? '/behaviour/create'
      : '/behaviour/create?student_id=$studentId';

  // Timetable
  static const String timetable = '/timetable';
  static const String uploadTimetable = '/timetable/upload';

  // Exam Schedules
  static const String examSchedules = '/exam-schedules';
  static const String examScheduleTable = '/exam-schedule/table';
  static const String createExamSeries = '/exam-schedule/create';

  // Results
  static const String results = '/results';
  static const String principalResultsDistribution = '/results/distribution';
  static const String enterResults = '/results/enter';
  static const String reportCard = '/results/report-card';
  static const String principalReportDetails = '/reports/details';

  // Fees
  static const String feeDashboard = '/fees';
  static String feeDashboardForStudent(String studentId) =>
      '/fees?student_id=$studentId';
  static const String paymentHistory = '/fees/payment-history';
  static const String recordPayment = '/fees/record-payment';
  static const String feeReceipt = '/fees/receipt';
  static const String receipt = '/fees/receipt/:id';

  // Chat
  static const String conversations = '/chat';
  static const String chatRoom = '/chat/:conversationId';
  static String chatRoomPath(String conversationId) => '/chat/$conversationId';

  // Leave
  static const String leaveList = '/leave';
  static const String applyLeave = '/leave/apply';
  static const String leaveBalance = '/leave/balance';
  static const String leaveDecision = '/leave/:id/decision';
  static String leaveDecisionPath(String id) => '/leave/$id/decision';

  // Gallery
  static const String galleryAlbums = '/gallery';
  static const String albumDetail = '/gallery/:id';
  static String albumDetailPath(String id) => '/gallery/$id';
  static const String createAlbum = '/gallery/create';

  // Documents
  static const String documents = '/documents';

  // Audit Logs
  static const String auditLogs = '/audit-logs';

  // Complaints
  static const String complaints = '/complaints';
  static const String complaintDetail = '/complaints/:id';
  static String complaintDetailPath(String id) => '/complaints/$id';
  static const String createComplaint = '/complaints/create';

  // Schools
  static const String schools = '/schools';
  static const String schoolDetail = '/schools/:id';
  static String schoolDetailPath(String id) => '/schools/$id';
  static const String createSchool = '/schools/create';
  static const String schoolSettings = '/schools/settings';
}
