enum RelationType {
  mother,
  father,
  guardian,
}

extension RelationTypeX on RelationType {
  static RelationType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'MOTHER':
        return RelationType.mother;
      case 'FATHER':
        return RelationType.father;
      default:
        return RelationType.guardian;
    }
  }

  String get backendValue {
    switch (this) {
      case RelationType.mother:
        return 'MOTHER';
      case RelationType.father:
        return 'FATHER';
      case RelationType.guardian:
        return 'GUARDIAN';
    }
  }

  String get label {
    switch (this) {
      case RelationType.mother:
        return 'Mother';
      case RelationType.father:
        return 'Father';
      case RelationType.guardian:
        return 'Guardian';
    }
  }
}

class ParentUserModel {
  const ParentUserModel({
    required this.id,
    required this.isActive,
    this.fullName,
    this.email,
    this.phone,
    this.profilePhotoKey,
    this.profilePhotoUrl,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final bool isActive;
  final String? profilePhotoKey;
  final String? profilePhotoUrl;

  factory ParentUserModel.fromJson(Map<String, dynamic> json) {
    return ParentUserModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      profilePhotoKey: json['profile_photo_key'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
    );
  }

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    if (email != null && email!.isNotEmpty) {
      final parts = email!.split('@').first.split('.');
      return parts.map((w) {
        if (w.isEmpty) return w;
        return w[0].toUpperCase() + w.substring(1);
      }).join(' ');
    }
    return phone ?? 'Parent';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'P';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

class ParentModel {
  const ParentModel({
    required this.id,
    required this.schoolId,
    required this.relation,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    this.occupation,
  });

  final String id;
  final String schoolId;
  final String? occupation;
  final RelationType relation;
  final ParentUserModel user;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ParentModel.fromJson(Map<String, dynamic> json) {
    return ParentModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      occupation: json['occupation'] as String?,
      relation: RelationTypeX.fromString(json['relation'] as String?),
      user: ParentUserModel.fromJson(json['user'] as Map<String, dynamic>),
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

  ParentModel copyWith({
    String? occupation,
    RelationType? relation,
  }) {
    return ParentModel(
      id: id,
      schoolId: schoolId,
      occupation: occupation ?? this.occupation,
      relation: relation ?? this.relation,
      user: user,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}