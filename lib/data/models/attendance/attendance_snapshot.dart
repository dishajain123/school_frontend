import 'attendance_model.dart';

class ClassSnapshotRecord {
  const ClassSnapshotRecord({
    required this.studentId,
    required this.admissionNumber,
    required this.section,
    this.status,
  });

  final String studentId;
  final String admissionNumber;
  final String section;
  final AttendanceStatus? status;

  factory ClassSnapshotRecord.fromJson(Map<String, dynamic> json) {
    return ClassSnapshotRecord(
      studentId: json['student_id'] as String,
      admissionNumber: json['admission_number'] as String,
      section: json['section'] as String? ?? '',
      status: json['status'] != null
          ? AttendanceStatusX.fromString(json['status'] as String)
          : null,
    );
  }
}

class ClassAttendanceSnapshot {
  const ClassAttendanceSnapshot({
    required this.standardId,
    required this.date,
    required this.totalStudents,
    required this.present,
    required this.absent,
    required this.late,
    required this.notMarked,
    required this.records,
  });

  final String standardId;
  final DateTime date;
  final int totalStudents;
  final int present;
  final int absent;
  final int late;
  final int notMarked;
  final List<ClassSnapshotRecord> records;

  double get presentPercentage =>
      totalStudents > 0 ? (present / totalStudents) * 100 : 0.0;

  factory ClassAttendanceSnapshot.fromJson(Map<String, dynamic> json) {
    return ClassAttendanceSnapshot(
      standardId: json['standard_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalStudents: json['total_students'] as int,
      present: json['present'] as int,
      absent: json['absent'] as int,
      late: json['late'] as int,
      notMarked: json['not_marked'] as int,
      records: (json['records'] as List)
          .map((e) => ClassSnapshotRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}