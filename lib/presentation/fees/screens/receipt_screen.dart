import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({
    super.key,
    required this.paymentId,
    this.amount,
    this.paymentDate,
    this.paymentMode,
  });

  final String paymentId;
  final double? amount;
  final DateTime? paymentDate;
  final String? paymentMode;

  factory ReceiptScreen.fromExtras(Map<String, dynamic> extra) {
    return ReceiptScreen(
      paymentId: extra['paymentId'] as String,
      amount: (extra['amount'] as num?)?.toDouble(),
      paymentDate: extra['paymentDate'] as DateTime?,
      paymentMode: extra['paymentMode'] as String?,
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '--';
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
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _fmt(double? v) {
    if (v == null) return '--';
    return '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urlAsync = ref.watch(receiptUrlProvider(paymentId));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(
        title: 'Fee Receipt',
        showBack: true,
        showNotificationBell: false,
      ),
      body: urlAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(
          message: 'Could not load receipt. ${e.toString()}',
          onRetry: () => ref.invalidate(receiptUrlProvider(paymentId)),
        ),
        data: (url) => _ReceiptContent(
          url: url,
          amount: amount,
          paymentDate: paymentDate,
          paymentMode: paymentMode,
          fmtDate: _fmtDate,
          fmt: _fmt,
        ),
      ),
    );
  }
}

class _ReceiptContent extends StatelessWidget {
  const _ReceiptContent({
    required this.url,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    required this.fmtDate,
    required this.fmt,
  });

  final String url;
  final double? amount;
  final DateTime? paymentDate;
  final String? paymentMode;
  final String Function(DateTime?) fmtDate;
  final String Function(double?) fmt;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        AppDimensions.space32,
        AppDimensions.pageHorizontal,
        AppDimensions.space40,
      ),
      children: [
        // ── Success hero ───────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.successGreen,
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'Payment Successful',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppDimensions.space4),
              Text(
                'Your receipt has been generated and is ready to view.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space32),

        // ── Amount highlight card ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppDimensions.space20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3558)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Amount Paid',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                fmt(amount),
                style: AppTypography.headlineLarge.copyWith(
                  color: AppColors.successGreen,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space20),

        // ── Details card ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
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
              _DetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Payment Date',
                value: fmtDate(paymentDate),
                isLast: paymentMode == null,
              ),
              if (paymentMode != null)
                _DetailRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment Mode',
                  value: paymentMode!,
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space32),

        // ── Open receipt button ────────────────────────────────────────────
        ElevatedButton.icon(
          onPressed: () => _openUrl(context, url),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Open Receipt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyDeep,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            textStyle: AppTypography.buttonPrimary,
          ),
        ),

        const SizedBox(height: AppDimensions.space12),

        Center(
          child: Text(
            'Receipt link expires in ~60 minutes.',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey400,
            ),
          ),
        ),
      ],
    );
  }

  void _openUrl(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Open Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy the link below and open it in your browser:',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.surface50,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                border: Border.all(color: AppColors.surface200),
              ),
              child: SelectableText(
                url,
                style: AppTypography.caption.copyWith(
                  color: AppColors.navyMedium,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
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
          Icon(icon, size: AppDimensions.iconSM, color: AppColors.grey400),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// Local spacing constant
const double _space14 = 14.0;
