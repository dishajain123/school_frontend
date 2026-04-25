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
      standardName: json['standard_name'] as String? ?? '',
      section: json['section'] as String? ?? '',
      totalRecords: json['total_records'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
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
      subjectName: json['subject_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      totalRecords: json['total_records'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AbsenteeEntry {
  const AbsenteeEntry({
    required this.studentId,
    required this.admissionNumber,
    required this.studentName,
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
      admissionNumber: json['admission_number'] as String? ?? '',
      studentName: json['student_name'] as String?,
      standardId: json['standard_id'] as String? ?? '',
      standardName: json['standard_name'] as String? ?? '',
      section: json['section'] as String? ?? '',
      totalClasses: json['total_classes'] as int? ?? 0,
      absences: json['absences'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
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
      periodLabel: json['period_label'] as String? ?? '',
      periodYear: json['period_year'] as int? ?? 0,
      periodValue: json['period_value'] as int? ?? 0,
      totalRecords: json['total_records'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
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
      overallPercentage: (json['overall_percentage'] as num?)?.toDouble() ?? 0,
      totalRecords: json['total_records'] as int? ?? 0,
      present: json['present'] as int? ?? 0,
      absent: json['absent'] as int? ?? 0,
      late: json['late'] as int? ?? 0,
      classStats: (json['class_stats'] as List<dynamic>? ?? const [])
          .map((e) => ClassAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      subjectStats: (json['subject_stats'] as List<dynamic>? ?? const [])
          .map((e) =>
              SubjectSchoolAttendanceStat.fromJson(e as Map<String, dynamic>))
          .toList(),
      topAbsentees: (json['top_absentees'] as List<dynamic>? ?? const [])
          .map((e) => AbsenteeEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      weeklyTrend: (json['weekly_trend'] as List<dynamic>? ?? const [])
          .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyTrend: (json['monthly_trend'] as List<dynamic>? ?? const [])
          .map((e) => AttendanceTrendItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

typedef AttendanceClassStat = ClassAttendanceStat;
typedef AttendanceSubjectStat = SubjectSchoolAttendanceStat;
