import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/fee_summary_bar.dart';
import '../widgets/payment_tile.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.ledgerId,
    this.totalAmount = 0,
    this.paidAmount = 0,
    this.outstandingAmount = 0,
    this.statusLabel,
  });

  final String ledgerId;
  final double totalAmount;
  final double paidAmount;
  final double outstandingAmount;
  final String? statusLabel;

  /// Construct from GoRouter extras.
  factory PaymentHistoryScreen.fromExtras(Map<String, dynamic> extra) {
    return PaymentHistoryScreen(
      ledgerId: extra['ledgerId'] as String,
      totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (extra['paidAmount'] as num?)?.toDouble() ?? 0,
      outstandingAmount:
          (extra['outstandingAmount'] as num?)?.toDouble() ?? 0,
      statusLabel: extra['status'] as String?,
    );
  }

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentListProvider(ledgerId));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: const Text('Payment History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(paymentListProvider(ledgerId)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(paymentListProvider(ledgerId)),
        child: ListView(
          padding:
              const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space8),

            // ── Ledger summary ─────────────────────────────────────────────
            FeeSummaryBar(
              totalAmount: totalAmount,
              paidAmount: paidAmount,
              outstandingAmount: outstandingAmount,
            ),

            const SizedBox(height: AppDimensions.space24),

            // ── Payments list ──────────────────────────────────────────────
            paymentsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppDimensions.space8),
                    child: AppLoading.listTile(),
                  ),
                ),
              ),
              error: (e, _) {
                // If the endpoint doesn't exist yet, show a helpful message.
                final isNotFound = e.toString().contains('404') ||
                    e.toString().contains('NotFoundException');
                return AppErrorState(
                  message: isNotFound
                      ? 'Payment history is not yet available for this entry.'
                      : e.toString(),
                  onRetry: isNotFound
                      ? null
                      : () =>
                          ref.invalidate(paymentListProvider(ledgerId)),
                );
              },
              data: (payments) {
                if (payments.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Payments Yet',
                    subtitle:
                        'Payments recorded against this fee entry will appear here.',
                  );
                }

                return Container(
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
                    children: payments.asMap().entries.map((entry) {
                      return PaymentTile(
                        payment: entry.value,
                        isLast: entry.key == payments.length - 1,
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}