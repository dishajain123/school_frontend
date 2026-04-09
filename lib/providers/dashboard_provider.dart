import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../data/models/complaint/complaint_model.dart';
import '../data/models/leave/leave_model.dart';
import '../data/models/student/student_model.dart';
import '../data/models/teacher/teacher_class_subject_model.dart';
import '../data/repositories/complaint_repository.dart';
import '../data/repositories/leave_repository.dart';
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
