import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class FeeDueBanner extends StatelessWidget {
  const FeeDueBanner({
    super.key,
    required this.amountDue,
    required this.onTap,
    this.onDismiss,
  });

  final double amountDue;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    if (amountDue <= 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: AppColors.goldLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: AppColors.goldPrimary.withValues(alpha: 0.4),
            width: AppDimensions.borderThin,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusSmall),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: AppDimensions.iconSM,
                color: AppColors.goldDark,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fee Payment Due',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₹${amountDue.toStringAsFixed(2)} pending',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.goldDark.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: AppDimensions.iconXS,
              color: AppColors.goldDark,
            ),
          ],
        ),
      ),
    );
  }
}