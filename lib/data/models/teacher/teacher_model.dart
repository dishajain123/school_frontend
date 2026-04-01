import '../auth/current_user.dart';

class TeacherUserModel {
  const TeacherUserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.isActive,
    this.profilePhotoKey,
    this.profilePhotoUrl,
  });

  final String id;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? profilePhotoKey;
  final String? profilePhotoUrl;

  factory TeacherUserModel.fromJson(Map<String, dynamic> json) {
    return TeacherUserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profilePhotoKey: json['profile_photo_key'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  String get displayName {
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first.replaceAll('.', ' ').split(' ').map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
    }
    return phone ?? 'Unknown';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class TeacherModel {
  const TeacherModel({
    required this.id,
    required this.schoolId,
    required this.employeeCode,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    this.academicYearId,
    this.joinDate,
    this.specialization,
  });

  final String id;
  final String schoolId;
  final String? academicYearId;
  final String employeeCode;
  final DateTime? joinDate;
  final String? specialization;
  final TeacherUserModel user;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String?,
      employeeCode: json['employee_code'] as String,
      joinDate: json['join_date'] != null
          ? DateTime.tryParse(json['join_date'] as String)
          : null,
      specialization: json['specialization'] as String?,
      user: TeacherUserModel.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  String get displayName => user.displayName;
  String get initials => user.initials;
  String? get email => user.email;
  String? get phone => user.phone;
  bool get isActive => user.isActive;
  String? get profilePhotoUrl => user.profilePhotoUrl;

  TeacherModel copyWith({
    String? employeeCode,
    DateTime? joinDate,
    String? specialization,
    String? academicYearId,
  }) {
    return TeacherModel(
      id: id,
      schoolId: schoolId,
      academicYearId: academicYearId ?? this.academicYearId,
      employeeCode: employeeCode ?? this.employeeCode,
      joinDate: joinDate ?? this.joinDate,
      specialization: specialization ?? this.specialization,
      user: user,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}