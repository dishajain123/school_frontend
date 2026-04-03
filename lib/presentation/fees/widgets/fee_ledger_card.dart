import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../data/models/fee/fee_ledger_model.dart';

/// Card displaying a single FeeLedger entry.
///
/// NOTE: The backend FeeLedgerResponse does not expose fee_category or due_date
/// (those fields live on FeeStructure). The card shows amounts, status, and
/// progress with what the API provides. Update once the backend schema exposes
/// the related structure fields.
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

  /// Null hides the "Pay Now" button (for read-only roles).
  final VoidCallback? onPayNow;

  /// Optional 1-based index shown as "Fee Entry #N".
  final int? sequenceNumber;

  @override
  State<FeeLedgerCard> createState() => _FeeLedgerCardState();
}

class _FeeLedgerCardState extends State<FeeLedgerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    final ledger = widget.ledger;
    final status = ledger.status;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onViewHistory();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
            boxShadow: AppDecorations.shadow1,
            border: Border.all(
              color: AppColors.surface200,
              width: AppDimensions.borderThin,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusMedium),
                    topRight: Radius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.12),
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
                    // Status chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: AppDimensions.space4,
                      ),
                      decoration: BoxDecoration(
                        color: status.bgColor,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        status.label,
                        style: AppTypography.labelSmall.copyWith(
                          color: status.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total amount (prominent)
                    Text(
                      _fmt(ledger.totalAmount),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total Amount',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey600),
                    ),

                    const SizedBox(height: AppDimensions.space12),

                    // Progress bar
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      child: LinearProgressIndicator(
                        value: ledger.progressFraction,
                        minHeight: 6,
                        backgroundColor: AppColors.surface200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ledger.isFullyPaid
                              ? AppColors.successGreen
                              : AppColors.navyMedium,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppDimensions.space8),

                    // Paid vs outstanding split
                    Row(
                      children: [
                        _AmountPill(
                          label: 'Paid',
                          value: _fmt(ledger.paidAmount),
                          color: AppColors.successGreen,
                        ),
                        const SizedBox(width: AppDimensions.space8),
                        if (ledger.hasOutstanding)
                          _AmountPill(
                            label: 'Due',
                            value: _fmt(ledger.outstandingAmount),
                            color: AppColors.errorRed,
                          ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space12),

                    // Action row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onViewHistory,
                            icon: const Icon(Icons.history_rounded, size: 16),
                            label: const Text('History'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppDimensions.space8),
                              textStyle: AppTypography.labelMedium,
                            ),
                          ),
                        ),
                        if (widget.onPayNow != null &&
                            ledger.hasOutstanding) ...[
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onPayNow,
                              icon: const Icon(Icons.payments_outlined,
                                  size: 16),
                              label: const Text('Pay Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyMedium,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppDimensions.space8),
                                textStyle: AppTypography.labelMedium,
                              ),
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

class _AmountPill extends StatelessWidget {
  const _AmountPill({
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTypography.labelSmall
                .copyWith(color: AppColors.grey600),
          ),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}