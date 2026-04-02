import 'attendance_model.dart';

class AttendanceRecordInput {
  AttendanceRecordInput({
    required this.studentId,
    required this.status,
  });

  final String studentId;
  AttendanceStatus status;

  Map<String, dynamic> toJson() => {
        'student_id': studentId,
        'status': status.backendValue,
      };
}