import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/announcement/announcement_model.dart';
import '../../common/widgets/app_card.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  final AnnouncementModel announcement;
  final VoidCallback? onTap;

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final type = announcement.type;
    final color = type.color;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: AppDecorations.quickActionContainer(color),
                child: Icon(type.icon, size: 16, color: color),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  announcement.title,
                  style: AppTypography.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Text(
                  type.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            announcement.body,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              const Icon(Icons.schedule,
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: AppDimensions.space4),
              Text(
                _formatDate(announcement.publishedAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              const Spacer(),
              if (announcement.attachmentUrl != null)
                const Icon(Icons.attachment,
                    size: 14, color: AppColors.grey400),
            ],
          ),
        ],
      ),
    );
  }
}
