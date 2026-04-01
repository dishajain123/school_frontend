import '../../models/auth/current_user.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    required this.schoolId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.profilePhotoKey,
    this.profilePhotoUrl,
  });

  final String id;
  final String? email;
  final String? phone;
  final UserRole role;
  final String? schoolId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? profilePhotoKey;
  final String? profilePhotoUrl;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: UserRoleX.fromBackend(json['role'] as String?),
      schoolId: (json['school_id'] ?? json['schoolId']) as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      profilePhotoKey: json['profile_photo_key'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  UserModel copyWith({
    String? phone,
    String? profilePhotoKey,
    String? profilePhotoUrl,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      schoolId: schoolId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
      profilePhotoKey: profilePhotoKey ?? this.profilePhotoKey,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }
}