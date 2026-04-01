enum UserRole {
  superadmin,
  principal,
  trustee,
  teacher,
  student,
  parent,
}

extension UserRoleX on UserRole {
  String get backendValue {
    switch (this) {
      case UserRole.superadmin:
        return 'SUPERADMIN';
      case UserRole.principal:
        return 'PRINCIPAL';
      case UserRole.trustee:
        return 'TRUSTEE';
      case UserRole.teacher:
        return 'TEACHER';
      case UserRole.student:
        return 'STUDENT';
      case UserRole.parent:
        return 'PARENT';
    }
  }

  static UserRole fromBackend(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    switch (normalized) {
      case 'SUPERADMIN':
        return UserRole.superadmin;
      case 'PRINCIPAL':
        return UserRole.principal;
      case 'TRUSTEE':
        return UserRole.trustee;
      case 'TEACHER':
        return UserRole.teacher;
      case 'STUDENT':
        return UserRole.student;
      case 'PARENT':
        return UserRole.parent;
      default:
        return UserRole.student;
    }
  }
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.role,
    this.name,
    this.email,
    this.phone,
    this.schoolId,
    this.parentId,
  });

  final String id;
  final UserRole role;
  final String? name;
  final String? email;
  final String? phone;
  final String? schoolId;
  final String? parentId;

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] as String?;
    return CurrentUser(
      id: (json['id'] ??
              json['_id'] ??
              json['user_id'] ??
              json['userId'] ??
              '')
          .toString(),
      role: UserRoleX.fromBackend(roleValue),
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      schoolId: (json['school_id'] ?? json['schoolId']) as String?,
      parentId: (json['parent_id'] ?? json['parentId']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role.backendValue,
      'name': name,
      'email': email,
      'phone': phone,
      'school_id': schoolId,
      'parent_id': parentId,
    };
  }
}
