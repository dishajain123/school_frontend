import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/assignment/assignment_model.dart';

class AssignmentRepository {
  const AssignmentRepository(this._dio);
  final Dio _dio;

  static const String _base = '/assignments';

  Future<AssignmentListResponse> listAssignments({
    String? standardId,
    String? subjectId,
    String? academicYearId,
    bool? isActive,
    bool? isOverdue,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      if (standardId != null) 'standard_id': standardId,
      if (subjectId != null) 'subject_id': subjectId,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (isActive != null) 'is_active': isActive,
      if (isOverdue != null) 'is_overdue': isOverdue,
    };

    final response = await _dio.get(
      _base,
      queryParameters: queryParams,
    );
    return AssignmentListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AssignmentModel> getById(String assignmentId) async {
    final response = await _dio.get('$_base/$assignmentId');
    return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssignmentModel> createAssignment({
    required String title,
    required String standardId,
    required String subjectId,
    required DateTime dueDate,
    required String academicYearId,
    String? description,
    MultipartFile? file,
  }) async {
    final formData = FormData.fromMap({
      'title': title,
      'standard_id': standardId,
      'subject_id': subjectId,
      'due_date':
          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      'academic_year_id': academicYearId,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (file != null) 'file': file,
    });

    final response = await _dio.post(
      _base,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AssignmentModel> updateAssignment(
    String assignmentId, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isActive,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (dueDate != null)
        'due_date':
            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
      if (isActive != null) 'is_active': isActive,
    };

    final response = await _dio.patch(
      '$_base/$assignmentId',
      data: body,
    );
    return AssignmentModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.read(dioClientProvider));
});
