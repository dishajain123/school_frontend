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
import 'auth_provider.dart';

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

class TeacherAnalyticsAssignmentItem {
  const TeacherAnalyticsAssignmentItem({
    required this.standardId,
    required this.standardName,
    required this.section,
    required this.subjectId,
    required this.subjectName,
    required this.academicYearId,
  });

  final String standardId;
  final String standardName;
  final String section;
  final String subjectId;
  final String subjectName;
  final String academicYearId;

  factory TeacherAnalyticsAssignmentItem.fromJson(Map<String, dynamic> json) {
    return TeacherAnalyticsAssignmentItem(
      standardId: json['standard_id'] as String? ?? '',
      standardName: json['standard_name'] as String? ?? '',
      section: json['section'] as String? ?? '',
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      academicYearId: json['academic_year_id'] as String? ?? '',
    );
  }
}

class TeacherAssignmentSubmissionAnalyticsModel {
  const TeacherAssignmentSubmissionAnalyticsModel({
    required this.totalAssignments,
    required this.overdueAssignments,
    required this.totalSubmissions,
    required this.onTimeSubmissions,
    required this.lateSubmissions,
    required this.pendingReviewSubmissions,
  });

  final int totalAssignments;
  final int overdueAssignments;
  final int totalSubmissions;
  final int onTimeSubmissions;
  final int lateSubmissions;
  final int pendingReviewSubmissions;

  factory TeacherAssignmentSubmissionAnalyticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherAssignmentSubmissionAnalyticsModel(
      totalAssignments: _asInt(json['total_assignments']),
      overdueAssignments: _asInt(json['overdue_assignments']),
      totalSubmissions: _asInt(json['total_submissions']),
      onTimeSubmissions: _asInt(json['on_time_submissions']),
      lateSubmissions: _asInt(json['late_submissions']),
      pendingReviewSubmissions: _asInt(json['pending_review_submissions']),
    );
  }
}

class TeacherAttendanceBySubjectAnalyticsModel {
  const TeacherAttendanceBySubjectAnalyticsModel({
    required this.subjectId,
    required this.subjectName,
    required this.total,
    required this.present,
    required this.absent,
    required this.late,
    required this.attendancePercentage,
  });

  final String subjectId;
  final String subjectName;
  final int total;
  final int present;
  final int absent;
  final int late;
  final double attendancePercentage;

  factory TeacherAttendanceBySubjectAnalyticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherAttendanceBySubjectAnalyticsModel(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      total: _asInt(json['total']),
      present: _asInt(json['present']),
      absent: _asInt(json['absent']),
      late: _asInt(json['late']),
      attendancePercentage: _asDouble(json['attendance_percentage']),
    );
  }
}

class TeacherAttendanceAnalyticsModel {
  const TeacherAttendanceAnalyticsModel({
    required this.totalRecords,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.attendancePercentage,
    required this.bySubject,
  });

  final int totalRecords;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final double attendancePercentage;
  final List<TeacherAttendanceBySubjectAnalyticsModel> bySubject;

  factory TeacherAttendanceAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['by_subject'] as List<dynamic>? ?? const [];
    return TeacherAttendanceAnalyticsModel(
      totalRecords: _asInt(json['total_records']),
      presentCount: _asInt(json['present_count']),
      absentCount: _asInt(json['absent_count']),
      lateCount: _asInt(json['late_count']),
      attendancePercentage: _asDouble(json['attendance_percentage']),
      bySubject: raw
          .whereType<Map>()
          .map(
            (e) => TeacherAttendanceBySubjectAnalyticsModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class TeacherMarksBySubjectAnalyticsModel {
  const TeacherMarksBySubjectAnalyticsModel({
    required this.subjectId,
    required this.subjectName,
    required this.entries,
    required this.averagePercentage,
  });

  final String subjectId;
  final String subjectName;
  final int entries;
  final double averagePercentage;

  factory TeacherMarksBySubjectAnalyticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TeacherMarksBySubjectAnalyticsModel(
      subjectId: json['subject_id'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      entries: _asInt(json['entries']),
      averagePercentage: _asDouble(json['average_percentage']),
    );
  }
}

class TeacherMarksAnalyticsModel {
  const TeacherMarksAnalyticsModel({
    required this.totalEntries,
    required this.averagePercentage,
    required this.aboveAverageCount,
    required this.moderateCount,
    required this.belowAverageCount,
    required this.bySubject,
  });

  final int totalEntries;
  final double averagePercentage;
  final int aboveAverageCount;
  final int moderateCount;
  final int belowAverageCount;
  final List<TeacherMarksBySubjectAnalyticsModel> bySubject;

  factory TeacherMarksAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final raw = json['by_subject'] as List<dynamic>? ?? const [];
    return TeacherMarksAnalyticsModel(
      totalEntries: _asInt(json['total_entries']),
      averagePercentage: _asDouble(json['average_percentage']),
      aboveAverageCount: _asInt(json['above_average_count']),
      moderateCount: _asInt(json['moderate_count']),
      belowAverageCount: _asInt(json['below_average_count']),
      bySubject: raw
          .whereType<Map>()
          .map(
            (e) => TeacherMarksBySubjectAnalyticsModel.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
    );
  }
}

class TeacherAnalyticsData {
  const TeacherAnalyticsData({
    required this.teacherId,
    required this.assignments,
    required this.assignmentSubmission,
    required this.attendance,
    required this.marks,
  });

  final String teacherId;
  final List<TeacherAnalyticsAssignmentItem> assignments;
  final TeacherAssignmentSubmissionAnalyticsModel assignmentSubmission;
  final TeacherAttendanceAnalyticsModel attendance;
  final TeacherMarksAnalyticsModel marks;

  factory TeacherAnalyticsData.fromJson(Map<String, dynamic> json) {
    final assignmentRaw = json['assignments'] as List<dynamic>? ?? const [];
    final assignmentSubmission = Map<String, dynamic>.from(
        (json['assignment_submission'] as Map?) ?? {});
    final attendance =
        Map<String, dynamic>.from((json['attendance'] as Map?) ?? {});
    final marks = Map<String, dynamic>.from((json['marks'] as Map?) ?? {});
    return TeacherAnalyticsData(
      teacherId: json['teacher_id'] as String? ?? '',
      assignments: assignmentRaw
          .whereType<Map>()
          .map(
            (e) => TeacherAnalyticsAssignmentItem.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList(),
      assignmentSubmission: TeacherAssignmentSubmissionAnalyticsModel.fromJson(
          assignmentSubmission),
      attendance: TeacherAttendanceAnalyticsModel.fromJson(attendance),
      marks: TeacherMarksAnalyticsModel.fromJson(marks),
    );
  }
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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
  ref.watch(currentUserProvider);
  final activeYearId = ref.watch(activeYearProvider)?.id;

  final teacherClassRepo = ref.read(teacherClassSubjectRepositoryProvider);
  final assignmentRepo = ref.read(assignmentRepositoryProvider);
  final leaveRepo = ref.read(leaveRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);
  final dio = ref.read(dioClientProvider);

  List<TeacherClassSubjectModel> assignments = const [];
  var overdueAssignmentsCount = 0;
  var pendingLeavesCount = 0;
  var complaintsCount = 0;

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
    // Keep this aligned with the teacher complaints screen, which lists
    // the teacher's own complaints across statuses.
    final complaints = await complaintRepo.list();
    complaintsCount = complaints.total;
  } on DioException {
    complaintsCount = 0;
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
    openComplaints: complaintsCount,
    teacherAttendancePercentage:
        _asDouble(report['teacher_attendance_percentage']),
  );
});

typedef TeacherAnalyticsParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
  String? subjectId,
});

final teacherAnalyticsProvider =
    FutureProvider.family<TeacherAnalyticsData, TeacherAnalyticsParams>(
  (ref, params) async {
    ref.watch(currentUserProvider);
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(
      '/teachers/me/analytics',
      queryParameters: {
        if (params.academicYearId != null)
          'academic_year_id': params.academicYearId,
        if (params.standardId != null) 'standard_id': params.standardId,
        if (params.section != null && params.section!.trim().isNotEmpty)
          'section': params.section,
        if (params.subjectId != null) 'subject_id': params.subjectId,
      },
    );
    return TeacherAnalyticsData.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  },
);

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

  var totalComplaintsCount = 0;
  try {
    // For parent dashboard, backend already scopes complaints to current parent.
    // Avoid extra role filter here because some deployments may reject it and
    // incorrectly fall back to 0.
    final complaintsResponse = await complaintRepo.list();
    totalComplaintsCount = complaintsResponse.total;
  } catch (_) {
    // Fallback for deployments that require explicit role filter.
    try {
      final complaintsResponse = await complaintRepo.list(
        complainantType: ComplainantType.parent,
      );
      totalComplaintsCount = complaintsResponse.total;
    } catch (_) {
      totalComplaintsCount = 0;
    }
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
    openComplaints: totalComplaintsCount,
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
  StudentAttendanceAnalytics? analytics;
  AssignmentListResponse? activeAssignments;
  AssignmentListResponse? overdueAssignments;
  ComplaintListResponse? openComplaints;
  List<ExamModel> exams = const [];

  try {
    analytics = await attendanceRepo.getStudentAnalytics(me.id);
  } catch (_) {}
  try {
    activeAssignments = await assignmentRepo.listAssignments(
      standardId: me.standardId,
      academicYearId: me.academicYearId,
      isActive: true,
      page: 1,
      pageSize: 1,
    );
  } catch (_) {}
  try {
    overdueAssignments = await assignmentRepo.listAssignments(
      standardId: me.standardId,
      academicYearId: me.academicYearId,
      isOverdue: true,
      page: 1,
      pageSize: 1,
    );
  } catch (_) {}
  try {
    openComplaints = await complaintRepo.list(status: ComplaintStatus.open);
  } catch (_) {}
  try {
    exams = await resultRepo.listExams(
      studentId: me.id,
      academicYearId: me.academicYearId,
      standardId: me.standardId,
    );
  } catch (_) {}

  final now = DateTime.now();
  final upcomingExams =
      exams.where((exam) => !exam.startDate.isBefore(now)).length;

  return StudentDashboardStats(
    attendancePercentage: analytics?.overallPercentage ?? 0,
    activeAssignments: activeAssignments?.total ?? 0,
    overdueAssignments: overdueAssignments?.total ?? 0,
    upcomingExams: upcomingExams,
    openComplaints: openComplaints?.total ?? 0,
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
    final scoped = await repo.listByClass(
      standardId: params.standardId,
      section: params.section,
      academicYearId: params.academicYearId,
    );
    if (scoped.isNotEmpty || params.academicYearId == null) {
      return scoped;
    }
    // Fallback for legacy/mismatched academic-year mapping:
    // if no rows found for current year, try same class+section without year.
    return repo.listByClass(
      standardId: params.standardId,
      section: params.section,
      academicYearId: null,
    );
  },
);

typedef TeacherDirectoryParams = ({
  String standardId,
  String? academicYearId,
});

final teacherDirectoryByStandardProvider =
    FutureProvider.family<Map<String, String>, TeacherDirectoryParams>(
  (ref, params) async {
    final repo = ref.read(teacherRepositoryProvider);
    final response = await repo.list(
      standardId: params.standardId,
      academicYearId: params.academicYearId,
      page: 1,
      pageSize: 200,
    );
    return {
      for (final teacher in response.items) teacher.id: teacher.displayName,
    };
  },
);

final myStudentProfileProvider = FutureProvider<StudentModel>((ref) async {
  final repo = ref.read(studentRepositoryProvider);
  return repo.getMyProfile();
});
