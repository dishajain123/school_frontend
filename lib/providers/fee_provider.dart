import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth/current_user.dart';
import '../data/models/fee/fee_ledger_model.dart';
import '../data/models/fee/payment_model.dart';
import '../data/models/student/student_model.dart';
import '../data/repositories/fee_repository.dart';
import '../data/repositories/student_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/parent_provider.dart';

// ── Fee Dashboard Provider ─────────────────────────────────────────────────────
// Keyed by studentId — one cached instance per student.
// Invalidate with ref.invalidate(feeDashboardProvider(studentId)) after payment.

final feeDashboardProvider =
    FutureProvider.family<FeeDashboardResult, String>((ref, studentId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.getDashboard(studentId);
});

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

typedef FeeStudentFilterParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
});

final feeReportStudentsProvider =
    FutureProvider.family<List<StudentModel>, FeeStudentFilterParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    const pageSize = 100;
    var page = 1;
    var totalPages = 1;
    final items = <StudentModel>[];
    do {
      final result = await repo.list(
        academicYearId: params.academicYearId,
        standardId: params.standardId,
        section: params.section,
        page: page,
        pageSize: pageSize,
      );
      items.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);
    return items;
  },
);

// ── My Student ID Provider ─────────────────────────────────────────────────────
// For STUDENT role only. The student list endpoint is scoped by the backend
// to the logged-in user's own record when called as STUDENT.
// Returns null if the student record cannot be resolved.

final myStudentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.role != UserRole.student) return null;

  try {
    final repo = ref.read(studentRepositoryProvider);
    final result = await repo.list(page: 1, pageSize: 1);
    return result.items.isNotEmpty ? result.items.first.id : null;
  } catch (_) {
    return null;
  }
});

// ── Resolved Student ID Provider ──────────────────────────────────────────────
// Convenience provider that resolves the correct studentId based on role:
//   PARENT  → selectedChildIdProvider
//   STUDENT → myStudentIdProvider
//   Others  → null (must provide explicit studentId via route)

final resolvedStudentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return null;

  switch (user.role) {
    case UserRole.parent:
      return ref.watch(selectedChildIdProvider);
    case UserRole.student:
      final result = await ref.watch(myStudentIdProvider.future);
      return result;
    default:
      return null;
  }
});

// ── Receipt URL Provider ───────────────────────────────────────────────────────
// Always fetches fresh — presigned URLs expire after ~1 hour.

final receiptUrlProvider =
    FutureProvider.family<String, String>((ref, paymentId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.getReceiptUrl(paymentId);
});

// ── Payment List Provider ──────────────────────────────────────────────────────
// Keyed by feeLedgerId. Calls assumed GET /fees/payments?fee_ledger_id={id}.

final paymentListProvider =
    FutureProvider.family<List<PaymentModel>, String>((ref, feeLedgerId) async {
  final repo = ref.read(feeRepositoryProvider);
  return repo.listPayments(feeLedgerId: feeLedgerId);
});

// ── Record Payment State & Notifier ───────────────────────────────────────────

class RecordPaymentState {
  const RecordPaymentState({
    this.isLoading = false,
    this.error,
    this.lastPayment,
  });

  final bool isLoading;
  final String? error;
  final PaymentModel? lastPayment;

  bool get isSuccess => lastPayment != null;

  RecordPaymentState copyWith({
    bool? isLoading,
    String? error,
    PaymentModel? lastPayment,
    bool clearError = false,
  }) {
    return RecordPaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      lastPayment: lastPayment ?? this.lastPayment,
    );
  }
}

class RecordPaymentNotifier extends Notifier<RecordPaymentState> {
  @override
  RecordPaymentState build() => const RecordPaymentState();

  Future<PaymentModel?> record({
    required String studentId,
    required String feeLedgerId,
    required double amount,
    required PaymentMode paymentMode,
    String? paymentDate,
    String? referenceNumber,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(feeRepositoryProvider);
      final payment = await repo.recordPayment(
        studentId: studentId,
        feeLedgerId: feeLedgerId,
        amount: amount,
        paymentMode: paymentMode.backendValue,
        paymentDate: paymentDate,
        referenceNumber: referenceNumber,
      );
      state = state.copyWith(isLoading: false, lastPayment: payment);
      // Bust the dashboard cache so the caller can refresh.
      ref.invalidate(feeDashboardProvider(studentId));
      // Also invalidate payment list for this ledger.
      ref.invalidate(paymentListProvider(feeLedgerId));
      return payment;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const RecordPaymentState();
}

final recordPaymentProvider =
    NotifierProvider<RecordPaymentNotifier, RecordPaymentState>(
  RecordPaymentNotifier.new,
);
