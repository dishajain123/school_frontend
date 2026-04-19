import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/diary/diary_model.dart';

class DiaryRepository {
  const DiaryRepository(this._dio);
  final Dio _dio;

  static const String _base = ApiConstants.diary;

  Future<DiaryListResponse> listDiary({
    String? date,
    String? standardId,
    String? subjectId,
    String? academicYearId,
    int page = 1,
    int pageSize = 100,
  }) async {
    // Guard: never send empty strings as UUID query params — FastAPI's UUID
    // parser will reject them with a 422 before our code even runs.
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (date != null && date.isNotEmpty) queryParams['date'] = date;
    if (standardId != null && standardId.isNotEmpty)
      queryParams['standard_id'] = standardId;
    if (subjectId != null && subjectId.isNotEmpty)
      queryParams['subject_id'] = subjectId;
    if (academicYearId != null && academicYearId.isNotEmpty)
      queryParams['academic_year_id'] = academicYearId;

    final response = await _dio.get(_base, queryParameters: queryParams);
    return DiaryListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DiaryModel> createDiary({
    required String standardId,
    required String subjectId,
    required String topicCovered,
    String? homeworkNote,
    String? date,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{
      'standard_id': standardId,
      'subject_id': subjectId,
      'topic_covered': topicCovered,
      if (homeworkNote != null && homeworkNote.isNotEmpty)
        'homework_note': homeworkNote,
      if (date != null && date.isNotEmpty) 'date': date,
      if (academicYearId != null && academicYearId.isNotEmpty)
        'academic_year_id': academicYearId,
    };

    final response = await _dio.post(
      _base,
      data: body,
      options: Options(contentType: 'application/json'),
    );
    return DiaryModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  return DiaryRepository(ref.read(dioClientProvider));
});