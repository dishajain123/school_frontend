import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum NotificationType {
  attendance,
  assignment,
  submission,
  homework,
  diary,
  exam,
  fee,
  result,
  announcement,
  leave,
  complaint,
  behaviour,
  chat,
  system,
}

enum NotificationPriority { low, medium, high }

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'ATTENDANCE':
        return NotificationType.attendance;
      case 'ASSIGNMENT':
        return NotificationType.assignment;
      case 'SUBMISSION':
        return NotificationType.submission;
      case 'HOMEWORK':
        return NotificationType.homework;
      case 'DIARY':
        return NotificationType.diary;
      case 'EXAM':
        return NotificationType.exam;
      case 'FEE':
        return NotificationType.fee;
      case 'RESULT':
        return NotificationType.result;
      case 'ANNOUNCEMENT':
        return NotificationType.announcement;
      case 'LEAVE':
        return NotificationType.leave;
      case 'COMPLAINT':
        return NotificationType.complaint;
      case 'BEHAVIOUR':
        return NotificationType.behaviour;
      case 'CHAT':
        return NotificationType.chat;
      default:
        return NotificationType.system;
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationType.attendance:
        return Icons.fact_check_outlined;
      case NotificationType.assignment:
        return Icons.assignment_outlined;
      case NotificationType.submission:
        return Icons.upload_file_outlined;
      case NotificationType.homework:
        return Icons.home_work_outlined;
      case NotificationType.diary:
        return Icons.menu_book_outlined;
      case NotificationType.exam:
        return Icons.quiz_outlined;
      case NotificationType.fee:
        return Icons.account_balance_wallet_outlined;
      case NotificationType.result:
        return Icons.bar_chart_outlined;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
      case NotificationType.leave:
        return Icons.beach_access_outlined;
      case NotificationType.complaint:
        return Icons.feedback_outlined;
      case NotificationType.behaviour:
        return Icons.psychology_outlined;
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
        return Icons.info_outline;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.attendance:
        return AppColors.successGreen;
      case NotificationType.assignment:
      case NotificationType.submission:
        return AppColors.infoBlue;
      case NotificationType.homework:
        return AppColors.navyMedium;
      case NotificationType.fee:
        return AppColors.warningAmber;
      case NotificationType.result:
      case NotificationType.exam:
        return AppColors.subjectMath;
      case NotificationType.leave:
        return AppColors.goldPrimary;
      case NotificationType.complaint:
        return AppColors.errorRed;
      case NotificationType.behaviour:
        return AppColors.subjectHindi;
      case NotificationType.announcement:
        return AppColors.navyDeep;
      default:
        return AppColors.grey600;
    }
  }
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    required this.updatedAt,
    this.referenceId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? referenceId;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    NotificationPriority parsePriority(String? v) {
      switch ((v ?? '').toUpperCase()) {
        case 'HIGH':
          return NotificationPriority.high;
        case 'LOW':
          return NotificationPriority.low;
        default:
          return NotificationPriority.medium;
      }
    }

    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationTypeX.fromString(json['type'] as String?),
      priority: parsePriority(json['priority'] as String?),
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      referenceId: json['reference_id'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      priority: priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      updatedAt: updatedAt,
      referenceId: referenceId,
    );
  }
}