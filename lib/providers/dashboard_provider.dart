import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/complaint/complaint_model.dart';
import '../data/models/leave/leave_model.dart';
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
  });

  final int totalStudents;
  final int totalTeachers;
  final int pendingLeaves;
  final int openComplaints;
}

final principalDashboardStatsProvider =
    FutureProvider<PrincipalDashboardStats>((ref) async {
  final activeYearId = ref.watch(activeYearProvider)?.id;

  final studentRepo = ref.read(studentRepositoryProvider);
  final teacherRepo = ref.read(teacherRepositoryProvider);
  final leaveRepo = ref.read(leaveRepositoryProvider);
  final complaintRepo = ref.read(complaintRepositoryProvider);

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

  return PrincipalDashboardStats(
    totalStudents: students.total,
    totalTeachers: teachers.total,
    pendingLeaves: pendingLeaves.total,
    openComplaints: openComplaints.total,
  );
});
