import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/fee/fee_ledger_model.dart';

const double _space10 = 10.0;
const double _space14 = 14.0;

class FeeLedgerCard extends StatefulWidget {
  const FeeLedgerCard({
    super.key,
    required this.ledger,
    required this.onViewHistory,
    this.onPayNow,
    this.sequenceNumber,
  });

  final FeeLedgerModel ledger;
  final VoidCallback onViewHistory;
  final VoidCallback? onPayNow;
  final int? sequenceNumber;

  @override
  State<FeeLedgerCard> createState() => _FeeLedgerCardState();
}

class _FeeLedgerCardState extends State<FeeLedgerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger;
    final status = ledger.status;
    final fullyPaid = ledger.isFullyPaid;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          widget.onViewHistory();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.surface200),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header strip ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusLarge),
                    topRight: Radius.circular(AppDimensions.radiusLarge),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon container
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.07),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        size: 16,
                        color: AppColors.navyMedium,
                      ),
                    ),
                    const SizedBox(width: _space10),
                    Expanded(
                      child: Text(
                        widget.sequenceNumber != null
                            ? 'Fee Entry #${widget.sequenceNumber}'
                            : 'Fee Entry',
                        style: AppTypography.titleSmall.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Status pill
                    _StatusPill(label: status.label, color: status.color, bgColor: status.bgColor),
                  ],
                ),
              ),

              // ── Body ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fmt(ledger.totalAmount),
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.navyDeep,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Total Amount',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.grey400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Paid / Due pills
                        Row(
                          children: [
                            _MiniPill(
                              label: 'Paid',
                              value: _fmt(ledger.paidAmount),
                              color: AppColors.successGreen,
                            ),
                            if (ledger.hasOutstanding) ...[
                              const SizedBox(width: AppDimensions.space6),
                              _MiniPill(
                                label: 'Due',
                                value: _fmt(ledger.outstandingAmount),
                                color: AppColors.errorRed,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: _space14),

                    // Progress bar
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: ledger.progressFraction,
                        minHeight: 5,
                        backgroundColor: AppColors.surface100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          fullyPaid
                              ? AppColors.successGreen
                              : AppColors.navyMedium,
                        ),
                      ),
                    ),

                    const SizedBox(height: _space14),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _CardButton(
                            icon: Icons.history_rounded,
                            label: 'History',
                            onTap: widget.onViewHistory,
                            outlined: true,
                          ),
                        ),
                        if (widget.onPayNow != null && ledger.hasOutstanding) ...[
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: _CardButton(
                              icon: Icons.payments_rounded,
                              label: 'Pay Now',
                              onTap: widget.onPayNow!,
                              outlined: false,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.grey500),
          ),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.outlined,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        height: 38,
        decoration: BoxDecoration(
          color: outlined ? AppColors.white : AppColors.navyDeep,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(
            color: outlined ? AppColors.surface200 : AppColors.navyDeep,
            width: outlined ? 1.5 : 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: outlined ? AppColors.grey600 : AppColors.white,
            ),
            const SizedBox(width: AppDimensions.space6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: outlined ? AppColors.grey700 : AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
