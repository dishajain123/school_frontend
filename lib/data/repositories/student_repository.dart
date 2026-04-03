import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/student/student_model.dart';

class StudentListResult {
  const StudentListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<StudentModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory StudentListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return StudentListResult(
      items: rawItems
          .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}

class StudentRepository {
  const StudentRepository(this._dio);
  final Dio _dio;

  Future<StudentListResult> list({
    String? standardId,
    String? section,
    String? academicYearId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (standardId != null) params['standard_id'] = standardId;
    if (section != null) params['section'] = section;
    if (academicYearId != null) params['academic_year_id'] = academicYearId;

    final response = await _dio.get(
      ApiConstants.students,
      queryParameters: params,
    );
    return StudentListResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentModel> getById(String studentId) async {
    final response = await _dio.get(ApiConstants.studentById(studentId));
    return StudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.students, data: payload);
    return StudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentModel> update(
      String studentId, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.studentById(studentId),
      data: payload,
    );
    return StudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StudentModel> updatePromotionStatus(
      String studentId, String promotionStatus) async {
    final response = await _dio.patch(
      ApiConstants.studentPromotionStatus(studentId),
      data: {'promotion_status': promotionStatus},
    );
    return StudentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> listSections({
    String? standardId,
    String? academicYearId,
  }) async {
    final response = await _dio.get(
      ApiConstants.studentSections,
      queryParameters: {
        if (standardId != null) 'standard_id': standardId,
        if (academicYearId != null) 'academic_year_id': academicYearId,
      },
    );
    final data = response.data as List<dynamic>? ?? const [];
    return data.map((e) => e.toString()).toList();
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(ref.read(dioClientProvider));
});
