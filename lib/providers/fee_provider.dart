// lib/providers/fee_provider.dart  [Mobile App]
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/fee/fee_ledger_model.dart';
import '../data/models/fee/fee_structure_model.dart';
import '../data/models/fee/payment_model.dart';
import '../data/repositories/fee_repository.dart';

// ── Fee Dashboard Provider ─────────────────────────────────────────────────────
// Keyed by (studentId, academicYearId).
// Invalidate with ref.invalidate(feeDashboardProvider) after any payment.

typedef FeeDashboardParams = ({
  String studentId,
  String? academicYearId,
});

final feeDashboardProvider =
    FutureProvider.family<FeeDashboardResult, FeeDashboardParams>(
  (ref, params) async {
    final repo = ref.read(feeRepositoryProvider);
    return repo.getDashboard(
      params.studentId,
      academicYearId: params.academicYearId,
    );
  },
);

// ── Payment List Provider ─────────────────────────────────────────────────────
// Keyed by ledgerId. Shows all payments for one installment.

final paymentListProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, ledgerId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.listPayments(feeLedgerId: ledgerId);
});

// ── Fee Analytics Provider ────────────────────────────────────────────────────

typedef FeeAnalyticsParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
  String? studentId,
});

final feeAnalyticsProvider =
    FutureProvider.family<Map<String, dynamic>, FeeAnalyticsParams>(
  (ref, params) async {
    final repo = ref.read(feeRepositoryProvider);
    return repo.getAnalytics(
      academicYearId: params.academicYearId,
      standardId: params.standardId,
      section: params.section,
      studentId: params.studentId,
    );
  },
);

// ── Fee Structures Provider ───────────────────────────────────────────────────

typedef FeeStructuresParams = ({
  String? academicYearId,
  String? standardId,
});

final feeStructuresProvider =
    FutureProvider.family<List<FeeStructureModel>, FeeStructuresParams>(
  (ref, params) async {
    final standardId = params.standardId;
    if (standardId == null || standardId.trim().isEmpty) {
      return <FeeStructureModel>[];
    }
    final repo = ref.read(feeRepositoryProvider);
    return repo.listStructures(
      standardId: standardId,
      academicYearId: params.academicYearId,
    );
  },
);

// ── Receipt URL Provider ──────────────────────────────────────────────────────

final receiptUrlProvider =
    FutureProvider.family<String, String>((ref, paymentId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.getReceiptUrl(paymentId);
});

class RecordPaymentState {
  const RecordPaymentState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  RecordPaymentState copyWith({bool? isLoading, String? error, bool clearError = false}) {
    return RecordPaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RecordPaymentNotifier extends StateNotifier<RecordPaymentState> {
  RecordPaymentNotifier(this._ref) : super(const RecordPaymentState());

  final Ref _ref;

  Future<PaymentModel?> record({
    required String studentId,
    required String feeLedgerId,
    required double amount,
    required PaymentMode paymentMode,
    String? paymentDate,
    String? referenceNumber,
    String? transactionRef,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(feeRepositoryProvider);
      final payment = await repo.recordPayment(
        studentId: studentId,
        feeLedgerId: feeLedgerId,
        amount: amount,
        paymentMode: paymentMode.backendValue,
        paymentDate: paymentDate,
        referenceNumber: referenceNumber,
        transactionRef: transactionRef,
      );
      state = state.copyWith(isLoading: false, clearError: true);
      return payment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final recordPaymentProvider =
    StateNotifierProvider<RecordPaymentNotifier, RecordPaymentState>((ref) {
  return RecordPaymentNotifier(ref);
});
