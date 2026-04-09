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
    String? standardId,
    String? subjectId,
    String? subjectName,
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
    if (standardId != null) {
      params['standard_id'] = standardId;
    }
    if (subjectId != null) {
      params['subject_id'] = subjectId;
    }
    if (subjectName != null && subjectName.trim().isNotEmpty) {
      params['subject_name'] = subjectName.trim();
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

  Future<TeacherModel> update(
      String teacherId, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.teacherById(teacherId),
      data: payload,
    );
    return TeacherModel.fromJson(response.data as Map<String, dynamic>);
  }
}

/// Repository for teacher's own class-subject assignments.
/// Used by MarkAttendanceScreen to populate class and subject dropdowns.
/// Endpoint: GET /teacher-assignments/mine
class TeacherClassSubjectRepository {
  const TeacherClassSubjectRepository(this._dio);
  final Dio _dio;

  List<TeacherClassSubjectModel> _parseList(dynamic data) {
    final List<dynamic> raw = data is List ? data : (data['items'] as List);
    return raw
        .map(
          (e) => TeacherClassSubjectModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<TeacherClassSubjectModel>> getMyAssignments({
    String? academicYearId,
  }) async {
    final query = <String, dynamic>{
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    try {
      final response = await _dio.get(
        '/teacher-assignments/mine',
        queryParameters: query,
      );
      return _parseList(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    try {
      // Backward compatibility for older backend route naming.
      final fallback = await _dio.get(
        '/teacher-class-subjects/mine',
        queryParameters: query,
      );
      return _parseList(fallback.data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    // Last fallback for setups that expose this via /teachers module.
    final legacy = await _dio.get(
      '/teachers/me/assignments',
      queryParameters: query,
    );
    return _parseList(legacy.data);
  }

  Future<List<TeacherClassSubjectModel>> listByTeacher({
    required String teacherId,
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      ApiConstants.teacherAssignments,
      queryParameters: {
        'teacher_id': teacherId,
        if (academicYearId != null) 'academic_year_id': academicYearId,
      },
    );
    return _parseList(response.data);
  }

  Future<List<TeacherClassSubjectModel>> listByClass({
    required String standardId,
    required String section,
    String? academicYearId,
  }) async {
    final query = <String, dynamic>{
      'standard_id': standardId,
      'section': section,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    try {
      final response = await _dio.get(
        ApiConstants.teacherAssignments,
        queryParameters: query,
      );
      return _parseList(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
    }

    final legacy = await _dio.get(
      '/teacher-class-subjects',
      queryParameters: query,
    );
    return _parseList(legacy.data);
  }

  Future<TeacherClassSubjectModel> createAssignment({
    required String teacherId,
    required String standardId,
    required String section,
    required String subjectId,
    required String academicYearId,
  }) async {
    final response = await _dio.post(
      ApiConstants.teacherAssignments,
      data: {
        'teacher_id': teacherId,
        'standard_id': standardId,
        'section': section,
        'subject_id': subjectId,
        'academic_year_id': academicYearId,
      },
    );
    return TeacherClassSubjectModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<TeacherClassSubjectModel> updateAssignment({
    required String assignmentId,
    required String standardId,
    required String section,
    required String subjectId,
    required String academicYearId,
  }) async {
    final response = await _dio.patch(
      ApiConstants.teacherAssignmentById(assignmentId),
      data: {
        'standard_id': standardId,
        'section': section,
        'subject_id': subjectId,
        'academic_year_id': academicYearId,
      },
    );
    return TeacherClassSubjectModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteAssignment(String assignmentId) async {
    await _dio.delete(ApiConstants.teacherAssignmentById(assignmentId));
  }
}

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository(ref.read(dioClientProvider));
});

final teacherClassSubjectRepositoryProvider =
    Provider<TeacherClassSubjectRepository>((ref) {
  return TeacherClassSubjectRepository(ref.read(dioClientProvider));
});
