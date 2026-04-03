import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/leave/leave_balance_model.dart';
import '../models/leave/leave_model.dart';

class LeaveRepository {
  const LeaveRepository(this._dio);
  final Dio _dio;

  // ── POST /api/v1/leave/apply ───────────────────────────────────────────────
  // Permission: leave:apply (TEACHER)
  // Creates a new leave request for the authenticated teacher.

  Future<LeaveModel> apply({
    required LeaveType leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    String? reason,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{
      'leave_type': leaveType.backendValue,
      'from_date': _formatDate(fromDate),
      'to_date': _formatDate(toDate),
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    final response = await _dio.post(
      ApiConstants.leaveApply,
      data: body,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH /api/v1/leave/{leave_id}/decision ────────────────────────────────
  // Permission: leave:approve (PRINCIPAL)
  // Approves or rejects a pending leave request.

  Future<LeaveModel> decide({
    required String leaveId,
    required LeaveStatus status,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'status': status.backendValue,
      if (remarks != null && remarks.trim().isNotEmpty)
        'remarks': remarks.trim(),
    };

    final response = await _dio.patch(
      ApiConstants.leaveDecision(leaveId),
      data: body,
    );
    return LeaveModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /api/v1/leave ──────────────────────────────────────────────────────
  // Permission: leave:read
  // TEACHER: returns own leaves only (backend scopes by teacher_id).
  // PRINCIPAL: returns all school leaves.

  Future<LeaveListResponse> list({
    LeaveStatus? status,
    String? academicYearId,
  }) async {
    final params = <String, dynamic>{
      if (status != null) 'status': status.backendValue,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    final response = await _dio.get(
      ApiConstants.leave,
      queryParameters: params.isEmpty ? null : params,
    );
    return LeaveListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /api/v1/leave/balance ──────────────────────────────────────────────
  // Permission: leave:apply (TEACHER only)
  // Returns leave balance for each leave type for the authenticated teacher.

  Future<List<LeaveBalanceModel>> getBalance({
    String? academicYearId,
  }) async {
    final params = <String, dynamic>{
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    final response = await _dio.get(
      ApiConstants.leaveBalance,
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data as List<dynamic>;
    return data
        .map((e) => LeaveBalanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(ref.read(dioClientProvider));
});