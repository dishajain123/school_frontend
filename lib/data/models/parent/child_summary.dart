class ChildSummaryModel {
  const ChildSummaryModel({
    required this.id,
    required this.admissionNumber,
    required this.isPromoted,
    this.section,
    this.rollNumber,
    this.dateOfBirth,
    this.admissionDate,
    this.academicYearId,
    this.standardId,
    this.userId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? userId;
  final String admissionNumber;
  final String? section;
  final String? rollNumber;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final bool isPromoted;
  final String? academicYearId;
  final String? standardId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChildSummaryModel.fromJson(Map<String, dynamic> json) {
    return ChildSummaryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      admissionNumber: json['admission_number'] as String,
      section: json['section'] as String?,
      rollNumber: json['roll_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      admissionDate: json['admission_date'] != null
          ? DateTime.tryParse(json['admission_date'] as String)
          : null,
      isPromoted: json['is_promoted'] as bool? ?? false,
      academicYearId: json['academic_year_id'] as String?,
      standardId: json['standard_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  String get initials {
    final code = admissionNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (code.length >= 2) return code.substring(0, 2).toUpperCase();
    if (code.length == 1) return code.toUpperCase();
    return 'ST';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'admission_number': admissionNumber,
        'section': section,
        'roll_number': rollNumber,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'admission_date': admissionDate?.toIso8601String(),
        'is_promoted': isPromoted,
        'academic_year_id': academicYearId,
        'standard_id': standardId,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}
