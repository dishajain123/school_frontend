import 'package:flutter/foundation.dart';
import '../../../core/utils/media_url_resolver.dart';

enum ExamType {
  unitTest,
  midTerm,
  finalExam,
  quarterly,
  halfYearly,
  annual,
  other,
}

extension ExamTypeX on ExamType {
  static ExamType fromString(String? v) {
    switch ((v ?? '').toUpperCase().replaceAll('-', '_')) {
      case 'UNIT_TEST':
      case 'UNIT':
        return ExamType.unitTest;
      case 'MID_TERM':
      case 'MIDTERM':
        return ExamType.midTerm;
      case 'FINAL_EXAM':
      case 'FINAL':
        return ExamType.finalExam;
      case 'QUARTERLY':
        return ExamType.quarterly;
      case 'HALF_YEARLY':
        return ExamType.halfYearly;
      case 'ANNUAL':
        return ExamType.annual;
      default:
        return ExamType.other;
    }
  }

  String get backendValue {
    switch (this) {
      case ExamType.unitTest:
        return 'UNIT';
      case ExamType.midTerm:
        return 'MIDTERM';
      case ExamType.finalExam:
        return 'FINAL';
      case ExamType.quarterly:
        return 'QUARTERLY';
      case ExamType.halfYearly:
        return 'HALF_YEARLY';
      case ExamType.annual:
        return 'ANNUAL';
      case ExamType.other:
        return 'UNIT';
    }
  }

  String get label {
    switch (this) {
      case ExamType.unitTest:
        return 'Unit Test';
      case ExamType.midTerm:
        return 'Mid Term';
      case ExamType.finalExam:
        return 'Final Exam';
      case ExamType.quarterly:
        return 'Quarterly';
      case ExamType.halfYearly:
        return 'Half Yearly';
      case ExamType.annual:
        return 'Annual';
      case ExamType.other:
        return 'Other';
    }
  }
}

@immutable
class ExamModel {
  const ExamModel({
    required this.id,
    required this.name,
    required this.examType,
    required this.standardId,
    required this.academicYearId,
    required this.startDate,
    required this.endDate,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String name;
  final ExamType examType;
  final String standardId;
  final String academicYearId;
  final DateTime startDate;
  final DateTime endDate;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      examType: ExamTypeX.fromString(json['exam_type'] as String?),
      standardId: json['standard_id'].toString(),
      academicYearId: json['academic_year_id'].toString(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      schoolId: json['school_id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exam_type': examType.backendValue,
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        'start_date': startDate.toIso8601String().split('T').first,
        'end_date': endDate.toIso8601String().split('T').first,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (createdBy != null) 'created_by': createdBy,
      };
}

@immutable
class ResultEntryModel {
  const ResultEntryModel({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.subjectId,
    required this.marksObtained,
    required this.maxMarks,
    required this.percentage,
    required this.isPublished,
    required this.enteredAt,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.gradeId,
    this.enteredBy,
  });

  final String id;
  final String examId;
  final String studentId;
  final String subjectId;
  final double marksObtained;
  final double maxMarks;
  final double percentage;
  final bool isPublished;
  final DateTime enteredAt;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? gradeId;
  final String? enteredBy;

  factory ResultEntryModel.fromJson(Map<String, dynamic> json) {
    return ResultEntryModel(
      id: json['id'].toString(),
      examId: json['exam_id'].toString(),
      studentId: json['student_id'].toString(),
      subjectId: json['subject_id'].toString(),
      marksObtained: (json['marks_obtained'] as num).toDouble(),
      maxMarks: (json['max_marks'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      isPublished: json['is_published'] as bool? ?? false,
      enteredAt: DateTime.parse(json['entered_at'] as String),
      schoolId: json['school_id'].toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      gradeId: json['grade_id']?.toString(),
      enteredBy: json['entered_by']?.toString(),
    );
  }

  ResultEntryModel copyWith({bool? isPublished}) {
    return ResultEntryModel(
      id: id,
      examId: examId,
      studentId: studentId,
      subjectId: subjectId,
      marksObtained: marksObtained,
      maxMarks: maxMarks,
      percentage: percentage,
      isPublished: isPublished ?? this.isPublished,
      enteredAt: enteredAt,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      gradeId: gradeId,
      enteredBy: enteredBy,
    );
  }
}

class ResultListResponse {
  const ResultListResponse({
    required this.items,
    required this.total,
    this.reportCardUrl,
    this.hasReportCard = false,
  });

  final List<ResultEntryModel> items;
  final int total;
  final String? reportCardUrl;
  final bool hasReportCard;

  factory ResultListResponse.fromJson(Map<String, dynamic> json) {
    return ResultListResponse(
      items: (json['items'] as List<dynamic>)
          .map((e) => ResultEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      reportCardUrl:
          MediaUrlResolver.resolveNullable(json['report_card_url'] as String?),
      hasReportCard: json['has_report_card'] as bool? ?? false,
    );
  }
}

class ReportCardModel {
  const ReportCardModel({required this.url});

  final String url;

  factory ReportCardModel.fromJson(Map<String, dynamic> json) {
    return ReportCardModel(
      url: MediaUrlResolver.resolve((json['url'] as String?) ?? ''),
    );
  }
}

@immutable
class ResultDistributionSubjectModel {
  const ResultDistributionSubjectModel({
    required this.subjectId,
    required this.subjectName,
    required this.marksObtained,
    required this.maxMarks,
    required this.percentage,
    required this.isPublished,
    this.gradeLetter,
  });

  final String subjectId;
  final String subjectName;
  final double marksObtained;
  final double maxMarks;
  final double percentage;
  final bool isPublished;
  final String? gradeLetter;

  factory ResultDistributionSubjectModel.fromJson(Map<String, dynamic> json) {
    return ResultDistributionSubjectModel(
      subjectId: json['subject_id'].toString(),
      subjectName: (json['subject_name'] as String?) ?? 'Subject',
      marksObtained: (json['marks_obtained'] as num).toDouble(),
      maxMarks: (json['max_marks'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      isPublished: json['is_published'] as bool? ?? false,
      gradeLetter: json['grade_letter'] as String?,
    );
  }
}

@immutable
class ResultDistributionStudentModel {
  const ResultDistributionStudentModel({
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
    required this.totalObtained,
    required this.totalMax,
    required this.overallPercentage,
    required this.subjects,
    this.section,
    this.rollNumber,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;
  final String? section;
  final String? rollNumber;
  final double totalObtained;
  final double totalMax;
  final double overallPercentage;
  final List<ResultDistributionSubjectModel> subjects;

  factory ResultDistributionStudentModel.fromJson(Map<String, dynamic> json) {
    final rawSubjects = json['subjects'] as List<dynamic>? ?? const [];
    return ResultDistributionStudentModel(
      studentId: json['student_id'].toString(),
      studentName: (json['student_name'] as String?) ?? 'Student',
      admissionNumber: (json['admission_number'] as String?) ?? '',
      section: json['section'] as String?,
      rollNumber: json['roll_number'] as String?,
      totalObtained: (json['total_obtained'] as num).toDouble(),
      totalMax: (json['total_max'] as num).toDouble(),
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
      subjects: rawSubjects
          .map((e) => ResultDistributionSubjectModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class ResultDistributionModel {
  const ResultDistributionModel({
    required this.exam,
    required this.totalStudents,
    required this.items,
  });

  final ExamModel exam;
  final int totalStudents;
  final List<ResultDistributionStudentModel> items;

  factory ResultDistributionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return ResultDistributionModel(
      exam: ExamModel.fromJson(json['exam'] as Map<String, dynamic>),
      totalStudents: json['total_students'] as int? ?? rawItems.length,
      items: rawItems
          .map((e) => ResultDistributionStudentModel.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }
}

@immutable
class ExamBulkCreateResponseModel {
  const ExamBulkCreateResponseModel({
    required this.created,
    required this.createdCount,
    required this.skippedCount,
  });

  final List<ExamModel> created;
  final int createdCount;
  final int skippedCount;

  factory ExamBulkCreateResponseModel.fromJson(Map<String, dynamic> json) {
    final rawCreated = json['created'] as List<dynamic>? ?? const [];
    return ExamBulkCreateResponseModel(
      created: rawCreated
          .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdCount: json['created_count'] as int? ?? rawCreated.length,
      skippedCount: json['skipped_count'] as int? ?? 0,
    );
  }
}
