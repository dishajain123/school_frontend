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
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      _base,
      queryParameters: {
        'assignment_id': assignmentId,
        'page': page,
        'page_size': pageSize,
      },
    );
    return SubmissionListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    required String grade,
    String? feedback,
  }) async {
    final response = await _dio.patch(
      '$_base/$submissionId/grade',
      data: {
        'grade': grade,
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      },
    );
    return SubmissionModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(ref.read(dioClientProvider));
});
