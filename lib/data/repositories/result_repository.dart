import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
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
    try {
      final response = await _dio.get(
        '$_base/report-card/$studentId',
        queryParameters: {'exam_id': examId},
      );
      return ReportCardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type != DioExceptionType.connectionError) rethrow;
      if (kIsWeb) rethrow;

      final baseUri = Uri.tryParse(_dio.options.baseUrl);
      final host = baseUri?.host.toLowerCase();
      final shouldRetryLocal =
          host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
      if (!shouldRetryLocal) rethrow;

      final retryUri = Uri(
        scheme: baseUri?.scheme.isNotEmpty == true ? baseUri!.scheme : 'http',
        host: host == '127.0.0.1' ? 'localhost' : '127.0.0.1',
        port: baseUri?.hasPort == true ? baseUri!.port : 8000,
        path: '${baseUri?.path ?? '/api/v1'}$_base/report-card/$studentId'
            .replaceAll('//', '/'),
        queryParameters: {'exam_id': examId},
      );
      final retry = await _dio.getUri(retryUri);
      return ReportCardModel.fromJson(retry.data as Map<String, dynamic>);
    }
  }

  Future<ReportCardModel> uploadReportCard({
    required String studentId,
    required String examId,
    required PlatformFile file,
  }) async {
    if ((file.bytes == null || file.bytes!.isEmpty) &&
        (file.path == null || file.path!.isEmpty)) {
      throw const FormatException('Selected file is empty or unavailable');
    }
    final multipartFile = file.bytes != null
        ? MultipartFile.fromBytes(file.bytes!, filename: file.name)
        : await MultipartFile.fromFile(file.path!, filename: file.name);

    final data = FormData.fromMap({
      'student_id': studentId,
      'exam_id': examId,
      'file': multipartFile,
    });
    final response = await _dio.post(ApiConstants.reportCardUpload, data: data);
    return ReportCardModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ResultDistributionModel> getExamDistribution({
    required String examId,
    String? section,
    String? studentId,
  }) async {
    final response = await _dio.get(
      '$_base/exams/$examId/distribution',
      queryParameters: {
        if (section != null && section.isNotEmpty) 'section': section,
        if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
      },
    );
    return ResultDistributionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<List<String>> listResultSections({
    required String standardId,
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      '$_base/sections',
      queryParameters: {
        'standard_id': standardId,
        if (academicYearId != null && academicYearId.isNotEmpty)
          'academic_year_id': academicYearId,
      },
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data.map((e) => e.toString()).toList();
  }
}

final resultRepositoryProvider = Provider<ResultRepository>((ref) {
  return ResultRepository(ref.read(dioClientProvider));
});
