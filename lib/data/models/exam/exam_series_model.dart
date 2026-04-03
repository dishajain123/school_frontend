import 'package:flutter/foundation.dart';

@immutable
class ExamSeriesModel {
  const ExamSeriesModel({
    required this.id,
    required this.name,
    required this.standardId,
    required this.academicYearId,
    required this.isPublished,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String name;
  final String standardId;
  final String academicYearId;
  final bool isPublished;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  factory ExamSeriesModel.fromJson(Map<String, dynamic> json) {
    return ExamSeriesModel(
      id: json['id'] as String,
      name: json['name'] as String,
      standardId: json['standard_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      isPublished: json['is_published'] as bool,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        'is_published': isPublished,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
      };

  ExamSeriesModel copyWith({
    String? id,
    String? name,
    String? standardId,
    String? academicYearId,
    bool? isPublished,
    String? schoolId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return ExamSeriesModel(
      id: id ?? this.id,
      name: name ?? this.name,
      standardId: standardId ?? this.standardId,
      academicYearId: academicYearId ?? this.academicYearId,
      isPublished: isPublished ?? this.isPublished,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}