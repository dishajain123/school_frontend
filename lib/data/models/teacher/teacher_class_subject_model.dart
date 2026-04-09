class TeacherClassSubjectModel {
  const TeacherClassSubjectModel({
    required this.id,
    required this.teacherId,
    required this.standardId,
    required this.section,
    required this.subjectId,
    required this.academicYearId,
    this.standardName,
    this.subjectName,
    this.subjectCode,
    this.academicYearName,
    this.teacherEmployeeCode,
  });

  final String id;
  final String teacherId;
  final String standardId;
  final String section;
  final String subjectId;
  final String academicYearId;
  final String? standardName;
  final String? subjectName;
  final String? subjectCode;
  final String? academicYearName;
  final String? teacherEmployeeCode;

  /// Human-readable label for standard+section dropdown
  String get classLabel {
    final name = standardName ?? standardId;
    return section.isNotEmpty ? '$name - $section' : name;
  }

  /// Human-readable label for subject dropdown
  String get subjectLabel {
    if (subjectName != null && subjectCode != null) {
      return '$subjectName ($subjectCode)';
    }
    return subjectName ?? subjectId;
  }

  factory TeacherClassSubjectModel.fromJson(Map<String, dynamic> json) {
    final standard = json['standard'] as Map<String, dynamic>?;
    final subject = json['subject'] as Map<String, dynamic>?;
    final academicYear = json['academic_year'] as Map<String, dynamic>?;
    final teacher = json['teacher'] as Map<String, dynamic>?;

    String idValue(dynamic value) => value?.toString() ?? '';

    return TeacherClassSubjectModel(
      id: idValue(json['id']),
      teacherId: idValue(json['teacher_id'] ?? teacher?['id']),
      standardId: idValue(json['standard_id'] ?? standard?['id']),
      section: json['section'] as String? ?? '',
      subjectId: idValue(json['subject_id'] ?? subject?['id']),
      academicYearId: idValue(json['academic_year_id'] ?? academicYear?['id']),
      standardName: standard?['name'] as String?,
      subjectName: subject?['name'] as String?,
      subjectCode: subject?['code'] as String?,
      academicYearName: academicYear?['name'] as String?,
      teacherEmployeeCode: teacher?['employee_code'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TeacherClassSubjectModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
