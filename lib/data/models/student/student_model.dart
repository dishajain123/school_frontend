import '../auth/current_user.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.schoolId,
    required this.parentId,
    required this.admissionNumber,
    required this.isPromoted,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
    this.studentName,
    this.standardId,
    this.academicYearId,
    this.section,
    this.rollNumber,
    this.dateOfBirth,
    this.admissionDate,
    this.email,
    this.phone,
    this.standardName,
    this.academicYearName,
    this.user,
  });

  final String id;
  final String? userId;
  final String? studentName;
  final String schoolId;
  final String parentId;
  final String? standardId;
  final String? academicYearId;
  final String? section;
  final String? rollNumber;
  final String admissionNumber;
  final DateTime? dateOfBirth;
  final DateTime? admissionDate;
  final String? email;
  final String? phone;
  final String? standardName;
  final String? academicYearName;
  final CurrentUser? user;
  final bool isPromoted;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return StudentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      studentName: json['student_name'] as String?,
      schoolId: json['school_id'] as String,
      parentId: json['parent_id'] as String,
      standardId: json['standard_id'] as String?,
      academicYearId: json['academic_year_id'] as String?,
      section: json['section'] as String?,
      rollNumber: json['roll_number'] as String?,
      admissionNumber: json['admission_number'] as String,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      admissionDate: json['admission_date'] != null
          ? DateTime.tryParse(json['admission_date'] as String)
          : null,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      standardName: json['standard_name'] as String?,
      academicYearName: json['academic_year_name'] as String?,
      user: userJson is Map<String, dynamic>
          ? CurrentUser.fromJson(userJson)
          : null,
      isPromoted: json['is_promoted'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'student_name': studentName,
        'school_id': schoolId,
        'parent_id': parentId,
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        'section': section,
        'roll_number': rollNumber,
        'admission_number': admissionNumber,
        'date_of_birth': dateOfBirth?.toIso8601String(),
        'admission_date': admissionDate?.toIso8601String(),
        'email': email,
        'phone': phone,
        'standard_name': standardName,
        'academic_year_name': academicYearName,
        'user': user?.toJson(),
        'is_promoted': isPromoted,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  String get displayName {
    final name = studentName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return admissionNumber;
  }

  String get initials {
    final code = admissionNumber.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (code.length >= 2) return code.substring(0, 2).toUpperCase();
    if (code.length == 1) return code.toUpperCase();
    return 'ST';
  }

  StudentModel copyWith({
    String? userId,
    String? studentName,
    String? standardId,
    String? academicYearId,
    String? section,
    String? rollNumber,
    DateTime? dateOfBirth,
    DateTime? admissionDate,
    bool? isPromoted,
  }) {
    return StudentModel(
      id: id,
      userId: userId ?? this.userId,
      studentName: studentName ?? this.studentName,
      schoolId: schoolId,
      parentId: parentId,
      standardId: standardId ?? this.standardId,
      academicYearId: academicYearId ?? this.academicYearId,
      section: section ?? this.section,
      rollNumber: rollNumber ?? this.rollNumber,
      admissionNumber: admissionNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      admissionDate: admissionDate ?? this.admissionDate,
      isPromoted: isPromoted ?? this.isPromoted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
