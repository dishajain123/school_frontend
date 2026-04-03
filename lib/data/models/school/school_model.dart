enum SubscriptionPlan {
  basic,
  standard,
  premium,
}

extension SubscriptionPlanX on SubscriptionPlan {
  static SubscriptionPlan fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'STANDARD':
        return SubscriptionPlan.standard;
      case 'PREMIUM':
        return SubscriptionPlan.premium;
      default:
        return SubscriptionPlan.basic;
    }
  }

  String get backendValue {
    switch (this) {
      case SubscriptionPlan.basic:
        return 'BASIC';
      case SubscriptionPlan.standard:
        return 'STANDARD';
      case SubscriptionPlan.premium:
        return 'PREMIUM';
    }
  }

  String get label {
    switch (this) {
      case SubscriptionPlan.basic:
        return 'Basic';
      case SubscriptionPlan.standard:
        return 'Standard';
      case SubscriptionPlan.premium:
        return 'Premium';
    }
  }
}

class SchoolModel {
  const SchoolModel({
    required this.id,
    required this.name,
    required this.contactEmail,
    required this.subscriptionPlan,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.contactPhone,
  });

  final String id;
  final String name;
  final String? address;
  final String contactEmail;
  final String? contactPhone;
  final SubscriptionPlan subscriptionPlan;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SchoolModel.fromJson(Map<String, dynamic> json) {
    return SchoolModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: json['address'] as String?,
      contactEmail: (json['contact_email'] ?? '').toString(),
      contactPhone: json['contact_phone'] as String?,
      subscriptionPlan:
          SubscriptionPlanX.fromString(json['subscription_plan'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  SchoolModel copyWith({
    String? id,
    String? name,
    String? address,
    String? contactEmail,
    String? contactPhone,
    SubscriptionPlan? subscriptionPlan,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SchoolModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SchoolListResponse {
  const SchoolListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<SchoolModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory SchoolListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SchoolListResponse(
      items: rawItems
          .map((item) => SchoolModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawItems.length,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 1,
    );
  }
}

class SchoolSettingModel {
  const SchoolSettingModel({
    required this.id,
    required this.schoolId,
    required this.settingKey,
    required this.settingValue,
    required this.createdAt,
    required this.updatedAt,
    this.updatedBy,
  });

  final String id;
  final String schoolId;
  final String settingKey;
  final String settingValue;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SchoolSettingModel.fromJson(Map<String, dynamic> json) {
    return SchoolSettingModel(
      id: (json['id'] ?? '').toString(),
      schoolId: (json['school_id'] ?? '').toString(),
      settingKey: (json['setting_key'] ?? '').toString(),
      settingValue: (json['setting_value'] ?? '').toString(),
      updatedBy: json['updated_by']?.toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }

  SchoolSettingModel copyWith({
    String? settingValue,
  }) {
    return SchoolSettingModel(
      id: id,
      schoolId: schoolId,
      settingKey: settingKey,
      settingValue: settingValue ?? this.settingValue,
      updatedBy: updatedBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class SchoolSettingsListResponse {
  const SchoolSettingsListResponse({
    required this.items,
    required this.total,
  });

  final List<SchoolSettingModel> items;
  final int total;

  factory SchoolSettingsListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SchoolSettingsListResponse(
      items: rawItems
          .map((item) =>
              SchoolSettingModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawItems.length,
    );
  }
}
