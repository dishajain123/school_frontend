import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/diary/diary_model.dart';

class DiaryRepository {
  const DiaryRepository(this._dio);
  final Dio _dio;

  // Matches FastAPI router prefix: /api/v1/diary
  static const String _base = ApiConstants.diary;

  // ── List diary entries ─────────────────────────────────────────────────────
  // Role-scoped on the backend:
  //   TEACHER  → their own entries
  //   STUDENT  → their class entries
  //   PARENT   → all their children's class entries
  //   Admin    → all

  Future<DiaryListResponse> listDiary({
    String? date, // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? standardId, // UUID string
    String? subjectId, // UUID string — optional subject filter
    String? academicYearId, // UUID string — backend uses active year if omitted
    int page = 1,
    int pageSize = 100, // Daily diary lists are small; load all in one shot
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (date != null) 'date': date,
        if (standardId != null) 'standard_id': standardId,
        if (subjectId != null) 'subject_id': subjectId,
        if (academicYearId != null) 'academic_year_id': academicYearId,
      },
    );
    return DiaryListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Create diary entry (TEACHER only) ─────────────────────────────────────

  Future<DiaryModel> createDiary({
    required String standardId,
    required String subjectId,
    required String topicCovered,
    String? homeworkNote,
    String? date, // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? academicYearId, // backend uses active year if omitted
  }) async {
    final body = <String, dynamic>{
      'standard_id': standardId,
      'subject_id': subjectId,
      'topic_covered': topicCovered,
      if (homeworkNote != null && homeworkNote.isNotEmpty)
        'homework_note': homeworkNote,
      if (date != null) 'date': date,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    try {
      final response = await _dio.post(_base, data: body);
      return DiaryModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg = '';
      if (data is Map<String, dynamic>) {
        final rawMsg = data['message'] ?? data['detail'];
        msg = rawMsg?.toString() ?? '';
      } else if (data != null) {
        msg = data.toString();
      }

      // Compatibility fallback for strict/stale backend validators.
      final isNoneBodyValidation =
          e.response?.statusCode == 422 && msg.contains('Input should be None');
      if (!isNoneBodyValidation) rethrow;

      try {
        final wrappedResponse =
            await _dio.post(_base, data: {'payload': body});
        return DiaryModel.fromJson(
            wrappedResponse.data as Map<String, dynamic>);
      } on DioException {
        final explicitResponse = await _dio.post('$_base/create', data: body);
        return DiaryModel.fromJson(
            explicitResponse.data as Map<String, dynamic>);
      }
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.read(dioClientProvider));
});
