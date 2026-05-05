class TimetableModel {
  const TimetableModel({
    required this.id,
    required this.standardId,
    this.examId,
    this.section,
    required this.academicYearId,
    required this.fileKey,
    this.fileUrl,
    this.effectiveFrom,
    this.effectiveTo,
    this.uploadedBy,
    this.uploadedByName,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String standardId;
  final String? examId;
  final String? section;
  final String academicYearId;
  final String fileKey;
  final String? fileUrl;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? uploadedBy;
  final String? uploadedByName;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String,
      standardId: json['standard_id'] as String,
      examId: json['exam_id'] as String?,
      section: json['section'] as String?,
      academicYearId: json['academic_year_id'] as String,
      fileKey: json['file_key'] as String,
      fileUrl: json['file_url'] as String?,
      effectiveFrom: json['effective_from'] != null
          ? DateTime.tryParse(json['effective_from'] as String)
          : null,
      effectiveTo: json['effective_to'] != null
          ? DateTime.tryParse(json['effective_to'] as String)
          : null,
      uploadedBy: json['uploaded_by'] as String?,
      uploadedByName: json['uploaded_by_name'] as String?,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  bool get isPdf => fileKey.toLowerCase().endsWith('.pdf');

  bool get isImage {
    final lower = fileKey.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  /// Extracts the original filename from the stored key (format: uuid_filename).
  String get fileName {
    final parts = fileKey.split('/');
    final last = parts.isEmpty ? fileKey : parts.last;
    final idx = last.indexOf('_');
    return (idx != -1 && idx < last.length - 1)
        ? last.substring(idx + 1)
        : last;
  }
}
