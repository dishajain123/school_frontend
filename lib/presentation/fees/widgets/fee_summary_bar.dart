import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';

/// Top-of-dashboard summary strip showing grand total, paid, and outstanding.
/// The progress bar fills based on paid/total ratio.
class FeeSummaryBar extends StatelessWidget {
  const FeeSummaryBar({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  double get _progressFraction =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppDecorations.shadow1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Three-column summary ───────────────────────────────────────────
          Row(
            children: [
              _SummaryColumn(
                label: 'Total',
                value: _fmt(totalAmount),
                valueColor: AppColors.white,
              ),
              const SizedBox(width: AppDimensions.space4),
              Container(
                width: 1,
                height: 36,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(width: AppDimensions.space4),
              _SummaryColumn(
                label: 'Paid',
                value: _fmt(paidAmount),
                valueColor: AppColors.successGreen,
              ),
              const SizedBox(width: AppDimensions.space4),
              Container(
                width: 1,
                height: 36,
                color: AppColors.white.withValues(alpha: 0.2),
              ),
              const SizedBox(width: AppDimensions.space4),
              _SummaryColumn(
                label: 'Outstanding',
                value: _fmt(outstandingAmount),
                valueColor: outstandingAmount > 0.01
                    ? AppColors.warningAmber
                    : AppColors.successGreen,
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.space16),

          // ── Progress bar ───────────────────────────────────────────────────
          ClipRRect(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: _progressFraction,
              minHeight: 8,
              backgroundColor: AppColors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.successGreen,
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.space8),

          // ── Progress label ─────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_progressFraction * 100).toStringAsFixed(0)}% paid',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              if (outstandingAmount > 0.01)
                Text(
                  '${_fmt(outstandingAmount)} remaining',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.warningAmber,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  'Fully cleared ✓',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: AppTypography.titleSmall.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}