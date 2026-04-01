import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/academic_year/academic_year_model.dart';

class AcademicYearRepository {
  const AcademicYearRepository(this._dio);
  final Dio _dio;

  Future<List<AcademicYearModel>> list() async {
    final response = await _dio.get(ApiConstants.academicYears);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AcademicYearModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AcademicYearModel> create(Map<String, dynamic> payload) async {
    final response =
        await _dio.post(ApiConstants.academicYears, data: payload);
    return AcademicYearModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AcademicYearModel> update(
      String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
        ApiConstants.academicYearById(id),
        data: payload);
    return AcademicYearModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<AcademicYearModel> activate(String id) async {
    final response =
        await _dio.patch(ApiConstants.academicYearActivate(id));
    return AcademicYearModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<Map<String, int>> rollover(
      String oldYearId, {
      String? newYearId,
    }) async {
    final uri = newYearId != null
        ? '${ApiConstants.academicYearRollover(oldYearId)}?new_year_id=$newYearId'
        : ApiConstants.academicYearRollover(oldYearId);
    final response = await _dio.post(uri);
    final data = response.data as Map<String, dynamic>;
    return {
      'processed': data['processed'] as int? ?? 0,
      'skipped': data['skipped'] as int? ?? 0,
    };
  }
}

final academicYearRepositoryProvider =
    Provider<AcademicYearRepository>((ref) {
  return AcademicYearRepository(ref.read(dioClientProvider));
});