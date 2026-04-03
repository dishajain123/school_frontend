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
  });

  final int inserted;
  final int updated;
  final int total;
  final DateTime date;

  factory MarkAttendanceResponse.fromJson(Map<String, dynamic> json) {
    return MarkAttendanceResponse(
      inserted: json['inserted'] as int,
      updated: json['updated'] as int,
      total: json['total'] as int,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
