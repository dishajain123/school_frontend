import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/fee/fee_ledger_model.dart';
import '../models/fee/fee_structure_model.dart';
import '../models/fee/payment_model.dart';

// ── Support types ─────────────────────────────────────────────────────────────

class LedgerGenerateResult {
  const LedgerGenerateResult({required this.created, required this.skipped});
  final int created;
  final int skipped;
}

// ── FeeRepository ─────────────────────────────────────────────────────────────

class FeeRepository {
  const FeeRepository(this._dio);

  final Dio _dio;

  static const String _base = '/api/v1/fees';

  // ── POST /fees/structures ──────────────────────────────────────────────────
  // Permission: fee:create
  // Creates a fee structure for a standard + academic year + category.

  Future<FeeStructureModel> createStructure(
      Map<String, dynamic> payload) async {
    final response = await _dio.post('$_base/structures', data: payload);
    return FeeStructureModel.fromJson(response.data as Map<String, dynamic>);
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
      created: data['created'] as int,
      skipped: data['skipped'] as int,
    );
  }

  // ── POST /fees/payments ────────────────────────────────────────────────────
  // Permission: fee:create
  // Records a payment against a fee ledger entry. Generates PDF receipt.

  Future<PaymentModel> recordPayment({
    required String studentId,
    required String feeLedgerId,
    required double amount,
    required String paymentMode, // PaymentMode.backendValue
    String? paymentDate, // ISO "yyyy-MM-dd"; backend defaults to today
    String? referenceNumber,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'fee_ledger_id': feeLedgerId,
      'amount': amount,
      'payment_mode': paymentMode,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (referenceNumber != null && referenceNumber.isNotEmpty)
        'reference_number': referenceNumber,
    };
    final response = await _dio.post('$_base/payments', data: body);
    return PaymentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /fees?student_id={id} ──────────────────────────────────────────────
  // Permission: fee:read
  // Returns all ledger entries for a student with outstanding_amount computed.
  // STUDENT role: backend validates own studentId.
  // PARENT role: backend validates child belongs to parent.

  Future<FeeDashboardResult> getDashboard(String studentId) async {
    final response = await _dio.get(
      _base,
      queryParameters: {'student_id': studentId},
    );
    return FeeDashboardResult.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── GET /fees/payments/{payment_id}/receipt ────────────────────────────────
  // Permission: fee:read
  // Returns a presigned MinIO URL for the PDF receipt.
  // URL is short-lived — do not cache.

  Future<String> getReceiptUrl(String paymentId) async {
    final response =
        await _dio.get('$_base/payments/$paymentId/receipt');
    return (response.data as Map<String, dynamic>)['url'] as String;
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
    // Support both { items: [...] } wrapper and direct list
    final List<dynamic> raw =
        data is List ? data : (data['items'] as List<dynamic>? ?? []);
    return raw
        .map((e) => PaymentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository(ref.read(dioClientProvider));
});
