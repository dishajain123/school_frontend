import 'package:flutter/foundation.dart';

@immutable
class HomeworkModel {
  final String id;
  final String description;
  final String? fileKey;
  final String? fileUrl;
  final bool? isSubmitted;
  final DateTime date;
  final String teacherId;
  final String standardId;
  final String subjectId;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const HomeworkModel({
    required this.id,
    required this.description,
    this.fileKey,
    this.fileUrl,
    this.isSubmitted,
    required this.date,
    required this.teacherId,
    required this.standardId,
    required this.subjectId,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id'] as String,
      description: json['description'] as String,
      fileKey: json['file_key'] as String?,
      fileUrl: json['file_url'] as String?,
      isSubmitted: json['is_submitted'] as bool?,
      // Backend returns "yyyy-MM-dd" — parse as local date
      date: DateTime.parse(json['date'] as String).toLocal(),
      teacherId: json['teacher_id'] as String,
      standardId: json['standard_id'] as String,
      subjectId: json['subject_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  HomeworkModel copyWith({
    String? id,
    String? description,
    String? fileKey,
    String? fileUrl,
    bool? isSubmitted,
    DateTime? date,
    String? teacherId,
    String? standardId,
    String? subjectId,
    String? academicYearId,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      description: description ?? this.description,
      fileKey: fileKey ?? this.fileKey,
      fileUrl: fileUrl ?? this.fileUrl,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      date: date ?? this.date,
      teacherId: teacherId ?? this.teacherId,
      standardId: standardId ?? this.standardId,
      subjectId: subjectId ?? this.subjectId,
      academicYearId: academicYearId ?? this.academicYearId,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeworkModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HomeworkModel(id: $id, description: $description, date: $date)';
}

// ── Paginated list response ───────────────────────────────────────────────────

class HomeworkListResponse {
  final List<HomeworkModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const HomeworkListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory HomeworkListResponse.fromJson(Map<String, dynamic> json) {
    return HomeworkListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => HomeworkModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  HomeworkListResponse copyWith({
    List<HomeworkModel>? items,
    int? total,
    int? page,
    int? pageSize,
    int? totalPages,
  }) {
    return HomeworkListResponse(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}
