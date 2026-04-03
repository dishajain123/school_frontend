import 'package:flutter/foundation.dart';

@immutable
class DiaryModel {
  final String id;
  final String topicCovered;
  final String? homeworkNote;
  final DateTime date;
  final String teacherId;
  final String standardId;
  final String subjectId;
  final String academicYearId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DiaryModel({
    required this.id,
    required this.topicCovered,
    this.homeworkNote,
    required this.date,
    required this.teacherId,
    required this.standardId,
    required this.subjectId,
    required this.academicYearId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiaryModel.fromJson(Map<String, dynamic> json) {
    return DiaryModel(
      id: json['id'] as String,
      topicCovered: json['topic_covered'] as String,
      homeworkNote: json['homework_note'] as String?,
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

  DiaryModel copyWith({
    String? id,
    String? topicCovered,
    String? homeworkNote,
    DateTime? date,
    String? teacherId,
    String? standardId,
    String? subjectId,
    String? academicYearId,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryModel(
      id: id ?? this.id,
      topicCovered: topicCovered ?? this.topicCovered,
      homeworkNote: homeworkNote ?? this.homeworkNote,
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
      other is DiaryModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DiaryModel(id: $id, topicCovered: $topicCovered, date: $date)';
}

// ── Paginated list response ───────────────────────────────────────────────────

class DiaryListResponse {
  final List<DiaryModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  const DiaryListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory DiaryListResponse.fromJson(Map<String, dynamic> json) {
    return DiaryListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => DiaryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
    );
  }

  DiaryListResponse copyWith({
    List<DiaryModel>? items,
    int? total,
    int? page,
    int? pageSize,
    int? totalPages,
  }) {
    return DiaryListResponse(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}