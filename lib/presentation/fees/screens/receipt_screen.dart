import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

// ── Color constants ───────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenBg = Color(0xFFE8F5E9);

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({
    super.key,
    required this.paymentId,
    this.amount,
    this.paymentDate,
    this.paymentMode,
    this.installmentName,
  });

  final String paymentId;
  final double? amount;
  final DateTime? paymentDate;
  final String? paymentMode;
  final String? installmentName;

  factory ReceiptScreen.fromExtras(Map<String, dynamic> extra) {
    return ReceiptScreen(
      paymentId: extra['paymentId'] as String,
      amount: (extra['amount'] as num?)?.toDouble(),
      paymentDate: extra['paymentDate'] as DateTime?,
      paymentMode: extra['paymentMode'] as String?,
      installmentName: extra['installmentName'] as String?,
    );
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '--';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
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
          installmentName: installmentName,
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
    required this.fmtDate,
    required this.fmt,
    this.amount,
    this.paymentDate,
    this.paymentMode,
    this.installmentName,
  });

  final String url;
  final double? amount;
  final DateTime? paymentDate;
  final String? paymentMode;
  final String? installmentName;
  final String Function(DateTime?) fmtDate;
  final String Function(double?) fmt;

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid receipt URL.')),
      );
      return;
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not open receipt. Try copying the link.')),
        );
      }
    }
  }

  void _copyUrl(BuildContext context) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt link copied to clipboard.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      children: [
        // ── Success hero ───────────────────────────────────────────────────
        Center(
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: _kGreenBg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _kGreen.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 52,
                  color: _kGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Payment Successful!',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your receipt has been generated and is ready to view.',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.grey500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Amount card ────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3558)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.25),
                blurRadius: 18,
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
              const SizedBox(height: 8),
              Text(
                fmt(amount),
                style: AppTypography.headlineLarge.copyWith(
                  color: _kGreen,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (installmentName != null &&
                  installmentName!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    installmentName!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Details card ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _ReceiptRow(
                icon: Icons.calendar_today_outlined,
                label: 'Payment Date',
                value: fmtDate(paymentDate),
                isFirst: true,
              ),
              if (paymentMode != null)
                _ReceiptRow(
                  icon: Icons.credit_card_outlined,
                  label: 'Payment Method',
                  value: paymentMode!,
                ),
              _ReceiptRow(
                icon: Icons.receipt_long_outlined,
                label: 'Receipt ID',
                value: '...${paymentMode?.hashCode.abs() ?? '—'}',
                isLast: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // ── Primary CTA: Open Receipt ──────────────────────────────────────
        ElevatedButton.icon(
          onPressed: () => _openUrl(context, url),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Open Receipt PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navyDeep,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            textStyle: AppTypography.buttonPrimary,
            elevation: 0,
          ),
        ),

        const SizedBox(height: 12),

        // ── Secondary CTA: Copy link ───────────────────────────────────────
        OutlinedButton.icon(
          onPressed: () => _copyUrl(context),
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy Receipt Link'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navyDeep,
            minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            side: const BorderSide(color: AppColors.surface200),
          ),
        ),

        const SizedBox(height: 16),

        Center(
          child: Text(
            'Receipt link expires in ~60 minutes.\nContact admin for a permanent copy.',
            style: AppTypography.caption
                .copyWith(color: AppColors.grey400, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// ── Receipt Row ───────────────────────────────────────────────────────────────

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.surface100)),
        borderRadius: isFirst
            ? const BorderRadius.vertical(top: Radius.circular(18))
            : isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(18))
                : null,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.navyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.grey500),
            ),
          ),
          Text(
            value,
            style: AppTypography.titleSmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.grey800,
            ),
          ),
        ],
      ),
    );
  }
}