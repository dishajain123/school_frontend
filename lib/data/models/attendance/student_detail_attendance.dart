import 'attendance_analytics.dart';
import 'attendance_model.dart';

class MonthlyAttendanceSummary {
  const MonthlyAttendanceSummary({
    required this.month,
    required this.year,
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  final int month;
  final int year;
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  factory MonthlyAttendanceSummary.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceSummary(
      month: json['month'] as int,
      year: json['year'] as int,
      totalClasses: json['total_classes'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class StudentDetailAttendanceResponse {
  const StudentDetailAttendanceResponse({
    required this.studentId,
    required this.admissionNumber,
    required this.studentName,
    required this.overallPercentage,
    required this.lectureRecords,
    required this.subjectStats,
    required this.monthlySummary,
  });

  final String studentId;
  final String admissionNumber;
  final String? studentName;
  final double overallPercentage;
  final List<AttendanceModel> lectureRecords;
  final List<SubjectAttendanceStat> subjectStats;
  final List<MonthlyAttendanceSummary> monthlySummary;

  factory StudentDetailAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return StudentDetailAttendanceResponse(
      studentId: json['student_id'] as String,
      admissionNumber: json['admission_number'] as String,
      studentName: json['student_name'] as String?,
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0,
      lectureRecords: (json['lecture_records'] as List<dynamic>? ?? const [])
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectStats: (json['subject_stats'] as List<dynamic>? ?? const [])
          .map((e) => SubjectAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlySummary: (json['monthly_summary'] as List<dynamic>? ?? const [])
          .map((e) =>
              MonthlyAttendanceSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
