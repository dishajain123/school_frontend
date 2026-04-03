import 'attendance_record_input.dart';

class MarkAttendanceRequest {
  const MarkAttendanceRequest({
    required this.standardId,
    required this.section,
    required this.subjectId,
    required this.academicYearId,
    required this.lectureNumber,
    required this.date,
    required this.records,
  });

  final String standardId;
  final String section;
  final String subjectId;
  final String academicYearId;
  final int lectureNumber;
  final DateTime date;
  final List<AttendanceRecordInput> records;

  Map<String, dynamic> toJson() => {
        'standard_id': standardId,
        'section': section,
        'subject_id': subjectId,
        'academic_year_id': academicYearId,
        'lecture_number': lectureNumber,
        'date': _formatDate(date),
        'records': records.map((r) => r.toJson()).toList(),
      };

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

class MarkAttendanceResponse {
  const MarkAttendanceResponse({
    required this.inserted,
    required this.updated,
    required this.total,
    required this.date,
    required this.lectureNumber,
  });

  final int inserted;
  final int updated;
  final int total;
  final DateTime date;
  final int lectureNumber;

  factory MarkAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return MarkAttendanceResponse(
      inserted: json['inserted'] as int,
      updated: json['updated'] as int,
      total: json['total'] as int,
      date: DateTime.parse(json['date'] as String),
      lectureNumber: json['lecture_number'] as int? ?? 1,
    );
  }
}
