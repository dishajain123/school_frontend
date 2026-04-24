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
    required this.permissions,
    this.fullName,
    this.email,
    this.phone,
    this.schoolId,
    this.parentId,
    this.isActive = true,
  });

  final String id;
  final UserRole role;
  final List<String> permissions;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? schoolId;
  final String? parentId;
  final bool isActive;

  bool hasPermission(String permission) => permissions.contains(permission);

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final roleValue = json['role'] as String?;
    final rawPerms = json['permissions'];
    final permissions = rawPerms is List
        ? rawPerms.map((e) => e.toString()).toList()
        : <String>[];

    return CurrentUser(
      id: (json['id'] ?? json['_id'] ?? json['user_id'] ?? json['userId'] ?? '')
          .toString(),
      role: UserRoleX.fromBackend(roleValue),
      permissions: permissions,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      schoolId: (json['school_id'] ?? json['schoolId']) as String?,
      parentId: (json['parent_id'] ?? json['parentId']) as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'role': role.backendValue,
      'permissions': permissions,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'school_id': schoolId,
      'parent_id': parentId,
      'is_active': isActive,
    };
  }

  CurrentUser copyWith({
    String? id,
    UserRole? role,
    List<String>? permissions,
    String? fullName,
    String? email,
    String? phone,
    String? schoolId,
    String? parentId,
    bool? isActive,
  }) {
    return CurrentUser(
      id: id ?? this.id,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      schoolId: schoolId ?? this.schoolId,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
    );
  }
}
