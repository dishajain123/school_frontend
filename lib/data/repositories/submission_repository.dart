import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/assignment/submission_model.dart';

class SubmissionRepository {
  const SubmissionRepository(this._dio);
  final Dio _dio;

  static const String _base = '/submissions';

  Future<SubmissionModel> createSubmission({
    required String assignmentId,
    required String studentId,
    String? textResponse,
    MultipartFile? file,
  }) async {
    final formData = FormData.fromMap({
      'assignment_id': assignmentId,
      'student_id': studentId,
      if (textResponse != null && textResponse.isNotEmpty)
        'text_response': textResponse,
      if (file != null) 'file': file,
    });

    final response = await _dio.post(
      _base,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubmissionListResponse> listSubmissions({
    required String assignmentId,
    String? studentId,
    String? standardId,
    String? subjectId,
    String? section,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'assignment_id': assignmentId,
        if (studentId != null) 'student_id': studentId,
        if (standardId != null) 'standard_id': standardId,
        if (subjectId != null) 'subject_id': subjectId,
        if (section != null && section.isNotEmpty) 'section': section,
        'page': page,
        'page_size': pageSize,
      },
    );
    return SubmissionListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    String? grade,
    String? feedback,
    bool? isApproved,
  }) async {
    final body = <String, dynamic>{
      if (grade != null && grade.trim().isNotEmpty) 'grade': grade.trim(),
      if (feedback != null) 'feedback': feedback.trim(),
      if (isApproved != null) 'is_approved': isApproved,
    };

    try {
      final response = await _dio.patch(
        '$_base/$submissionId/review',
        data: body,
      );
      return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      final fallback = await _dio.patch(
        '$_base/$submissionId/grade',
        data: body,
      );
      return SubmissionModel.fromJson(fallback.data as Map<String, dynamic>);
    }
  }
}

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(ref.read(dioClientProvider));
});
