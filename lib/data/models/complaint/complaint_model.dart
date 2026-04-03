import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum ComplaintCategory {
  academic,
  infrastructure,
  staff,
  other,
}

extension ComplaintCategoryX on ComplaintCategory {
  static ComplaintCategory fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ACADEMIC':
        return ComplaintCategory.academic;
      case 'INFRASTRUCTURE':
        return ComplaintCategory.infrastructure;
      case 'STAFF':
        return ComplaintCategory.staff;
      default:
        return ComplaintCategory.other;
    }
  }

  String get backendValue {
    switch (this) {
      case ComplaintCategory.academic:
        return 'ACADEMIC';
      case ComplaintCategory.infrastructure:
        return 'INFRASTRUCTURE';
      case ComplaintCategory.staff:
        return 'STAFF';
      case ComplaintCategory.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case ComplaintCategory.academic:
        return 'Academic';
      case ComplaintCategory.infrastructure:
        return 'Infrastructure';
      case ComplaintCategory.staff:
        return 'Staff';
      case ComplaintCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintCategory.academic:
        return Icons.school_outlined;
      case ComplaintCategory.infrastructure:
        return Icons.apartment_outlined;
      case ComplaintCategory.staff:
        return Icons.people_outline_rounded;
      case ComplaintCategory.other:
        return Icons.feedback_outlined;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintCategory.academic:
        return AppColors.subjectMath;
      case ComplaintCategory.infrastructure:
        return AppColors.warningAmber;
      case ComplaintCategory.staff:
        return AppColors.infoBlue;
      case ComplaintCategory.other:
        return AppColors.navyMedium;
    }
  }
}

enum ComplaintStatus {
  open,
  inProgress,
  resolved,
  closed,
}

extension ComplaintStatusX on ComplaintStatus {
  static ComplaintStatus fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'IN_PROGRESS':
        return ComplaintStatus.inProgress;
      case 'RESOLVED':
        return ComplaintStatus.resolved;
      case 'CLOSED':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.open;
    }
  }

  String get backendValue {
    switch (this) {
      case ComplaintStatus.open:
        return 'OPEN';
      case ComplaintStatus.inProgress:
        return 'IN_PROGRESS';
      case ComplaintStatus.resolved:
        return 'RESOLVED';
      case ComplaintStatus.closed:
        return 'CLOSED';
    }
  }

  String get label {
    switch (this) {
      case ComplaintStatus.open:
        return 'Open';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.closed:
        return 'Closed';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.open:
        return Icons.mark_email_unread_outlined;
      case ComplaintStatus.inProgress:
        return Icons.work_history_outlined;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case ComplaintStatus.closed:
        return Icons.lock_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.open:
        return AppColors.warningAmber;
      case ComplaintStatus.inProgress:
        return AppColors.infoBlue;
      case ComplaintStatus.resolved:
        return AppColors.successGreen;
      case ComplaintStatus.closed:
        return AppColors.grey600;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ComplaintStatus.open:
        return AppColors.warningLight;
      case ComplaintStatus.inProgress:
        return AppColors.infoLight;
      case ComplaintStatus.resolved:
        return AppColors.successLight;
      case ComplaintStatus.closed:
        return AppColors.surface100;
    }
  }

  int get indexValue {
    switch (this) {
      case ComplaintStatus.open:
        return 0;
      case ComplaintStatus.inProgress:
        return 1;
      case ComplaintStatus.resolved:
        return 2;
      case ComplaintStatus.closed:
        return 3;
    }
  }

  ComplaintStatus? get next {
    switch (this) {
      case ComplaintStatus.open:
        return ComplaintStatus.inProgress;
      case ComplaintStatus.inProgress:
        return ComplaintStatus.resolved;
      case ComplaintStatus.resolved:
        return ComplaintStatus.closed;
      case ComplaintStatus.closed:
        return null;
    }
  }
}

enum FeedbackType {
  general,
  academic,
  infrastructure,
  staff,
}

extension FeedbackTypeX on FeedbackType {
  static FeedbackType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ACADEMIC':
        return FeedbackType.academic;
      case 'INFRASTRUCTURE':
        return FeedbackType.infrastructure;
      case 'STAFF':
        return FeedbackType.staff;
      default:
        return FeedbackType.general;
    }
  }

  String get backendValue {
    switch (this) {
      case FeedbackType.general:
        return 'GENERAL';
      case FeedbackType.academic:
        return 'ACADEMIC';
      case FeedbackType.infrastructure:
        return 'INFRASTRUCTURE';
      case FeedbackType.staff:
        return 'STAFF';
    }
  }
}

class ComplaintModel {
  const ComplaintModel({
    required this.id,
    required this.schoolId,
    required this.category,
    required this.description,
    required this.status,
    required this.isAnonymous,
    required this.createdAt,
    this.submittedBy,
    this.attachmentKey,
    this.attachmentUrl,
    this.resolvedBy,
    this.resolutionNote,
    this.createdAtLocal,
  });

  final String id;
  final String schoolId;
  final String? submittedBy;
  final ComplaintCategory category;
  final String description;
  final String? attachmentKey;
  final String? attachmentUrl;
  final ComplaintStatus status;
  final String? resolvedBy;
  final String? resolutionNote;
  final bool isAnonymous;
  final DateTime createdAt;
  final String? createdAtLocal;

  int get statusIndex => status.indexValue;

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      submittedBy: json['submitted_by'] as String?,
      category: ComplaintCategoryX.fromString(json['category'] as String?),
      description: json['description'] as String? ?? '',
      attachmentKey: json['attachment_key'] as String?,
      attachmentUrl: json['attachment_url'] as String?,
      status: ComplaintStatusX.fromString(json['status'] as String?),
      resolvedBy: json['resolved_by'] as String?,
      resolutionNote: json['resolution_note'] as String?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      createdAtLocal: json['created_at_local'] as String?,
    );
  }
}

class ComplaintListResponse {
  const ComplaintListResponse({
    required this.items,
    required this.total,
  });

  final List<ComplaintModel> items;
  final int total;

  factory ComplaintListResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return ComplaintListResponse(
      items: raw
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? raw.length,
    );
  }
}

class FeedbackModel {
  const FeedbackModel({
    required this.id,
    required this.feedbackType,
    required this.rating,
    required this.createdAt,
    required this.schoolId,
    this.userId,
    this.comment,
  });

  final String id;
  final FeedbackType feedbackType;
  final int rating;
  final DateTime createdAt;
  final String schoolId;
  final String? userId;
  final String? comment;

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      feedbackType: FeedbackTypeX.fromString(json['feedback_type'] as String?),
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      schoolId: json['school_id'] as String,
    );
  }
}
