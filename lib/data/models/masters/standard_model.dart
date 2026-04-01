class StandardModel {
  const StandardModel({
    required this.id,
    required this.name,
    required this.level,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearId,
  });

  final String id;
  final String name;
  final int level;
  final String schoolId;
  final String? academicYearId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StandardModel.fromJson(Map<String, dynamic> json) {
    return StandardModel(
      id: json['id'] as String,
      name: json['name'] as String,
      level: json['level'] as int,
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'level': level,
        'school_id': schoolId,
        'academic_year_id': academicYearId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  StandardModel copyWith({
    String? id,
    String? name,
    int? level,
    String? schoolId,
    String? academicYearId,
  }) {
    return StandardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      schoolId: schoolId ?? this.schoolId,
      academicYearId: academicYearId ?? this.academicYearId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get displayName => '$name (Level $level)';
}