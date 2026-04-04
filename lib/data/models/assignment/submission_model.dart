import 'package:flutter/foundation.dart';

@immutable
class SubmissionModel {
  final String id;
  final String assignmentId;
  final String studentId;
  final String performedBy;
  final DateTime submittedAt;
  final String? fileKey;
  final String? fileUrl;
  final String? textResponse;
  final String? grade;
  final String? feedback;
  final bool isGraded;
  final bool isApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? studentAdmissionNumber;
  final String? studentRollNumber;
  final String? studentSection;
  final bool isLate;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SubmissionModel({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.performedBy,
    required this.submittedAt,
    this.fileKey,
    this.fileUrl,
    this.textResponse,
    this.grade,
    this.feedback,
    required this.isGraded,
    required this.isApproved,
    this.approvedBy,
    this.approvedAt,
    this.studentAdmissionNumber,
    this.studentRollNumber,
    this.studentSection,
    required this.isLate,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubmissionModel.fromJson(Map<String, dynamic> json) {
    return SubmissionModel(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      studentId: json['student_id'] as String,
      performedBy: json['performed_by'] as String,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      fileKey: json['file_key'] as String?,
      fileUrl: json['file_url'] as String?,
      textResponse: json['text_response'] as String?,
      grade: json['grade'] as String?,
      feedback: json['feedback'] as String?,
      isGraded: json['is_graded'] as bool,
      isApproved: json['is_approved'] as bool? ?? false,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      studentAdmissionNumber: json['student_admission_number'] as String?,
      studentRollNumber: json['student_roll_number'] as String?,
      studentSection: json['student_section'] as String?,
      isLate: json['is_late'] as bool,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  SubmissionModel copyWith({
    String? id,
    String? assignmentId,
    String? studentId,
    String? performedBy,
    DateTime? submittedAt,
    String? fileKey,
    String? fileUrl,
    String? textResponse,
    String? grade,
    String? feedback,
    bool? isGraded,
    bool? isApproved,
    String? approvedBy,
    DateTime? approvedAt,
    String? studentAdmissionNumber,
    String? studentRollNumber,
    String? studentSection,
    bool? isLate,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentId: studentId ?? this.studentId,
      performedBy: performedBy ?? this.performedBy,
      submittedAt: submittedAt ?? this.submittedAt,
      fileKey: fileKey ?? this.fileKey,
      fileUrl: fileUrl ?? this.fileUrl,
      textResponse: textResponse ?? this.textResponse,
      grade: grade ?? this.grade,
      feedback: feedback ?? this.feedback,
      isGraded: isGraded ?? this.isGraded,
      isApproved: isApproved ?? this.isApproved,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      studentAdmissionNumber:
          studentAdmissionNumber ?? this.studentAdmissionNumber,
      studentRollNumber: studentRollNumber ?? this.studentRollNumber,
      studentSection: studentSection ?? this.studentSection,
      isLate: isLate ?? this.isLate,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SubmissionListResponse {
  final List<SubmissionModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const SubmissionListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory SubmissionListResponse.fromJson(Map<String, dynamic> json) {
    return SubmissionListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => SubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}
