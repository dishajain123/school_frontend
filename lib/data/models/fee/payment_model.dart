import 'package:flutter/material.dart';

// ── PaymentMode ───────────────────────────────────────────────────────────────
// Mirrors app/utils/enums.PaymentMode.
// Values must match the backend enum exactly.

enum PaymentMode {
  cash,
  cheque,
  online,
  dd,
  neft,
  rtgs,
  upi,
  other,
}

extension PaymentModeX on PaymentMode {
  static PaymentMode fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'CASH':
        return PaymentMode.cash;
      case 'CHEQUE':
        return PaymentMode.cheque;
      case 'ONLINE':
        return PaymentMode.online;
      case 'DD':
        return PaymentMode.dd;
      case 'NEFT':
      case 'BANK_TRANSFER':
      case 'BANK':
        return PaymentMode.neft;
      case 'RTGS':
        return PaymentMode.rtgs;
      case 'UPI':
        return PaymentMode.upi;
      case 'OTHER':
      case 'CARD':
        return PaymentMode.other;
      default:
        return PaymentMode.cash;
    }
  }

  String get backendValue {
    switch (this) {
      case PaymentMode.cash:
        return 'CASH';
      case PaymentMode.cheque:
        return 'CHEQUE';
      case PaymentMode.online:
        return 'ONLINE';
      case PaymentMode.dd:
        return 'DD';
      case PaymentMode.neft:
        return 'NEFT';
      case PaymentMode.rtgs:
        return 'RTGS';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.other:
        return 'OTHER';
    }
  }

  String get label {
    switch (this) {
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.cheque:
        return 'Cheque';
      case PaymentMode.online:
        return 'Online';
      case PaymentMode.dd:
        return 'Demand Draft';
      case PaymentMode.neft:
        return 'NEFT';
      case PaymentMode.rtgs:
        return 'RTGS';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMode.cash:
        return Icons.payments_outlined;
      case PaymentMode.cheque:
        return Icons.description_outlined;
      case PaymentMode.online:
        return Icons.language_outlined;
      case PaymentMode.dd:
        return Icons.receipt_long_outlined;
      case PaymentMode.neft:
        return Icons.account_balance_outlined;
      case PaymentMode.rtgs:
        return Icons.swap_horiz_outlined;
      case PaymentMode.upi:
        return Icons.smartphone_outlined;
      case PaymentMode.other:
        return Icons.payments_outlined;
    }
  }
}

// ── PaymentModel ──────────────────────────────────────────────────────────────
// Mirrors PaymentResponse from app/schemas/fee.py

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.feeLedgerId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMode,
    required this.lateFeeApplied,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
    this.referenceNumber,
    this.receiptKey,
    this.recordedBy,
    this.originalDueDate,
  });

  final String id;
  final String studentId;
  final String feeLedgerId;
  final double amount;
  final DateTime paymentDate;
  final PaymentMode paymentMode;
  final String? referenceNumber;
  final String? receiptKey;
  final String? recordedBy;
  final bool lateFeeApplied;
  final DateTime? originalDueDate;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasReceipt => receiptKey != null && receiptKey!.isNotEmpty;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      feeLedgerId: json['fee_ledger_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['payment_date'] as String),
      paymentMode: PaymentModeX.fromString(json['payment_mode'] as String?),
      referenceNumber: json['reference_number'] as String?,
      receiptKey: json['receipt_key'] as String?,
      recordedBy: json['recorded_by'] as String?,
      lateFeeApplied: json['late_fee_applied'] as bool? ?? false,
      originalDueDate: json['original_due_date'] != null
          ? DateTime.tryParse(json['original_due_date'] as String)
          : null,
      schoolId: json['school_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

// ── PaymentListResult ─────────────────────────────────────────────────────────

class PaymentListResult {
  const PaymentListResult({required this.items, required this.total});

  final List<PaymentModel> items;
  final int total;

  factory PaymentListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaymentListResult(
      items: rawItems
          .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }
}
