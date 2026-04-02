import 'attendance_record_input.dart';

class MarkAttendanceRequest {
  const MarkAttendanceRequest({
    required this.standardId,
    required this.subjectId,
    required this.academicYearId,
    required this.date,
    required this.records,
  });

  final String standardId;
  final String subjectId;
  final String academicYearId;
  final DateTime date;
  final List<AttendanceRecordInput> records;

  Map<String, dynamic> toJson() => {
        'standard_id': standardId,
        'subject_id': subjectId,
        'academic_year_id': academicYearId,
        'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        'records': records.map((r) => r.toJson()).toList(),
      };
}