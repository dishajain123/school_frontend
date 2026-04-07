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
      final status = e.response?.statusCode;
      if (!_shouldFallbackCreate(e.response?.data, status)) {
        rethrow;
      }

      // Backward compatibility for deployments exposing create at /diary/create.
      final fallback = await _dio.post('$_base/create', data: body);
      return DiaryModel.fromJson(fallback.data as Map<String, dynamic>);
    }
  }

  bool _shouldFallbackCreate(dynamic responseData, int? statusCode) {
    if (statusCode == 404 || statusCode == 405) return true;
    if (statusCode != 422) return false;

    final map = responseData is Map<String, dynamic> ? responseData : null;
    final detail = map?['detail'];
    if (detail is String) {
      final msg = detail.toLowerCase();
      if (msg.contains('input should be none')) return true;
      return msg.contains('input') &&
          (msg.contains('required') || msg.contains('not found'));
    }

    if (detail is List) {
      for (final item in detail) {
        if (item is! Map) continue;
        final msg = item['msg']?.toString().toLowerCase() ?? '';
        if (msg.contains('input should be none')) return true;
        final loc = item['loc'];
        if (loc is List &&
            loc.any((p) => p.toString().toLowerCase() == 'input')) {
          return true;
        }
      }
    }
    return false;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.read(dioClientProvider));
});
