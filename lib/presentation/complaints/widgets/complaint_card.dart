import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_status_chip.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    this.onTap,
  });

  final ComplaintModel complaint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDimensions.quickActionIconContainer,
                height: AppDimensions.quickActionIconContainer,
                decoration: AppDecorations.quickActionContainer(
                    complaint.category.color),
                child: Icon(
                  complaint.category.icon,
                  size: AppDimensions.iconSM,
                  color: complaint.category.color,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Text(
                  complaint.category.label,
                  style: AppTypography.titleMedium,
                ),
              ),
              AppStatusChip(status: complaint.status.backendValue, small: true),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          Text(
            complaint.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey800),
          ),
          const SizedBox(height: AppDimensions.space12),
          Row(
            children: [
              const Icon(
                Icons.schedule_outlined,
                size: AppDimensions.iconXS,
                color: AppColors.grey400,
              ),
              const SizedBox(width: AppDimensions.space4),
              Text(
                DateFormatter.formatDate(complaint.createdAt),
                style: AppTypography.caption,
              ),
              const Spacer(),
              if (complaint.isAnonymous)
                Text(
                  'Anonymous',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (complaint.attachmentKey != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppDimensions.space8),
                  child: Icon(
                    Icons.attachment_rounded,
                    size: AppDimensions.iconXS,
                    color: AppColors.grey400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
