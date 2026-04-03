class BelowThresholdStudent {
  const BelowThresholdStudent({
    required this.studentId,
    required this.admissionNumber,
    required this.section,
    required this.overallPercentage,
  });

  final String studentId;
  final String admissionNumber;
  final String section;
  final double overallPercentage;

  factory BelowThresholdStudent.fromJson(Map<String, dynamic> json) {
    return BelowThresholdStudent(
      studentId: json['student_id'] as String,
      admissionNumber: json['admission_number'] as String,
      section: json['section'] as String? ?? '',
      overallPercentage: (json['overall_percentage'] as num).toDouble(),
    );
  }
}

class BelowThresholdResponse {
  const BelowThresholdResponse({
    required this.standardId,
    required this.threshold,
    required this.academicYearId,
    required this.students,
    required this.total,
  });

  final String standardId;
  final double threshold;
  final String academicYearId;
  final List<BelowThresholdStudent> students;
  final int total;

  factory BelowThresholdResponse.fromJson(Map<String, dynamic> json) {
    return BelowThresholdResponse(
      standardId: json['standard_id'] as String,
      threshold: (json['threshold'] as num).toDouble(),
      academicYearId: json['academic_year_id'] as String,
      students: (json['students'] as List)
          .map((e) =>
              BelowThresholdStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
    );
  }
}