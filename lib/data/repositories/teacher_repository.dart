import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/teacher/teacher_class_subject_model.dart';
import '../models/teacher/teacher_model.dart';

class TeacherListResult {
  const TeacherListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<TeacherModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory TeacherListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return TeacherListResult(
      items: rawItems
          .map((e) => TeacherModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}

class TeacherRepository {
  const TeacherRepository(this._dio);
  final Dio _dio;

  Future<TeacherListResult> list({
    String? academicYearId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (academicYearId != null) {
      params['academic_year_id'] = academicYearId;
    }

    final response = await _dio.get(
      ApiConstants.teachers,
      queryParameters: params,
    );
    return TeacherListResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeacherModel> getById(String teacherId) async {
    final response = await _dio.get(ApiConstants.teacherById(teacherId));
    return TeacherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeacherModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.teachers, data: payload);
    return TeacherModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeacherModel> update(String teacherId, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.teacherById(teacherId),
      data: payload,
    );
    return TeacherModel.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Repository for teacher's own class-subject assignments.
/// Used by MarkAttendanceScreen to populate class and subject dropdowns.
/// Endpoint assumed: GET /api/v1/teacher-class-subjects/mine
class TeacherClassSubjectRepository {
  const TeacherClassSubjectRepository(this._dio);
  final Dio _dio;

  Future<List<TeacherClassSubjectModel>> getMyAssignments({
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      '/api/v1/teacher-class-subjects/mine',
      queryParameters: {
        if (academicYearId != null) 'academic_year_id': academicYearId,
      },
    );
    final data = response.data;
    // Support both direct list and paginated wrapper { items: [...] }
    final List<dynamic> raw = data is List ? data : (data['items'] as List);
    return raw
        .map((e) =>
            TeacherClassSubjectModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref.read(dioClientProvider));
});

final teacherClassSubjectRepositoryProvider =
    Provider<TeacherClassSubjectRepository>((ref) {
  return TeacherClassSubjectRepository(ref.read(dioClientProvider));
});
