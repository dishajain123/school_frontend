import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notification/notification_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = notification.type.color;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: notification.isRead ? AppColors.white : AppColors.infoLight.withValues(alpha: 0.3),
          border: Border(
            left: BorderSide(
              color: notification.isRead ? Colors.transparent : color,
              width: 3,
            ),
            bottom: const BorderSide(color: AppColors.surface100, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type.icon,
                size: AppDimensions.iconSM,
                color: color,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: notification.isRead
                                ? FontWeight.w500
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        DateFormatter.formatRelative(notification.createdAt),
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    notification.body,
                    style: AppTypography.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: AppDimensions.space8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: AppDimensions.space4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}