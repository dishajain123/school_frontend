class SubjectModel {
  const SubjectModel({
    required this.id,
    required this.name,
    required this.code,
    required this.standardId,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? standardId;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      standardId: json['standard_id'] as String?,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'standard_id': standardId,
        'school_id': schoolId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  SubjectModel copyWith({
    String? name,
    String? code,
    String? standardId,
  }) {
    return SubjectModel(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      standardId: standardId ?? this.standardId,
      schoolId: schoolId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
