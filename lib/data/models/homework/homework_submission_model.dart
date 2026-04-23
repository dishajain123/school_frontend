import 'package:flutter/foundation.dart';

@immutable
class HomeworkSubmissionModel {
  const HomeworkSubmissionModel({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    required this.performedBy,
    required this.textResponse,
    required this.fileKey,
    required this.fileUrl,
    required this.feedback,
    required this.isReviewed,
    required this.isApproved,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.schoolId,
    required this.studentAdmissionNumber,
    required this.studentName,
    required this.performerName,
    required this.reviewerName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String homeworkId;
  final String studentId;
  final String performedBy;
  final String textResponse;
  final String? fileKey;
  final String? fileUrl;
  final String? feedback;
  final bool isReviewed;
  final bool isApproved;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String schoolId;
  final String? studentAdmissionNumber;
  final String? studentName;
  final String? performerName;
  final String? reviewerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory HomeworkSubmissionModel.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmissionModel(
      id: json['id'] as String,
      homeworkId: json['homework_id'] as String,
      studentId: json['student_id'] as String,
      performedBy: json['performed_by'] as String,
      textResponse: json['text_response'] as String? ?? '',
      fileKey: json['file_key'] as String?,
      fileUrl: json['file_url'] as String?,
      feedback: json['feedback'] as String?,
      isReviewed: json['is_reviewed'] as bool? ?? false,
      isApproved: json['is_approved'] as bool? ?? false,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String).toLocal()
          : null,
      schoolId: json['school_id'] as String,
      studentAdmissionNumber: json['student_admission_number'] as String?,
      studentName: json['student_name'] as String?,
      performerName: json['performer_name'] as String?,
      reviewerName: json['reviewer_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}

@immutable
class HomeworkSubmissionListResponse {
  const HomeworkSubmissionListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<HomeworkSubmissionModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory HomeworkSubmissionListResponse.fromJson(Map<String, dynamic> json) {
    return HomeworkSubmissionListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) =>
              HomeworkSubmissionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}
