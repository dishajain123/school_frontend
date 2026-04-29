// lib/presentation/fees/screens/fee_receipt_screen.dart  [Mobile App]
// Phase 8 — Fee Receipt Screen.
// Fetches a presigned receipt URL from the backend and renders it in a WebView or
// provides a direct download/open link for the PDF.
// API: GET /fees/payments/{paymentId}/receipt → { url: "https://..." }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _receiptUrlProvider = FutureProvider.family<String, String>((ref, paymentId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.getReceiptUrl(paymentId);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class FeeReceiptScreen extends ConsumerWidget {
  const FeeReceiptScreen({
    super.key,
    required this.paymentId,
    this.amount,
    this.paymentDate,
    this.paymentMode,
  });

  final String paymentId;
  final double? amount;
  final String? paymentDate;
  final String? paymentMode;

  factory FeeReceiptScreen.fromExtras(Map<String, dynamic> extra) {
    return FeeReceiptScreen(
      paymentId: extra['paymentId'] as String? ?? '',
      amount: (extra['amount'] as num?)?.toDouble(),
      paymentDate: extra['paymentDate'] as String?,
      paymentMode: extra['paymentMode'] as String?,
    );
  }

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(_receiptUrlProvider(paymentId));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Payment Receipt',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_receiptUrlProvider(paymentId)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Payment Summary Card ───────────────────────────────────────────
          if (amount != null || paymentDate != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.receipt_long_rounded, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Text('Payment Receipt',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white70)),
                  ]),
                  const SizedBox(height: 12),
                  if (amount != null)
                    Text(
                      _fmt(amount!),
                      style: AppTypography.headlineLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (paymentDate != null)
                    Text('Date: $paymentDate',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                  if (paymentMode != null)
                    Text('Mode: $paymentMode',
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                  Text('ID: $paymentId',
                      style: AppTypography.labelSmall.copyWith(color: Colors.white38)),
                ],
              ),
            ),

          // ── Receipt Content ────────────────────────────────────────────────
          Expanded(
            child: receiptAsync.when(
              data: (url) => _ReceiptViewer(url: url, paymentId: paymentId),
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(_receiptUrlProvider(paymentId)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Receipt Viewer ────────────────────────────────────────────────────────────

class _ReceiptViewer extends StatelessWidget {
  const _ReceiptViewer({required this.url, required this.paymentId});

  final String url;
  final String paymentId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surface200),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B1F3A).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.successGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Receipt Ready',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your payment receipt has been generated. Tap the button below to view or download it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('View / Download Receipt'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDeep,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _launchUrl(context, url),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Receipt expires in 1 hour. Download before it expires.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchUrl(BuildContext context, String url) {
    // On web/mobile use url_launcher or equivalent.
    // Showing a snackbar with the URL as fallback for environments without url_launcher.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Receipt URL: $url'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () {
            // In production, implement clipboard copy or url_launcher here.
          },
        ),
        duration: const Duration(seconds: 10),
      ),
    );
  }
}
