import 'package:flutter/foundation.dart';

@immutable
class AssignmentModel {
  final String id;
  final String title;
  final String? description;
  final String teacherId;
  final String standardId;
  final String subjectId;
  final DateTime dueDate;
  final String? fileKey;
  final String? fileUrl;
  final bool isActive;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssignmentModel({
    required this.id,
    required this.title,
    this.description,
    required this.teacherId,
    required this.standardId,
    required this.subjectId,
    required this.dueDate,
    this.fileKey,
    this.fileUrl,
    required this.isActive,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    final today = DateTime.now();
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final todayDate = DateTime(today.year, today.month, today.day);
    return todayDate.isAfter(due);
  }

  bool get isDueToday {
    final today = DateTime.now();
    return dueDate.year == today.year &&
        dueDate.month == today.month &&
        dueDate.day == today.day;
  }

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      teacherId: json['teacher_id'] as String,
      standardId: json['standard_id'] as String,
      subjectId: json['subject_id'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      fileKey: json['file_key'] as String?,
      fileUrl: json['file_url'] as String?,
      isActive: json['is_active'] as bool,
      academicYearId: json['academic_year_id'] as String,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  AssignmentModel copyWith({
    String? id,
    String? title,
    String? description,
    String? teacherId,
    String? standardId,
    String? subjectId,
    DateTime? dueDate,
    String? fileKey,
    String? fileUrl,
    bool? isActive,
    String? academicYearId,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssignmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      teacherId: teacherId ?? this.teacherId,
      standardId: standardId ?? this.standardId,
      subjectId: subjectId ?? this.subjectId,
      dueDate: dueDate ?? this.dueDate,
      fileKey: fileKey ?? this.fileKey,
      fileUrl: fileUrl ?? this.fileUrl,
      isActive: isActive ?? this.isActive,
      academicYearId: academicYearId ?? this.academicYearId,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class AssignmentListResponse {
  final List<AssignmentModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const AssignmentListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory AssignmentListResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => AssignmentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}