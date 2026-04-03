import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/school/school_model.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_list_tile.dart';

class SchoolTile extends StatelessWidget {
  const SchoolTile({
    super.key,
    required this.school,
    this.onTap,
    this.isLast = false,
  });

  final SchoolModel school;
  final VoidCallback? onTap;
  final bool isLast;

  Color get _planColor {
    switch (school.subscriptionPlan) {
      case SubscriptionPlan.basic:
        return AppColors.infoBlue;
      case SubscriptionPlan.standard:
        return AppColors.warningAmber;
      case SubscriptionPlan.premium:
        return AppColors.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      title: school.name,
      subtitle: school.contactEmail,
      isLast: isLast,
      onTap: onTap,
      leading: Container(
        width: AppDimensions.quickActionIconContainer,
        height: AppDimensions.quickActionIconContainer,
        decoration: BoxDecoration(
          color: AppColors.navyLight.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: const Icon(
          Icons.business_outlined,
          color: AppColors.navyMedium,
          size: AppDimensions.iconSM,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AppChip(
            label: school.subscriptionPlan.label,
            color: _planColor.withValues(alpha: 0.14),
            textColor: _planColor,
            small: true,
          ),
          const SizedBox(height: AppDimensions.space6),
          Text(
            school.isActive ? 'Active' : 'Inactive',
            style: AppTypography.caption.copyWith(
              color:
                  school.isActive ? AppColors.successGreen : AppColors.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
