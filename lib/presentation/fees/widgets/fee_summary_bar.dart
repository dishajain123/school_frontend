import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';

class FeeSummaryBar extends StatefulWidget {
  const FeeSummaryBar({
    super.key,
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
  });

  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;

  @override
  State<FeeSummaryBar> createState() => _FeeSummaryBarState();
}

class _FeeSummaryBarState extends State<FeeSummaryBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  double get _fraction =>
      widget.totalAmount > 0
          ? (widget.paidAmount / widget.totalAmount).clamp(0.0, 1.0)
          : 0.0;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _progress = Tween<double>(begin: 0, end: _fraction).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullyPaid = widget.outstandingAmount <= 0.01;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3558)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: -32,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.space8),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.1),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.white,
                        size: AppDimensions.iconSM,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Text(
                      'Fee Overview',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (fullyPaid)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                          border: Border.all(
                            color:
                                AppColors.successGreen.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 10, color: AppColors.successGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Cleared',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space20),

                // Total amount (hero)
                Text(
                  _fmt(widget.totalAmount),
                  style: AppTypography.headlineLarge.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Total Billed',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ),

                const SizedBox(height: AppDimensions.space20),

                // Progress bar
                AnimatedBuilder(
                  animation: _progress,
                  builder: (_, __) => Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                        child: LinearProgressIndicator(
                          value: _progress.value,
                          minHeight: 6,
                          backgroundColor:
                              AppColors.white.withValues(alpha: 0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.successGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_progress.value * 100).toStringAsFixed(0)}% paid',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.5),
                            ),
                          ),
                          if (!fullyPaid)
                            Text(
                              '${_fmt(widget.outstandingAmount)} due',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.warningAmber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Divider
                Container(
                  height: 1,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),

                const SizedBox(height: AppDimensions.space16),

                // Paid / Outstanding split
                Row(
                  children: [
                    Expanded(
                      child: _StatColumn(
                        label: 'Paid',
                        value: _fmt(widget.paidAmount),
                        valueColor: AppColors.successGreen,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 36,
                      color: AppColors.white.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _StatColumn(
                        label: 'Outstanding',
                        value: _fmt(widget.outstandingAmount),
                        valueColor: fullyPaid
                            ? AppColors.successGreen
                            : AppColors.warningAmber,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.space4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}