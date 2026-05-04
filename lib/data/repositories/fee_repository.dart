// lib/data/repositories/fee_repository.dart  [Mobile App]
// Phase 8 — Fee Repository.
// Covers: dashboard, structures, ledger generation, payments, analytics, receipts.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/fee/fee_ledger_model.dart';
import '../models/fee/fee_structure_model.dart';
import '../models/fee/payment_model.dart';

class FeeRepository {
  const FeeRepository(this._dio);
  final Dio _dio;

  static const String _base = '/fees';

  // ── GET /fees?student_id={id} ──────────────────────────────────────────────
  // Returns all ledger entries for a student with totals.
  // STUDENT role: backend validates own studentId.
  // PARENT role: backend validates child belongs to parent.

  Future<FeeDashboardResult> getDashboard(
    String studentId, {
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'student_id': studentId,
        if (academicYearId != null && academicYearId.trim().isNotEmpty)
          'academic_year_id': academicYearId,
      },
    );
    return FeeDashboardResult.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /fees/structures ───────────────────────────────────────────────────
  // Lists fee structures for a class + academic year.

  Future<List<FeeStructureModel>> listStructures({
    required String standardId,
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      ApiConstants.feeStructuresList,
      queryParameters: {
        'standard_id': standardId,
        if (academicYearId != null && academicYearId.trim().isNotEmpty)
          'academic_year_id': academicYearId,
      },
    );
    final data = response.data;
    final List<dynamic> raw =
        data is List ? data : (data['items'] as List<dynamic>? ?? []);
    return raw
        .map((e) => FeeStructureModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── POST /fees/ledger/generate ─────────────────────────────────────────────
  // Permission: fee:create
  // Generates fee ledger entries for all students in a standard.

  Future<LedgerGenerateResult> generateLedger({
    required String standardId,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{'standard_id': standardId};
    if (academicYearId != null) body['academic_year_id'] = academicYearId;
    final response = await _dio.post('$_base/ledger/generate', data: body);
    final data = response.data as Map<String, dynamic>;
    return LedgerGenerateResult(
      created: (data['created'] as num?)?.toInt() ?? 0,
      skipped: (data['skipped'] as num?)?.toInt() ?? 0,
    );
  }

  // ── POST /fees/payments ────────────────────────────────────────────────────
  // Permission: fee:create
  // Records a payment. Returns payment with receipt_key if generated.

  Future<PaymentModel> recordPayment({
    required String studentId,
    required String feeLedgerId,
    required double amount,
    required String paymentMode,
    String? paymentDate,
    String? referenceNumber,
    String? transactionRef,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'fee_ledger_id': feeLedgerId,
      'amount': amount,
      'payment_mode': paymentMode,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
      if (transactionRef != null && transactionRef.isNotEmpty)
        'transaction_ref': transactionRef,
    };
    final response = await _dio.post('$_base/payments', data: body);
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /fees/payments?fee_ledger_id={id} ──────────────────────────────────
  // Lists payment history for a specific ledger entry.

  Future<List<PaymentModel>> listPayments({
    required String feeLedgerId,
  }) async {
    final response = await _dio.get(
      '$_base/payments',
      queryParameters: {'fee_ledger_id': feeLedgerId},
    );
    final data = response.data;
    final List<dynamic> raw =
        data is List ? data : (data['items'] as List<dynamic>? ?? []);
    return raw
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /fees/payments/{payment_id}/receipt ────────────────────────────────
  // Permission: fee:read
  // Returns a presigned MinIO URL for the PDF receipt.

  Future<String> getReceiptUrl(String paymentId) async {
    final response = await _dio.get('$_base/payments/$paymentId/receipt');
    final url = (response.data as Map<String, dynamic>)['url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Receipt URL not available. The receipt may still be generating.');
    }
    return url;
  }

  // ── GET /fees/analytics ────────────────────────────────────────────────────
  // Permission: Principal/Trustee/Superadmin

  Future<Map<String, dynamic>> getAnalytics({
    String? academicYearId,
    String? standardId,
    String? section,
    String? studentId,
    String? reportDate,
  }) async {
    final params = <String, dynamic>{
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (standardId != null) 'standard_id': standardId,
      if (section != null && section.trim().isNotEmpty) 'section': section,
      if (studentId != null) 'student_id': studentId,
      if (reportDate != null) 'report_date': reportDate,
    };

    try {
      final response = await _dio.get(
        '$_base/analytics',
        queryParameters: params,
      );
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      // Backward-compatible fallback if analytics endpoint unavailable.
      if (e.response?.statusCode == 404 || e.response?.statusCode == 403) {
        return {
          'summary': {
            'total_billed_amount': 0.0,
            'total_paid_amount': 0.0,
            'total_outstanding_amount': 0.0,
            'collection_percentage': 0.0,
            'total_ledgers': 0,
            'total_students': 0,
            'defaulters_count': 0,
          },
          'by_class': <Map<String, dynamic>>[],
          'by_category': <Map<String, dynamic>>[],
          'by_status': <Map<String, dynamic>>[],
          'by_payment_mode': <Map<String, dynamic>>[],
          'by_student': <Map<String, dynamic>>[],
          'by_installment': <Map<String, dynamic>>[],
        };
      }
      rethrow;
    }
  }

  // ── GET /fees/defaulters ───────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDefaulters({
    String? academicYearId,
    String? standardId,
  }) async {
    final response = await _dio.get(
      '$_base/defaulters',
      queryParameters: {
        if (academicYearId != null) 'academic_year_id': academicYearId,
        if (standardId != null) 'standard_id': standardId,
      },
    );
    return ((response.data as Map<String, dynamic>)['defaulters'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository(ref.read(dioClientProvider));
});

// ── Result types ──────────────────────────────────────────────────────────────

class LedgerGenerateResult {
  const LedgerGenerateResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}
