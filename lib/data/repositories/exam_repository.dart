import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/exam/exam_series_model.dart';
import '../models/exam/exam_entry_model.dart';

class ExamRepository {
  const ExamRepository(this._dio);
  final Dio _dio;

  // Dio already includes /api/v1 in its baseUrl.
  static const String _base = '/exam-schedule';

  // ── POST /exam-schedule ────────────────────────────────────────────────────
  Future<ExamSeriesModel> createSeries({
    required String name,
    required String examId,
    String? section,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'exam_id': examId,
      if (section != null && section.trim().isNotEmpty) 'section': section.trim().toUpperCase(),
    };
    final response = await _dio.post(_base, data: body);
    return ExamSeriesModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── POST /exam-schedule/{series_id}/entries ────────────────────────────────
  Future<ExamEntryModel> addEntry({
    required String seriesId,
    required String subjectId,
    required String examDate, // "yyyy-MM-dd"
    required String startTime, // "HH:MM:SS"
    required int durationMinutes,
    String? venue,
  }) async {
    final body = <String, dynamic>{
      'subject_id': subjectId,
      'exam_date': examDate,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      if (venue != null) 'venue': venue,
    };
    final response = await _dio.post('$_base/$seriesId/entries', data: body);
    return ExamEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH /exam-schedule/{series_id}/publish ───────────────────────────────
  Future<ExamSeriesModel> publishSeries(String seriesId) async {
    final response = await _dio.patch('$_base/$seriesId/publish');
    return ExamSeriesModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH /exam-schedule/entries/{entry_id}/cancel ────────────────────────
  Future<ExamEntryModel> cancelEntry(String entryId) async {
    final response = await _dio.patch('$_base/entries/$entryId/cancel');
    return ExamEntryModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /exam-schedule?standard_id=...&series_id=... ─────────────────────
  Future<ExamScheduleTable> getSchedule({
    required String standardId,
    String? seriesId,
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'standard_id': standardId,
        if (seriesId != null && seriesId.isNotEmpty) 'series_id': seriesId,
      },
    );
    return ExamScheduleTable.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ExamSeriesModel>> listSeries({
    required String standardId,
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      '$_base/series',
      queryParameters: {
        'standard_id': standardId,
        if (academicYearId != null && academicYearId.isNotEmpty)
          'academic_year_id': academicYearId,
      },
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data
        .map((e) => ExamSeriesModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final examRepositoryProvider = Provider<ExamRepository>((ref) {
  return ExamRepository(ref.read(dioClientProvider));
});
