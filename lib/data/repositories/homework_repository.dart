import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/homework/homework_model.dart';

class HomeworkRepository {
  const HomeworkRepository(this._dio);
  final Dio _dio;

  // Matches FastAPI router prefix + app mount: /api/v1/homework
  static const String _base = '/api/v1/homework';

  // ── List homework ──────────────────────────────────────────────────────────

  Future<HomeworkListResponse> listHomework({
    String? date,          // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? standardId,    // UUID string
    String? subjectId,     // UUID string — optional subject filter
    String? academicYearId, // UUID string — backend uses active year if omitted
    int page = 1,
    int pageSize = 20,
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
    return HomeworkListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  // ── Create homework (TEACHER only) ────────────────────────────────────────

  Future<HomeworkModel> createHomework({
    required String standardId,
    required String subjectId,
    required String description,
    String? date,          // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? academicYearId, // backend uses active year if omitted
  }) async {
    final body = <String, dynamic>{
      'standard_id': standardId,
      'subject_id': subjectId,
      'description': description,
      if (date != null) 'date': date,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    final response = await _dio.post(_base, data: body);
    return HomeworkModel.fromJson(response.data as Map<String, dynamic>);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(ref.read(dioClientProvider));
});