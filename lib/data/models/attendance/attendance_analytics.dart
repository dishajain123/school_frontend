class SubjectAttendanceStat {
  const SubjectAttendanceStat({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.totalClasses,
    required this.present,
    required this.absent,
    required this.late,
    required this.percentage,
  });

  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final int totalClasses;
  final int present;
  final int absent;
  final int late;
  final double percentage;

  factory SubjectAttendanceStat.fromJson(Map<String, dynamic> json) {
    return SubjectAttendanceStat(
      subjectId: json['subject_id'] as String,
      subjectName: json['subject_name'] as String,
      subjectCode: json['subject_code'] as String,
      totalClasses: json['total_classes'] as int,
      present: json['present'] as int,
      absent: json['absent'] as int,
      late: json['late'] as int,
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}

class StudentAttendanceAnalytics {
  const StudentAttendanceAnalytics({
    required this.studentId,
    required this.month,
    required this.year,
    required this.overallPercentage,
    required this.subjects,
  });

  final String studentId;
  final int? month;
  final int? year;
  final double overallPercentage;
  final List<SubjectAttendanceStat> subjects;

  factory StudentAttendanceAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentAttendanceAnalytics(
      studentId: json['student_id'] as String,
      month: json['month'] as int?,
      year: json['year'] as int?,
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
      subjects: (json['subjects'] as List)
          .map((e) => SubjectAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}