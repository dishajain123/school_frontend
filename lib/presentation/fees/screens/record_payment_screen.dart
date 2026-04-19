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
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

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
      outstandingAmount: (extra['outstandingAmount'] as num?)?.toDouble(),
      totalAmount: (extra['totalAmount'] as num?)?.toDouble(),
    );
  }

  @override
  ConsumerState<RecordPaymentScreen> createState() =>
      _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _refCtrl = TextEditingController();

  PaymentMode _selectedMode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.outstandingAmount != null && widget.outstandingAmount! > 0) {
      _amountCtrl.text = widget.outstandingAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

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
          referenceNumber:
              _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
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
      appBar: const AppAppBar(
        title: 'Record Payment',
        showBack: true,
        showNotificationBell: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pageHorizontal,
            AppDimensions.space16,
            AppDimensions.pageHorizontal,
            AppDimensions.space40,
          ),
          children: [
            // ── Context banner ─────────────────────────────────────────────
            if (widget.totalAmount != null && widget.outstandingAmount != null)
              _ContextBanner(
                totalAmount: widget.totalAmount!,
                outstandingAmount: widget.outstandingAmount!,
                fmt: _fmt,
              ),

            if (widget.totalAmount != null)
              const SizedBox(height: AppDimensions.space24),

            // ── Form card ──────────────────────────────────────────────────
            Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16,
                      vertical: _space14,
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
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.navyDeep.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSmall),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            size: 16,
                            color: AppColors.navyMedium,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.space12),
                        Text(
                          'Payment Details',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Amount
                        AppTextField(
                          label: 'Amount (₹)',
                          hint: '0.00',
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
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

                        const SizedBox(height: AppDimensions.space20),

                        // Payment Mode label
                        Text(
                          'Payment Mode',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: _space10),
                        _PaymentModeGrid(
                          selected: _selectedMode,
                          onChanged: (m) => setState(() => _selectedMode = m),
                        ),

                        const SizedBox(height: AppDimensions.space20),

                        // Payment Date label
                        Text(
                          'Payment Date',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.grey700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        _DatePickerTile(
                          date: _paymentDate,
                          formatted: _fmtDate(_paymentDate),
                          onTap: _pickDate,
                        ),

                        const SizedBox(height: AppDimensions.space20),

                        // Reference
                        AppTextField(
                          label: 'Reference Number (optional)',
                          hint: 'Transaction ID, cheque no., etc.',
                          controller: _refCtrl,
                          keyboardType: TextInputType.text,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            // Submit
            AppButton.primary(
              label: 'Record Payment',
              onTap: state.isLoading ? () {} : _submit,
              isLoading: state.isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ContextBanner extends StatelessWidget {
  const _ContextBanner({
    required this.totalAmount,
    required this.outstandingAmount,
    required this.fmt,
  });

  final double totalAmount;
  final double outstandingAmount;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyDeep,
            AppColors.navyMedium,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppColors.white,
              size: AppDimensions.iconMD,
            ),
          ),
          const SizedBox(width: AppDimensions.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Outstanding Balance',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppDimensions.space2),
                Text(
                  fmt(outstandingAmount),
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.warningAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Total',
                style: AppTypography.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.5),
                ),
              ),
              Text(
                fmt(totalAmount),
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.date,
    required this.formatted,
    required this.onTap,
  });

  final DateTime date;
  final String formatted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: _space14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: AppDimensions.iconSM,
              color: AppColors.grey400,
            ),
            const SizedBox(width: AppDimensions.space12),
            Text(
              formatted,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.navyDeep,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400,
              size: AppDimensions.iconSM,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentModeGrid extends StatelessWidget {
  const _PaymentModeGrid({
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
              vertical: _space10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyDeep : AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                color: isSelected ? AppColors.navyDeep : AppColors.surface200,
                width: isSelected
                    ? AppDimensions.borderMedium
                    : AppDimensions.borderThin,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mode.icon,
                  size: 15,
                  color: isSelected ? AppColors.white : AppColors.grey500,
                ),
                const SizedBox(width: AppDimensions.space6),
                Text(
                  mode.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? AppColors.white : AppColors.grey700,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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

// Local spacing constants
const double _space10 = 10.0;
const double _space14 = 14.0;
