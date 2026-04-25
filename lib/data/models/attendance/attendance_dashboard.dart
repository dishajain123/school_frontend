import 'attendance_model.dart';
import 'attendance_analytics.dart';

// ── Lecture Snapshot ──────────────────────────────────────────────────────────

class LectureStudentEntry {
  const LectureStudentEntry({
    required this.studentId,
    required this.admissionNumber,
    this.studentName,
    this.rollNumber,
    required this.status,
    this.attendanceId,
  });

  final String studentId;
  final String admissionNumber;
  final String? studentName;
  final String? rollNumber;
  final AttendanceStatus status;
  final String? attendanceId;

  factory LectureStudentEntry.fromJson(Map<String, dynamic> json) {
    return LectureStudentEntry(
      studentId: json['student_id'] as String,
      admissionNumber: json['admission_number'] as String,
      studentName: json['student_name'] as String?,
      rollNumber: json['roll_number'] as String?,
      status: AttendanceStatusX.fromString(json['status'] as String? ?? 'ABSENT'),
      attendanceId: json['attendance_id'] as String?,
    );
  }
}

class LectureAttendanceResponse {
  const LectureAttendanceResponse({
    required this.standardId,
    required this.section,
    required this.subjectId,
    required this.academicYearId,
    required this.date,
    required this.lectureNumber,
    required this.totalStudents,
    required this.presentCount,
    required this.absentCount,
    required this.lateCount,
    required this.entries,
  });

  final String standardId;
  final String section;
  final String subjectId;
  final String academicYearId;
  final DateTime date;
  final int lectureNumber;
  final int totalStudents;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final List<LectureStudentEntry> entries;

  factory LectureAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return LectureAttendanceResponse(
      standardId: json['standard_id'] as String,
      section: json['section'] as String,
      subjectId: json['subject_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      date: DateTime.parse(json['date'] as String),
      lectureNumber: json['lecture_number'] as int,
      totalStudents: json['total_students'] as int,
      presentCount: json['present_count'] as int,
      absentCount: json['absent_count'] as int,
      lateCount: json['late_count'] as int,
      entries: (json['entries'] as List)
          .map((e) => LectureStudentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Monthly Summary ───────────────────────────────────────────────────────────

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
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      totalClasses: (json['total_classes'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      late: (json['late'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

// ── Student Detail Response ───────────────────────────────────────────────────

class StudentDetailAttendanceResponse {
  const StudentDetailAttendanceResponse({
    required this.studentId,
    required this.admissionNumber,
    this.studentName,
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
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
      lectureRecords: (json['lecture_records'] as List)
          .map((e) => AttendanceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectStats: (json['subject_stats'] as List)
          .map((e) => SubjectAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlySummary: (json['monthly_summary'] as List)
          .map((e) => MonthlyAttendanceSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Dashboard Analytics ───────────────────────────────────────────────────────

class ClassAttendanceStat {
  const ClassAttendanceStat({
    required this.standardId,
    required this.standardName,
    required this.section,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  final String standardId;
  final String standardName;
  final String section;
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  factory ClassAttendanceStat.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceStat(
      standardId: json['standard_id'] as String,
      standardName: json['standard_name'] as String,
      section: json['section'] as String,
      totalRecords: (json['total_records'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      late: (json['late'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class SubjectSchoolAttendanceStat {
  const SubjectSchoolAttendanceStat({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  factory SubjectSchoolAttendanceStat.fromJson(Map<String, dynamic> json) {
    return SubjectSchoolAttendanceStat(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      totalRecords: (json['total_records'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      late: (json['late'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class AbsenteeEntry {
  const AbsenteeEntry({
    required this.studentId,
    required this.admissionNumber,
    this.studentName,
    required this.standardId,
    required this.standardName,
    required this.section,
    required this.totalClasses,
    required this.absences,
    required this.percentage,
  });

  final String studentId;
  final String admissionNumber;
  final String? studentName;
  final String standardId;
  final String standardName;
  final String section;
  final int totalClasses;
  final int absences;
  final double percentage;

  factory AbsenteeEntry.fromJson(Map<String, dynamic> json) {
    return AbsenteeEntry(
      studentId: json['student_id'] as String,
      admissionNumber: json['admission_number'] as String,
      studentName: json['student_name'] as String?,
      standardId: json['standard_id'] as String,
      standardName: json['standard_name'] as String,
      section: json['section'] as String,
      totalClasses: (json['total_classes'] as num).toInt(),
      absences: (json['absences'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class AttendanceTrendItem {
  const AttendanceTrendItem({
    required this.periodLabel,
    required this.periodYear,
    required this.periodValue,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  final String periodLabel;
  final int periodYear;
  final int periodValue;
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  factory AttendanceTrendItem.fromJson(Map<String, dynamic> json) {
    return AttendanceTrendItem(
      periodLabel: json['period_label'] as String,
      periodYear: (json['period_year'] as num).toInt(),
      periodValue: (json['period_value'] as num).toInt(),
      totalRecords: (json['total_records'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      late: (json['late'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class AttendanceDashboardResponse {
  const AttendanceDashboardResponse({
    required this.schoolId,
    required this.academicYearId,
    required this.overallPercentage,
    required this.totalRecords,
    required this.present,
    required this.absent,
    required this.late,
    required this.classStats,
    required this.subjectStats,
    required this.topAbsentees,
    required this.weeklyTrend,
    required this.monthlyTrend,
  });

  final String schoolId;
  final String academicYearId;
  final double overallPercentage;
  final int totalRecords;
  final int present;
  final int absent;
  final int late;
  final List<ClassAttendanceStat> classStats;
  final List<SubjectSchoolAttendanceStat> subjectStats;
  final List<AbsenteeEntry> topAbsentees;
  final List<AttendanceTrendItem> weeklyTrend;
  final List<AttendanceTrendItem> monthlyTrend;

  factory AttendanceDashboardResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceDashboardResponse(
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
      totalRecords: (json['total_records'] as num).toInt(),
      present: (json['present'] as num).toInt(),
      absent: (json['absent'] as num).toInt(),
      late: (json['late'] as num).toInt(),
      classStats: (json['class_stats'] as List)
          .map((e) => ClassAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectStats: (json['subject_stats'] as List)
          .map((e) =>
              SubjectSchoolAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAbsentees: (json['top_absentees'] as List)
          .map((e) => AbsenteeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyTrend: (json['weekly_trend'] as List)
          .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrend: (json['monthly_trend'] as List)
          .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}