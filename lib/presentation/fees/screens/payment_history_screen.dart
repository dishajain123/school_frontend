import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_app_bar.dart';
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

  factory PaymentHistoryScreen.fromExtras(Map<String, dynamic> extra) {
    return PaymentHistoryScreen(
      ledgerId: extra['ledgerId'] as String,
      totalAmount: (extra['totalAmount'] as num?)?.toDouble() ?? 0,
      paidAmount: (extra['paidAmount'] as num?)?.toDouble() ?? 0,
      outstandingAmount: (extra['outstandingAmount'] as num?)?.toDouble() ?? 0,
      statusLabel: extra['status'] as String?,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentListProvider(ledgerId));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Payment History',
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
        onRefresh: () async => ref.invalidate(paymentListProvider(ledgerId)),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageHorizontal,
            AppDimensions.space16,
            AppDimensions.pageHorizontal,
            AppDimensions.space40,
          ),
          children: [
            // Summary hero
            FeeSummaryBar(
              totalAmount: totalAmount,
              paidAmount: paidAmount,
              outstandingAmount: outstandingAmount,
            ),

            const SizedBox(height: AppDimensions.space24),

            // Status badge row
            if (statusLabel != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusBackground(statusLabel!),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      statusLabel!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.statusForeground(statusLabel!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Section heading
            Row(
              children: [
                Text(
                  'Transactions',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.navyDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space12),

            // Payments list
            paymentsAsync.when(
              loading: () => Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.space8),
                    child: AppLoading.listTile(),
                  ),
                ),
              ),
              error: (e, _) {
                final isNotFound = e.toString().contains('404') ||
                    e.toString().contains('NotFoundException');
                return AppErrorState(
                  message: isNotFound
                      ? 'Payment history is not yet available for this entry.'
                      : e.toString(),
                  onRetry: isNotFound
                      ? null
                      : () => ref.invalidate(paymentListProvider(ledgerId)),
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
          ],
        ),
      ),
    );
  }
}
