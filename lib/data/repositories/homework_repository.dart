import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/homework/homework_model.dart';
import '../models/homework/homework_submission_model.dart';

class HomeworkRepository {
  const HomeworkRepository(this._dio);
  final Dio _dio;

  // Dio already includes /api/v1 in its baseUrl.
  static const String _base = '/homework';

  // ── List homework ──────────────────────────────────────────────────────────

  Future<HomeworkListResponse> listHomework({
    String? date, // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? standardId, // UUID string
    String? subjectId, // UUID string — optional subject filter
    String? academicYearId, // UUID string — backend uses active year if omitted
    bool? isSubmitted,
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
        if (isSubmitted != null) 'is_submitted': isSubmitted,
      },
    );
    return HomeworkListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Create homework (TEACHER only) ────────────────────────────────────────

  Future<HomeworkModel> createHomework({
    required String standardId,
    required String subjectId,
    String? description,
    String? date, // ISO "yyyy-MM-dd" — backend defaults to today if omitted
    String? academicYearId, // backend uses active year if omitted
    MultipartFile? file,
  }) async {
    final formData = FormData.fromMap({
      'standard_id': standardId,
      'subject_id': subjectId,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      if (date != null) 'date': date,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (file != null) 'file': file,
    });

    final response = await _dio.post(
      _base,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return HomeworkModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Homework responses (student/parent submit, teacher review) ───────────

  Future<HomeworkSubmissionModel> createResponse({
    required String homeworkId,
    String? textResponse,
    String? studentId,
    MultipartFile? file,
  }) async {
    final formData = FormData.fromMap({
      'homework_id': homeworkId,
      if (textResponse != null && textResponse.trim().isNotEmpty)
        'text_response': textResponse.trim(),
      if (studentId != null) 'student_id': studentId,
      if (file != null) 'file': file,
    });
    final response = await _dio.post(
      '$_base/responses',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return HomeworkSubmissionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<HomeworkSubmissionListResponse> listResponses({
    required String homeworkId,
    String? studentId,
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '$_base/$homeworkId/responses',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (studentId != null) 'student_id': studentId,
      },
    );
    return HomeworkSubmissionListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<HomeworkSubmissionModel> reviewResponse({
    required String submissionId,
    String? feedback,
    bool? isApproved,
  }) async {
    final response = await _dio.patch(
      '$_base/responses/$submissionId/review',
      data: {
        if (feedback != null) 'feedback': feedback,
        if (isApproved != null) 'is_approved': isApproved,
      },
    );
    return HomeworkSubmissionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final homeworkRepositoryProvider = Provider<HomeworkRepository>((ref) {
  return HomeworkRepository(ref.read(dioClientProvider));
});
