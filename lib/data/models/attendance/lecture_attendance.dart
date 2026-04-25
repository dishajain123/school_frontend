import 'attendance_model.dart';

class LectureStudentEntry {
  const LectureStudentEntry({
    required this.studentId,
    required this.admissionNumber,
    required this.studentName,
    required this.rollNumber,
    required this.status,
    required this.attendanceId,
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
      status:
          AttendanceStatusX.fromString((json['status'] as String?) ?? 'ABSENT'),
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
      section: json['section'] as String? ?? '',
      subjectId: json['subject_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      date: DateTime.parse(json['date'] as String),
      lectureNumber: json['lecture_number'] as int? ?? 1,
      totalStudents: json['total_students'] as int? ?? 0,
      presentCount: json['present_count'] as int? ?? 0,
      absentCount: json['absent_count'] as int? ?? 0,
      lateCount: json['late_count'] as int? ?? 0,
      entries: (json['entries'] as List<dynamic>? ?? const [])
          .map((e) => LectureStudentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
