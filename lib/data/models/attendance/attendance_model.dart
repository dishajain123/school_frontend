import '../../models/masters/subject_model.dart';

enum AttendanceStatus { present, absent, late }

extension AttendanceStatusX on AttendanceStatus {
  String get backendValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'PRESENT';
      case AttendanceStatus.absent:
        return 'ABSENT';
      case AttendanceStatus.late:
        return 'LATE';
    }
  }

  static AttendanceStatus fromString(String v) {
    switch (v.toUpperCase()) {
      case 'PRESENT':
        return AttendanceStatus.present;
      case 'ABSENT':
        return AttendanceStatus.absent;
      case 'LATE':
        return AttendanceStatus.late;
      default:
        return AttendanceStatus.absent;
    }
  }
}

class AttendanceModel {
  const AttendanceModel({
    required this.id,
    required this.studentId,
    required this.teacherId,
    required this.standardId,
    required this.subjectId,
    required this.academicYearId,
    required this.date,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String studentId;
  final String teacherId;
  final String standardId;
  final String subjectId;
  final String academicYearId;
  final DateTime date;
  final AttendanceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      teacherId: json['teacher_id'] as String,
      standardId: json['standard_id'] as String,
      subjectId: json['subject_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: AttendanceStatusX.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}