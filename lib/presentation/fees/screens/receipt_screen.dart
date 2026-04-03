import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/fee_provider.dart';
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

  /// Construct from GoRouter extras.
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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
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
      appBar: AppBar(title: const Text('Fee Receipt')),
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
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        const SizedBox(height: AppDimensions.space24),

        // ── Receipt icon + title ───────────────────────────────────────────
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 44,
              color: AppColors.successGreen,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space16),

        Center(
          child: Text(
            'Payment Successful',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space4),

        Center(
          child: Text(
            'Your receipt has been generated.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey600,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space32),

        // ── Payment details card ───────────────────────────────────────────
        Container(
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
            children: [
              _DetailRow(
                label: 'Amount Paid',
                value: fmt(amount),
                isHighlighted: true,
              ),
              _DetailRow(
                label: 'Payment Date',
                value: fmtDate(paymentDate),
              ),
              if (paymentMode != null)
                _DetailRow(
                  label: 'Payment Mode',
                  value: paymentMode!,
                  isLast: true,
                ),
            ],
          ),
        ),

        const SizedBox(height: AppDimensions.space24),

        // ── Open receipt button ────────────────────────────────────────────
        // Opens the presigned URL. Add flutter_pdfview inline rendering
        // here if package is available in pubspec.yaml.
        ElevatedButton.icon(
          onPressed: () => _openUrl(context, url),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Open Receipt'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyMedium,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(48),
            textStyle: AppTypography.labelLarge,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space12),

        // ── URL hint (debug) ───────────────────────────────────────────────
        // Remove in production or keep as a fallback.
        Center(
          child: Text(
            'Receipt URL expires in ~60 minutes.',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey400,
            ),
          ),
        ),

        const SizedBox(height: AppDimensions.space40),
      ],
    );
  }

  /// Opens the presigned URL.
  /// Uses url_launcher if available; falls back to showing a SnackBar with
  /// instructions when the package is not configured.
  void _openUrl(BuildContext context, String url) {
    // If url_launcher is in pubspec.yaml, replace this body with:
    //   await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    //
    // For now, show a dialog with the URL so the user can copy it.
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Open Receipt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Copy the link below and open it in your browser to view the receipt:'),
            const SizedBox(height: 8),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12),
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
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isHighlighted;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.surface200,
                  width: AppDimensions.borderThin,
                ),
              ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey600,
            ),
          ),
          Text(
            value,
            style: isHighlighted
                ? AppTypography.titleSmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                  )
                : AppTypography.titleSmall.copyWith(
                    color: AppColors.navyDeep,
                  ),
          ),
        ],
      ),
    );
  }
}
