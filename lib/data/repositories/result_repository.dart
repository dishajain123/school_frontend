import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/result/result_model.dart';

class ResultRepository {
  const ResultRepository(this._dio);
  final Dio _dio;

  static const String _base = '/results';

  // ── POST /results/exams ────────────────────────────────────────────────────
  Future<ExamModel> createExam({
    required String name,
    required String examType,
    required String standardId,
    required String startDate,
    required String endDate,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'exam_type': examType,
      'standard_id': standardId,
      'start_date': startDate,
      'end_date': endDate,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };
    final response = await _dio.post('$_base/exams', data: body);
    return ExamModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── POST /results/entries ──────────────────────────────────────────────────
  Future<ResultListResponse> bulkEnterResults({
    required String examId,
    required List<Map<String, dynamic>> entries,
  }) async {
    final body = <String, dynamic>{
      'exam_id': examId,
      'entries': entries,
    };
    final response = await _dio.post('$_base/entries', data: body);
    return ResultListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH /results/exams/{exam_id}/publish ─────────────────────────────────
  Future<int> publishExam(String examId) async {
    final response = await _dio.patch('$_base/exams/$examId/publish');
    return (response.data as Map<String, dynamic>)['updated'] as int? ?? 0;
  }

  // ── GET /results/exams ─────────────────────────────────────────────────────
  Future<List<ExamModel>> listExams({
    String? studentId,
    String? academicYearId,
    String? standardId,
  }) async {
    final response = await _dio.get(
      '$_base/exams',
      queryParameters: {
        if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
        if (academicYearId != null && academicYearId.isNotEmpty)
          'academic_year_id': academicYearId,
        if (standardId != null && standardId.isNotEmpty)
          'standard_id': standardId,
      },
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => ExamModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── GET /results?student_id=...&exam_id=... ────────────────────────────────
  Future<ResultListResponse> listResults({
    required String studentId,
    required String examId,
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'student_id': studentId,
        'exam_id': examId,
      },
    );
    return ResultListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /results/report-card/{student_id}?exam_id=... ─────────────────────
  Future<ReportCardModel> getReportCard({
    required String studentId,
    required String examId,
  }) async {
    final response = await _dio.get(
      '$_base/report-card/$studentId',
      queryParameters: {'exam_id': examId},
    );
    return ReportCardModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final resultRepositoryProvider = Provider<ResultRepository>((ref) {
  return ResultRepository(ref.read(dioClientProvider));
});
