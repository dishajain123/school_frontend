import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/attendance/attendance_model.dart';
import '../models/attendance/mark_attendance_request.dart';
import '../models/attendance/attendance_analytics.dart';
import '../models/attendance/below_threshold.dart';

class AttendanceRepository {
  const AttendanceRepository(this._dio);
  final Dio _dio;

  // ── Mark Attendance ─────────────────────────────────────────────────────────

  Future<MarkAttendanceResponse> markAttendance(
      MarkAttendanceRequest request) async {
    final response = await _dio.post(
      ApiConstants.attendance,
      data: request.toJson(),
    );
    return MarkAttendanceResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── List Attendance ─────────────────────────────────────────────────────────

  Future<({List<AttendanceModel> items, int total})> listAttendance({
    String? studentId,
    String? standardId,
    String? section,
    String? academicYearId,
    String? date,
    int? month,
    int? year,
    String? subjectId,
    int? lectureNumber,
  }) async {
    final response = await _dio.get(
      ApiConstants.attendance,
      queryParameters: {
        if (studentId != null) 'student_id': studentId,
        if (standardId != null) 'standard_id': standardId,
        if (section != null) 'section': section,
        if (academicYearId != null) 'academic_year_id': academicYearId,
        if (date != null) 'date': date,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
        if (subjectId != null) 'subject_id': subjectId,
        if (lectureNumber != null) 'lecture_number': lectureNumber,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List)
        .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return (items: items, total: data['total'] as int);
  }

  // ── Analytics: Student ──────────────────────────────────────────────────────

  Future<StudentAttendanceAnalytics> getStudentAnalytics(
    String studentId, {
    int? month,
    int? year,
  }) async {
    final response = await _dio.get(
      ApiConstants.attendanceStudentAnalytics(studentId),
      queryParameters: {
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      },
    );
    return StudentAttendanceAnalytics.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── Analytics: Below Threshold ──────────────────────────────────────────────

  Future<BelowThresholdResponse> getBelowThreshold({
    required String standardId,
    required String academicYearId,
    double threshold = 75.0,
  }) async {
    final response = await _dio.get(
      ApiConstants.attendanceBelowThreshold,
      queryParameters: {
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        'threshold': threshold,
      },
    );
    return BelowThresholdResponse.fromJson(
        response.data as Map<String, dynamic>);
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository(ref.read(dioClientProvider));
});
