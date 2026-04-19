import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/fee/payment_model.dart';

const double _space14 = 14.0;

class PaymentTile extends StatelessWidget {
  const PaymentTile({
    super.key,
    required this.payment,
    this.isLast = false,
  });

  final PaymentModel payment;
  final bool isLast;

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final hasRef = payment.referenceNumber != null &&
        payment.referenceNumber!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(
                  color: AppColors.surface100,
                  width: AppDimensions.borderThin,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: _space14,
      ),
      child: Row(
        children: [
          // Mode icon badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(
              payment.paymentMode.icon,
              size: AppDimensions.iconSM,
              color: AppColors.navyMedium,
            ),
          ),

          const SizedBox(width: AppDimensions.space12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _fmtDate(payment.paymentDate),
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (payment.lateFeeApplied) ...[
                      const SizedBox(width: AppDimensions.space6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warningAmber.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          'Late Fee',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                Text(
                  payment.paymentMode.label +
                      (hasRef ? ' · Ref: ${payment.referenceNumber}' : ''),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppDimensions.space8),

          // Amount + receipt
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(payment.amount),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (payment.hasReceipt) ...[
                const SizedBox(height: AppDimensions.space4),
                GestureDetector(
                  onTap: () => context.push(
                    RouteNames.feeReceipt,
                    extra: {
                      'paymentId': payment.id,
                      'amount': payment.amount,
                      'paymentDate': payment.paymentDate,
                      'paymentMode': payment.paymentMode.label,
                    },
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space8,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.06),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.receipt_outlined,
                          size: 11,
                          color: AppColors.navyMedium,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Receipt',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.navyMedium,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
