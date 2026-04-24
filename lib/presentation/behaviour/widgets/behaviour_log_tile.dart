import 'package:flutter/material.dart';

import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/behaviour/behaviour_log_model.dart';
import '../../common/widgets/app_card.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_list_tile.dart';

class BehaviourLogTile extends StatelessWidget {
  const BehaviourLogTile({
    super.key,
    required this.log,
    this.onTap,
  });

  final BehaviourLogModel log;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: AppListTile(
        title: (log.studentName != null && log.studentName!.trim().isNotEmpty)
            ? log.studentName!.trim()
            : log.incidentType.label,
        subtitle:
            (log.studentName != null && log.studentName!.trim().isNotEmpty)
                ? '${log.incidentType.label} · ${log.description}'
                : log.description,
        showDivider: false,
        leading: Container(
          width: AppDimensions.quickActionIconContainer,
          height: AppDimensions.quickActionIconContainer,
          decoration: BoxDecoration(
            color: log.incidentTypeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          child: Icon(
            log.incidentType.icon,
            size: AppDimensions.iconSM,
            color: log.incidentTypeColor,
          ),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppChip(
              label: log.severity.label,
              color: log.severity.color.withValues(alpha: 0.14),
              textColor: log.severity.color,
              small: true,
            ),
            const SizedBox(height: AppDimensions.space6),
            Text(
              DateFormatter.formatDate(log.incidentDate),
              style: AppTypography.caption,
            ),
          ],
        ),
      ),
    );
  }
}
