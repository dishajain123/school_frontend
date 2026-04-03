import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/fee/payment_model.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

/// Record a payment against a specific fee ledger entry.
/// Route: /fees/record-payment
/// Extras: { studentId, ledgerId, outstandingAmount, totalAmount }
///
/// Permission: fee:create (PRINCIPAL / TRUSTEE / SUPERADMIN).
class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.studentId,
    this.ledgerId,
    this.outstandingAmount,
    this.totalAmount,
  });

  final String studentId;
  final String? ledgerId;
  final double? outstandingAmount;
  final double? totalAmount;

  factory RecordPaymentScreen.fromExtras(Map<String, dynamic> extra) {
    return RecordPaymentScreen(
      studentId: extra['studentId'] as String? ?? '',
      ledgerId: extra['ledgerId'] as String?,
      outstandingAmount:
          (extra['outstandingAmount'] as num?)?.toDouble(),
      totalAmount: (extra['totalAmount'] as num?)?.toDouble(),
    );
  }

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState
    extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  PaymentMode _selectedMode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.outstandingAmount != null && widget.outstandingAmount! > 0) {
      _amountCtrl.text =
          widget.outstandingAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyMedium,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.ledgerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ledger entry selected.')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    final apiDate =
        '${_paymentDate.year}-${_paymentDate.month.toString().padLeft(2, '0')}-${_paymentDate.day.toString().padLeft(2, '0')}';

    final payment = await ref.read(recordPaymentProvider.notifier).record(
          studentId: widget.studentId,
          feeLedgerId: widget.ledgerId!,
          amount: amount,
          paymentMode: _selectedMode,
          paymentDate: apiDate,
          referenceNumber: _refCtrl.text.trim().isEmpty
              ? null
              : _refCtrl.text.trim(),
        );

    if (!mounted) return;

    if (payment != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Payment of ₹${amount.toStringAsFixed(2)} recorded successfully.',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      context.pop(payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordPaymentProvider);

    ref.listen<RecordPaymentState>(recordPaymentProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding:
              const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),

            // ── Context info ───────────────────────────────────────────────
            if (widget.totalAmount != null &&
                widget.outstandingAmount != null)
              _InfoBanner(
                totalAmount: widget.totalAmount!,
                outstandingAmount: widget.outstandingAmount!,
              ),

            const SizedBox(height: AppDimensions.space24),

            // ── Amount ─────────────────────────────────────────────────────
            AppTextField(
              label: 'Amount (₹)',
              hint: '0.00',
              controller: _amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Amount is required';
                }
                final d = double.tryParse(v.trim());
                if (d == null || d <= 0) {
                  return 'Enter a valid positive amount';
                }
                if (widget.outstandingAmount != null &&
                    d > widget.outstandingAmount! + 0.01) {
                  return 'Amount exceeds outstanding balance';
                }
                return null;
              },
            ),

            const SizedBox(height: AppDimensions.space16),

            // ── Payment Mode ───────────────────────────────────────────────
            _SectionLabel('Payment Mode'),
            const SizedBox(height: AppDimensions.space8),
            _PaymentModeSelector(
              selected: _selectedMode,
              onChanged: (mode) => setState(() => _selectedMode = mode),
            ),

            const SizedBox(height: AppDimensions.space16),

            // ── Payment Date ───────────────────────────────────────────────
            _SectionLabel('Payment Date'),
            const SizedBox(height: AppDimensions.space8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: AppColors.surface200,
                    width: AppDimensions.borderThin,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: AppDimensions.iconSM,
                        color: AppColors.grey600),
                    const SizedBox(width: AppDimensions.space12),
                    Text(
                      _fmtDate(_paymentDate),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right,
                        color: AppColors.grey400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.space16),

            // ── Reference Number (optional) ────────────────────────────────
            AppTextField(
              label: 'Reference Number (optional)',
              hint: 'Transaction ID, cheque no., etc.',
              controller: _refCtrl,
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: AppDimensions.space32),

            // ── Submit ─────────────────────────────────────────────────────
            AppButton.primary(
              label: 'Record Payment',
              onTap: state.isLoading ? () {} : _submit,
              isLoading: state.isLoading,
            ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.totalAmount,
    required this.outstandingAmount,
  });

  final double totalAmount;
  final double outstandingAmount;

  String _fmt(double v) => '₹${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.3),
          width: AppDimensions.borderThin,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.goldDark, size: AppDimensions.iconSM),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding: ${_fmt(outstandingAmount)}',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Total: ${_fmt(totalAmount)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.goldDark.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey800,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _PaymentModeSelector extends StatelessWidget {
  const _PaymentModeSelector({
    required this.selected,
    required this.onChanged,
  });

  final PaymentMode selected;
  final ValueChanged<PaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      children: PaymentMode.values.map((mode) {
        final isSelected = mode == selected;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.navyMedium
                  : AppColors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppColors.navyMedium
                    : AppColors.surface200,
                width: isSelected ? 1.5 : AppDimensions.borderThin,
              ),
              boxShadow: isSelected ? [] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mode.icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.grey600,
                ),
                const SizedBox(width: AppDimensions.space6),
                Text(
                  mode.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected
                        ? AppColors.white
                        : AppColors.grey800,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
