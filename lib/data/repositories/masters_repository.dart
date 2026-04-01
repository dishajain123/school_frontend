import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/masters/grade_master_model.dart';
import '../models/masters/standard_model.dart';
import '../models/masters/subject_model.dart';

class MastersRepository {
  const MastersRepository(this._dio);
  final Dio _dio;

  // ── Standards ─────────────────────────────────────────────────────────────

  Future<List<StandardModel>> listStandards({String? academicYearId}) async {
    final params = <String, dynamic>{};
    if (academicYearId != null) params['academic_year_id'] = academicYearId;
    final response = await _dio.get(ApiConstants.standards, queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => StandardModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StandardModel> createStandard(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.standards, data: payload);
    return StandardModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<StandardModel> updateStandard(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(ApiConstants.standardById(id), data: payload);
    return StandardModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteStandard(String id) async {
    await _dio.delete(ApiConstants.standardById(id));
  }

  // ── Subjects ──────────────────────────────────────────────────────────────

  Future<List<SubjectModel>> listSubjects({String? standardId}) async {
    final params = <String, dynamic>{};
    if (standardId != null) params['standard_id'] = standardId;
    final response = await _dio.get(ApiConstants.subjects, queryParameters: params);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => SubjectModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SubjectModel> createSubject(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.subjects, data: payload);
    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SubjectModel> updateSubject(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(ApiConstants.subjectById(id), data: payload);
    return SubjectModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSubject(String id) async {
    await _dio.delete(ApiConstants.subjectById(id));
  }

  // ── Grade Master ──────────────────────────────────────────────────────────

  Future<List<GradeMasterModel>> listGrades() async {
    final response = await _dio.get(ApiConstants.grades);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items.map((e) => GradeMasterModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GradeMasterModel> createGrade(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.grades, data: payload);
    return GradeMasterModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<GradeMasterModel> updateGrade(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(ApiConstants.gradeById(id), data: payload);
    return GradeMasterModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteGrade(String id) async {
    await _dio.delete(ApiConstants.gradeById(id));
  }

  Future<GradeMasterModel?> lookupGrade(double percent) async {
    try {
      final response = await _dio.get(ApiConstants.gradesLookup, queryParameters: {'percent': percent});
      return GradeMasterModel.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

final mastersRepositoryProvider = Provider<MastersRepository>((ref) {
  return MastersRepository(ref.read(dioClientProvider));
});