import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/fee/fee_ledger_model.dart';
import '../../../data/models/fee/payment_model.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';

// ── Color constants ───────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenBg = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kOrangeBg = Color(0xFFFFF3E0);
const _kRed = Color(0xFFC62828);
const _kRedBg = Color(0xFFFFEBEE);

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.ledgerId,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.statusLabel,
    this.installmentName,
    this.dueDate,
  });

  final String ledgerId;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String? statusLabel;
  final String? installmentName;
  final String? dueDate;

  factory PaymentHistoryScreen.fromExtras(Map<String, dynamic> extra) {
    return PaymentHistoryScreen(
      ledgerId: extra['ledgerId'] as String,
      totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (extra['paidAmount'] as num?)?.toDouble() ?? 0,
      outstandingAmount: (extra['outstandingAmount'] as num?)?.toDouble() ?? 0,
      statusLabel: extra['status'] as String?,
      installmentName: extra['installmentName'] as String?,
      dueDate: extra['dueDate'] as String?,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentListProvider(ledgerId));
    final status = FeeStatusX.fromString(statusLabel);
    final dueDateParsed = dueDate != null ? DateTime.tryParse(dueDate!) : null;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: installmentName ?? 'Payment History',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(paymentListProvider(ledgerId)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async => ref.invalidate(paymentListProvider(ledgerId)),
        child: CustomScrollView(
          slivers: [
            // ── Installment summary card ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _InstallmentSummaryCard(
                  installmentName: installmentName,
                  totalAmount: totalAmount,
                  paidAmount: paidAmount,
                  outstandingAmount: outstandingAmount,
                  status: status,
                  dueDate: dueDateParsed,
                ),
              ),
            ),

            // ── Section title ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Transactions',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
              ),
            ),

            // ── Payments list ─────────────────────────────────────────
            paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const SliverFillRemaining(
                    child: AppEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No Payments Yet',
                      subtitle:
                          'Payments recorded against this installment will appear here.',
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  sliver: SliverList.separated(
                    itemCount: payments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _PaymentCard(
                      payment: payments[i],
                      onViewReceipt: payments[i].hasReceipt
                          ? () => context.push(
                                RouteNames.feeReceipt,
                                extra: {
                                  'paymentId': payments[i].id,
                                  'amount': payments[i].amount,
                                  'paymentDate': payments[i].paymentDate,
                                  'paymentMode': payments[i].paymentMode.label,
                                },
                              )
                          : null,
                    ),
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: AppLoading.listTile(),
                  ),
                  childCount: 3,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: AppErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(paymentListProvider(ledgerId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Installment Summary Card ──────────────────────────────────────────────────

class _InstallmentSummaryCard extends StatelessWidget {
  const _InstallmentSummaryCard({
    required this.totalAmount,
    required this.paidAmount,
    required this.outstandingAmount,
    required this.status,
    this.installmentName,
    this.dueDate,
  });

  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final FeeStatus status;
  final String? installmentName;
  final DateTime? dueDate;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final pct =
        totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;
    final isOverdue = status == FeeStatus.overdue;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isOverdue
              ? [_kRed, const Color(0xFF8B1A1A)]
              : [const Color(0xFF0B1F3A), const Color(0xFF1A3558)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isOverdue ? _kRed : const Color(0xFF0B1F3A))
                .withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (installmentName != null && installmentName!.isNotEmpty)
                      Text(
                        installmentName!,
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    if (dueDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.event_rounded,
                                size: 12,
                                color: AppColors.white.withValues(alpha: 0.6)),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${_fmtDate(dueDate!)}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _WhiteStat(label: 'Total', value: _fmt(totalAmount)),
              ),
              Expanded(
                child: _WhiteStat(label: 'Paid', value: _fmt(paidAmount)),
              ),
              Expanded(
                child: _WhiteStat(
                    label: 'Outstanding', value: _fmt(outstandingAmount)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.white.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteStat extends StatelessWidget {
  const _WhiteStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption
                .copyWith(color: AppColors.white.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.titleSmall
                .copyWith(color: AppColors.white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Payment Card ──────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment, this.onViewReceipt});
  final PaymentModel payment;
  final VoidCallback? onViewReceipt;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mode icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _kGreenBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_modeIcon(payment.paymentMode.label),
                size: 20, color: _kGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentMode.label,
                  style: AppTypography.titleSmall
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmtDate(payment.paymentDate),
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                ),
                if (payment.referenceNumber != null &&
                    payment.referenceNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Ref: ${payment.referenceNumber}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400, fontSize: 10),
                  ),
                ],
                if (payment.transactionRef != null &&
                    payment.transactionRef!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Notes: ${payment.transactionRef}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400, fontSize: 10),
                  ),
                ],
                if (payment.lateFeeApplied) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kOrangeBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Late Payment',
                      style: AppTypography.caption.copyWith(
                        color: _kOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmt(payment.amount),
                style: AppTypography.titleMedium.copyWith(
                  color: _kGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (onViewReceipt != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onViewReceipt,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_rounded,
                            size: 11, color: AppColors.white),
                        const SizedBox(width: 4),
                        Text(
                          'Receipt',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.white,
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

  IconData _modeIcon(String mode) {
    switch (mode.toUpperCase()) {
      case 'CASH':
        return Icons.payments_rounded;
      case 'UPI':
        return Icons.qr_code_rounded;
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'CHEQUE':
        return Icons.account_balance_rounded;
      case 'DD':
        return Icons.receipt_long_rounded;
      case 'NEFT':
      case 'RTGS':
      case 'BANK_TRANSFER':
      case 'BANK':
      case 'ONLINE':
        return Icons.account_balance_wallet_rounded;
      case 'OTHER':
        return Icons.monetization_on_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }
}
