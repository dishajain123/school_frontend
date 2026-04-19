import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment/assignment_model.dart';
import '../data/models/attendance/attendance_analytics.dart';
import '../core/network/dio_client.dart';
import '../data/models/complaint/complaint_model.dart';
import '../data/models/leave/leave_model.dart';
import '../data/models/parent/child_summary.dart';
import '../data/models/result/result_model.dart';
import '../data/models/student/student_model.dart';
import '../data/models/teacher/teacher_class_subject_model.dart';
import '../data/repositories/assignment_repository.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/complaint_repository.dart';
import '../data/repositories/fee_repository.dart';
import '../data/repositories/leave_repository.dart';
import '../data/repositories/parent_repository.dart';
import '../data/repositories/result_repository.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/teacher_repository.dart';
import 'academic_year_provider.dart';

class PrincipalDashboardStats {
  const PrincipalDashboardStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.pendingLeaves,
    required this.openComplaints,
    required this.studentAttendancePercentage,
    required this.feesPaidAmount,
    required this.resultsAveragePercentage,
    required this.teacherAttendancePercentage,
  });

  final int totalStudents;
  final int totalTeachers;
  final int pendingLeaves;
  final int openComplaints;

  // Principal report highlights
  final double studentAttendancePercentage;
  final double feesPaidAmount;
  final double resultsAveragePercentage;
  final double teacherAttendancePercentage;
}

class TeacherDashboardStats {
  const TeacherDashboardStats({
    required this.myClasses,
    required this.pendingLeaves,
    required this.overdueAssignments,
    required this.openComplaints,
    required this.teacherAttendancePercentage,
  });

  final int myClasses;
  final int pendingLeaves;
  final int overdueAssignments;
  final int openComplaints;
  final double teacherAttendancePercentage;
}

class ParentDashboardStats {
  const ParentDashboardStats({
    required this.linkedChildren,
    required this.classTeachers,
    required this.outstandingFeesAmount,
    required this.openComplaints,
  });

  final int linkedChildren;
  final int classTeachers;
  final double outstandingFeesAmount;
  final int openComplaints;
}

class StudentDashboardStats {
  const StudentDashboardStats({
    required this.attendancePercentage,
    required this.activeAssignments,
    required this.overdueAssignments,
    required this.upcomingExams,
    required this.openComplaints,
  });

  final double attendancePercentage;
  final int activeAssignments;
  final int overdueAssignments;
  final int upcomingExams;
  final int openComplaints;
}

class TrusteeDashboardStats {
  const TrusteeDashboardStats({
    required this.totalStudents,
    required this.totalTeachers,
    required this.openComplaints,
    required this.feesPaidAmount,
    required this.studentAttendancePercentage,
  });

  final int totalStudents;
  final int totalTeachers;
  final int openComplaints;
  final double feesPaidAmount;
  final double studentAttendancePercentage;
}

double _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

final principalDashboardStatsProvider =
    FutureProvider<PrincipalDashboardStats>((ref) async {
  final activeYearId = ref.watch(activeYearProvider)?.id;

  final studentRepo = ref.read(studentRepositoryProvider);
  final teacherRepo = ref.read(teacherRepositoryProvider);
  final leaveRepo = ref.read(leaveRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final dio = ref.read(dioClientProvider);

  final results = await Future.wait([
    studentRepo.list(
      academicYearId: activeYearId,
      page: 1,
      pageSize: 1,
    ),
    teacherRepo.list(
      academicYearId: activeYearId,
      page: 1,
      pageSize: 1,
    ),
    leaveRepo.list(
      status: LeaveStatus.pending,
      academicYearId: activeYearId,
    ),
    complaintRepo.list(
      status: ComplaintStatus.open,
    ),
  ]);

  final students = results[0] as StudentListResult;
  final teachers = results[1] as TeacherListResult;
  final pendingLeaves = results[2] as LeaveListResponse;
  final openComplaints = results[3] as ComplaintListResponse;

  Map<String, dynamic> report = <String, dynamic>{};
  try {
    final reportRes = await dio.get(
      '/principal-reports/overview',
      queryParameters: {
        if (activeYearId != null) 'academic_year_id': activeYearId,
      },
    );
    if (reportRes.data is Map) {
      report = Map<String, dynamic>.from(reportRes.data as Map);
    }
  } on DioException {
    // Keep dashboard usable even if report endpoint is unavailable.
    report = <String, dynamic>{};
  }

  return PrincipalDashboardStats(
    totalStudents: students.total,
    totalTeachers: teachers.total,
    pendingLeaves: pendingLeaves.total,
    openComplaints: openComplaints.total,
    studentAttendancePercentage:
        _asDouble(report['student_attendance_percentage']),
    feesPaidAmount: _asDouble(report['fees_paid_amount']),
    resultsAveragePercentage: _asDouble(report['results_average_percentage']),
    teacherAttendancePercentage:
        _asDouble(report['teacher_attendance_percentage']),
  );
});

final teacherDashboardStatsProvider =
    FutureProvider<TeacherDashboardStats>((ref) async {
  final activeYearId = ref.watch(activeYearProvider)?.id;

  final teacherClassRepo = ref.read(teacherClassSubjectRepositoryProvider);
  final assignmentRepo = ref.read(assignmentRepositoryProvider);
  final leaveRepo = ref.read(leaveRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final dio = ref.read(dioClientProvider);

  List<TeacherClassSubjectModel> assignments = const [];
  var overdueAssignmentsCount = 0;
  var pendingLeavesCount = 0;
  var openComplaintsCount = 0;

  try {
    assignments = await teacherClassRepo.getMyAssignments(
      academicYearId: activeYearId,
    );
  } on DioException {
    assignments = const [];
  }

  try {
    final overdueAssignments = await assignmentRepo.listAssignments(
      academicYearId: activeYearId,
      isOverdue: true,
      page: 1,
      pageSize: 1,
    );
    overdueAssignmentsCount = overdueAssignments.total;
  } on DioException {
    overdueAssignmentsCount = 0;
  }

  try {
    final pendingLeaves = await leaveRepo.list(
      status: LeaveStatus.pending,
      academicYearId: activeYearId,
    );
    pendingLeavesCount = pendingLeaves.total;
  } on DioException {
    pendingLeavesCount = 0;
  }

  try {
    final openComplaints = await complaintRepo.list(
      status: ComplaintStatus.open,
    );
    openComplaintsCount = openComplaints.total;
  } on DioException {
    openComplaintsCount = 0;
  }

  Map<String, dynamic> report = <String, dynamic>{};
  try {
    final reportRes = await dio.get(
      '/principal-reports/overview',
      queryParameters: {
        if (activeYearId != null) 'academic_year_id': activeYearId,
      },
    );
    if (reportRes.data is Map) {
      report = Map<String, dynamic>.from(reportRes.data as Map);
    }
  } on DioException {
    report = <String, dynamic>{};
  }

  final uniqueClassSections = assignments
      .map((a) => '${a.standardId}|${a.section.trim().toUpperCase()}')
      .toSet();

  return TeacherDashboardStats(
    myClasses: uniqueClassSections.length,
    pendingLeaves: pendingLeavesCount,
    overdueAssignments: overdueAssignmentsCount,
    openComplaints: openComplaintsCount,
    teacherAttendancePercentage:
        _asDouble(report['teacher_attendance_percentage']),
  );
});

final parentDashboardStatsProvider =
    FutureProvider<ParentDashboardStats>((ref) async {
  final parentRepo = ref.read(parentRepositoryProvider);
  final teacherClassRepo = ref.read(teacherClassSubjectRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final feeRepo = ref.read(feeRepositoryProvider);

  var children = <ChildSummaryModel>[];
  try {
    children = await parentRepo.getMyChildren();
  } catch (_) {
    children = <ChildSummaryModel>[];
  }

  var openComplaintsCount = 0;
  try {
    final openComplaintsResponse = await complaintRepo.list(
      status: ComplaintStatus.open,
    );
    openComplaintsCount = openComplaintsResponse.total;
  } catch (_) {
    openComplaintsCount = 0;
  }

  final classKeys = <String>{};
  for (final child in children) {
    final standardId = child.standardId;
    final section = child.section?.trim();
    if (standardId == null ||
        standardId.isEmpty ||
        section == null ||
        section.isEmpty) {
      continue;
    }
    final year = child.academicYearId ?? '';
    classKeys.add('$standardId|${section.toUpperCase()}|$year');
  }

  final teacherIds = <String>{};
  for (final key in classKeys) {
    final parts = key.split('|');
    try {
      final rows = await teacherClassRepo.listByClass(
        standardId: parts[0],
        section: parts[1],
        academicYearId: parts[2].isEmpty ? null : parts[2],
      );
      for (final row in rows) {
        teacherIds.add(row.teacherId);
      }
    } catch (_) {
      // Keep available teacher count from successful class queries.
    }
  }

  var outstandingTotal = 0.0;
  for (final child in children) {
    try {
      final fee = await feeRepo.getDashboard(child.id);
      outstandingTotal += fee.grandOutstanding;
    } catch (_) {
      // Keep available outstanding total from successful child queries.
    }
  }

  return ParentDashboardStats(
    linkedChildren: children.length,
    classTeachers: teacherIds.length,
    outstandingFeesAmount: outstandingTotal,
    openComplaints: openComplaintsCount,
  );
});

final studentDashboardStatsProvider =
    FutureProvider<StudentDashboardStats>((ref) async {
  final studentRepo = ref.read(studentRepositoryProvider);
  final attendanceRepo = ref.read(attendanceRepositoryProvider);
  final assignmentRepo = ref.read(assignmentRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final resultRepo = ref.read(resultRepositoryProvider);

  final me = await studentRepo.getMyProfile();

  final responses = await Future.wait([
    attendanceRepo.getStudentAnalytics(me.id),
    assignmentRepo.listAssignments(
      standardId: me.standardId,
      academicYearId: me.academicYearId,
      isActive: true,
      page: 1,
      pageSize: 1,
    ),
    assignmentRepo.listAssignments(
      standardId: me.standardId,
      academicYearId: me.academicYearId,
      isOverdue: true,
      page: 1,
      pageSize: 1,
    ),
    complaintRepo.list(status: ComplaintStatus.open),
    resultRepo.listExams(
      studentId: me.id,
      academicYearId: me.academicYearId,
      standardId: me.standardId,
    ),
  ]);

  final analytics = responses[0] as StudentAttendanceAnalytics;
  final activeAssignments = responses[1] as AssignmentListResponse;
  final overdueAssignments = responses[2] as AssignmentListResponse;
  final openComplaints = responses[3] as ComplaintListResponse;
  final exams = responses[4] as List<ExamModel>;

  final now = DateTime.now();
  final upcomingExams =
      exams.where((exam) => !exam.startDate.isBefore(now)).length;

  return StudentDashboardStats(
    attendancePercentage: analytics.overallPercentage,
    activeAssignments: activeAssignments.total,
    overdueAssignments: overdueAssignments.total,
    upcomingExams: upcomingExams,
    openComplaints: openComplaints.total,
  );
});

final trusteeDashboardStatsProvider =
    FutureProvider<TrusteeDashboardStats>((ref) async {
  final activeYearId = ref.watch(activeYearProvider)?.id;

  final studentRepo = ref.read(studentRepositoryProvider);
  final teacherRepo = ref.read(teacherRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final dio = ref.read(dioClientProvider);

  final results = await Future.wait([
    studentRepo.list(
      academicYearId: activeYearId,
      page: 1,
      pageSize: 1,
    ),
    teacherRepo.list(
      academicYearId: activeYearId,
      page: 1,
      pageSize: 1,
    ),
    complaintRepo.list(status: ComplaintStatus.open),
  ]);

  final students = results[0] as StudentListResult;
  final teachers = results[1] as TeacherListResult;
  final openComplaints = results[2] as ComplaintListResponse;

  Map<String, dynamic> report = <String, dynamic>{};
  try {
    final reportRes = await dio.get(
      '/principal-reports/overview',
      queryParameters: {
        if (activeYearId != null) 'academic_year_id': activeYearId,
      },
    );
    if (reportRes.data is Map) {
      report = Map<String, dynamic>.from(reportRes.data as Map);
    }
  } on DioException {
    report = <String, dynamic>{};
  }

  return TrusteeDashboardStats(
    totalStudents: students.total,
    totalTeachers: teachers.total,
    openComplaints: openComplaints.total,
    feesPaidAmount: _asDouble(report['fees_paid_amount']),
    studentAttendancePercentage:
        _asDouble(report['student_attendance_percentage']),
  );
});

typedef ClassTeachersParams = ({
  String standardId,
  String section,
  String? academicYearId,
});

final classTeachersProvider =
    FutureProvider.family<List<TeacherClassSubjectModel>, ClassTeachersParams>(
  (ref, params) async {
    final repo = ref.read(teacherClassSubjectRepositoryProvider);
    return repo.listByClass(
      standardId: params.standardId,
      section: params.section,
      academicYearId: params.academicYearId,
    );
  },
);

final myStudentProfileProvider = FutureProvider<StudentModel>((ref) async {
  final repo = ref.read(studentRepositoryProvider);
  return repo.getMyProfile();
});
