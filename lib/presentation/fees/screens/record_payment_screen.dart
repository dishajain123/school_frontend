import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/fee/payment_model.dart';
import '../../../providers/fee_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

// ── Color constants ───────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenBg = Color(0xFFE8F5E9);
const _kRed = Color(0xFFC62828);

class RecordPaymentScreen extends ConsumerStatefulWidget {
  const RecordPaymentScreen({
    super.key,
    required this.studentId,
    this.ledgerId,
    this.totalAmount,
    this.outstandingAmount,
    this.installmentName,
    this.dueDate,
  });

  final String studentId;
  final String? ledgerId;
  final double? totalAmount;
  final double? outstandingAmount;
  final String? installmentName;
  final String? dueDate;

  factory RecordPaymentScreen.fromExtras(Map<String, dynamic> extra) {
    return RecordPaymentScreen(
      studentId: extra['studentId'] as String,
      ledgerId: extra['ledgerId'] as String?,
      totalAmount: (extra['totalAmount'] as num?)?.toDouble(),
      outstandingAmount: (extra['outstandingAmount'] as num?)?.toDouble(),
      installmentName: extra['installmentName'] as String?,
      dueDate: extra['dueDate'] as String?,
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
  final _transactionCtrl = TextEditingController();
  PaymentMode _selectedMode = PaymentMode.cash;
  DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Pre-fill amount with outstanding balance
    if (widget.outstandingAmount != null && widget.outstandingAmount! > 0) {
      _amountCtrl.text = widget.outstandingAmount!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    _transactionCtrl.dispose();
    super.dispose();
  }

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: Colors.white,
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
        const SnackBar(content: Text('No fee entry selected.')),
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
          transactionRef: _transactionCtrl.text.trim().isEmpty
              ? null
              : _transactionCtrl.text.trim(),
        );

    if (!mounted) return;

    if (payment != null) {
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

    final outstanding = widget.outstandingAmount ?? 0.0;
    final isOverdue = widget.dueDate != null &&
        DateTime.tryParse(widget.dueDate!)?.isBefore(DateTime.now()) == true;

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ── Installment context card ──────────────────────────────────
            _InstallmentContextCard(
              installmentName: widget.installmentName,
              totalAmount: widget.totalAmount,
              outstandingAmount: outstanding,
              dueDate: widget.dueDate,
              isOverdue: isOverdue,
              fmt: _fmt,
              fmtDate: _fmtDate,
            ),

            const SizedBox(height: 20),

            // ── Payment form card ─────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount
                    _SectionLabel(label: 'Payment Amount'),
                    const SizedBox(height: 10),
                    _AmountField(
                      controller: _amountCtrl,
                      outstandingAmount: outstanding,
                    ),
                    const SizedBox(height: 20),

                    // Payment Mode
                    _SectionLabel(label: 'Payment Method'),
                    const SizedBox(height: 10),
                    _PaymentModeGrid(
                      selected: _selectedMode,
                      onChanged: (m) => setState(() => _selectedMode = m),
                    ),
                    const SizedBox(height: 20),

                    // Payment Date
                    _SectionLabel(label: 'Payment Date'),
                    const SizedBox(height: 10),
                    _DatePickerTile(
                      date: _paymentDate,
                      formatted: _fmtDate(_paymentDate),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 20),

                    // Reference Number
                    _SectionLabel(label: 'Transaction Reference (optional)'),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: '',
                      hint: 'UTR No., Cheque No., Transaction ID...',
                      controller: _refCtrl,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Transaction Notes / Ref (optional)'),
                    const SizedBox(height: 10),
                    AppTextField(
                      label: '',
                      hint: 'Gateway ref, remarks, or payment details...',
                      controller: _transactionCtrl,
                      keyboardType: TextInputType.text,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Pay Now CTA ───────────────────────────────────────────────
            AppButton.primary(
              label: state.isLoading
                  ? 'Processing...'
                  : 'Pay Now  ${_amountCtrl.text.isNotEmpty && double.tryParse(_amountCtrl.text) != null ? _fmt(double.parse(_amountCtrl.text)) : ''}',
              onTap: state.isLoading ? () {} : _submit,
              isLoading: state.isLoading,
            ),

            if (outstanding > 0) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Outstanding balance: ${_fmt(outstanding)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Installment Context Card ──────────────────────────────────────────────────

class _InstallmentContextCard extends StatelessWidget {
  const _InstallmentContextCard({
    required this.outstandingAmount,
    required this.isOverdue,
    required this.fmt,
    required this.fmtDate,
    this.installmentName,
    this.totalAmount,
    this.dueDate,
  });

  final String? installmentName;
  final double? totalAmount;
  final double outstandingAmount;
  final String? dueDate;
  final bool isOverdue;
  final String Function(double) fmt;
  final String Function(DateTime) fmtDate;

  @override
  Widget build(BuildContext context) {
    final dueDateParsed = dueDate != null ? DateTime.tryParse(dueDate!) : null;

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
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isOverdue
                      ? Icons.warning_amber_rounded
                      : Icons.account_balance_wallet_outlined,
                  color: AppColors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      installmentName ?? 'Fee Payment',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (dueDateParsed != null)
                      Text(
                        isOverdue
                            ? 'OVERDUE · Due: ${fmtDate(dueDateParsed)}'
                            : 'Due: ${fmtDate(dueDateParsed)}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (totalAmount != null)
                Expanded(
                  child: _WhiteStat(label: 'Total', value: fmt(totalAmount!)),
                ),
              Expanded(
                child: _WhiteStat(
                  label: 'Outstanding',
                  value: fmt(outstandingAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: totalAmount != null && totalAmount! > 0
                  ? ((totalAmount! - outstandingAmount) / totalAmount!)
                      .clamp(0.0, 1.0)
                  : 0.0,
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

// ── Amount Field ──────────────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField(
      {required this.controller, required this.outstandingAmount});
  final TextEditingController controller;
  final double outstandingAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text('₹',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w700,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
                hintStyle: AppTypography.headlineMedium.copyWith(
                  color: AppColors.grey300,
                  fontWeight: FontWeight.w400,
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Amount is required';
                }
                final d = double.tryParse(v.trim());
                if (d == null || d <= 0) {
                  return 'Enter a valid positive amount';
                }
                if (outstandingAmount > 0 && d > outstandingAmount + 0.01) {
                  return 'Amount exceeds outstanding (${outstandingAmount.toStringAsFixed(2)})';
                }
                return null;
              },
            ),
          ),
          if (outstandingAmount > 0)
            GestureDetector(
              onTap: () {
                controller.text = outstandingAmount.toStringAsFixed(2);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _kGreenBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Full',
                  style: AppTypography.labelSmall.copyWith(
                    color: _kGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Payment Mode Grid ─────────────────────────────────────────────────────────

class _PaymentModeGrid extends StatelessWidget {
  const _PaymentModeGrid({required this.selected, required this.onChanged});
  final PaymentMode selected;
  final ValueChanged<PaymentMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PaymentMode.values.map((mode) {
        final isSelected = selected == mode;
        return GestureDetector(
          onTap: () => onChanged(mode),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.navyDeep : AppColors.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.navyDeep : AppColors.surface200,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _modeIcon(mode),
                  size: 16,
                  color: isSelected ? AppColors.white : AppColors.grey500,
                ),
                const SizedBox(width: 6),
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

  IconData _modeIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.payments_rounded;
      case PaymentMode.upi:
        return Icons.qr_code_rounded;
      case PaymentMode.online:
        return Icons.credit_card_rounded;
      case PaymentMode.card:
        return Icons.credit_card_rounded;
      case PaymentMode.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMode.cheque:
        return Icons.account_balance_rounded;
      case PaymentMode.dd:
        return Icons.receipt_long_rounded;
      case PaymentMode.neft:
        return Icons.account_balance_wallet_rounded;
      case PaymentMode.rtgs:
        return Icons.swap_horiz_rounded;
      case PaymentMode.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

// ── Date Picker Tile ──────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 18, color: AppColors.navyMedium),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                formatted,
                style: AppTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more_rounded,
                size: 18, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey700,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}
