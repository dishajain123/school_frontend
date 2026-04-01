class GradeMasterModel {
  const GradeMasterModel({
    required this.id,
    required this.gradeLetter,
    required this.gradePoint,
    required this.minPercent,
    required this.maxPercent,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String gradeLetter;
  final double gradePoint;
  final double minPercent;
  final double maxPercent;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory GradeMasterModel.fromJson(Map<String, dynamic> json) {
    return GradeMasterModel(
      id: json['id'] as String,
      gradeLetter: json['grade_letter'] as String,
      gradePoint: (json['grade_point'] as num).toDouble(),
      minPercent: (json['min_percent'] as num).toDouble(),
      maxPercent: (json['max_percent'] as num).toDouble(),
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'grade_letter': gradeLetter,
        'grade_point': gradePoint,
        'min_percent': minPercent,
        'max_percent': maxPercent,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  GradeMasterModel copyWith({
    String? gradeLetter,
    double? gradePoint,
    double? minPercent,
    double? maxPercent,
  }) {
    return GradeMasterModel(
      id: id,
      gradeLetter: gradeLetter ?? this.gradeLetter,
      gradePoint: gradePoint ?? this.gradePoint,
      minPercent: minPercent ?? this.minPercent,
      maxPercent: maxPercent ?? this.maxPercent,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get range => '${minPercent.toStringAsFixed(0)}% – ${maxPercent.toStringAsFixed(0)}%';
}