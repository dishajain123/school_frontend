import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../models/timetable/timetable_model.dart';

class TimetableRepository {
  const TimetableRepository(this._dio);
  final Dio _dio;

  static const String _base = '/api/v1/timetable';

  // ── GET timetable ──────────────────────────────────────────────────────────

  Future<TimetableModel> getTimetable({
    required String standardId,
    String? academicYearId,
    String? section,
  }) async {
    final response = await _dio.get(
      '$_base/$standardId',
      queryParameters: {
        if (academicYearId != null) 'academic_year_id': academicYearId,
        if (section != null) 'section': section,
      },
    );
    return TimetableModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── POST upload timetable (PRINCIPAL only) ─────────────────────────────────

  Future<TimetableModel> uploadTimetable({
    required String standardId,
    required File file,
    String? academicYearId,
    String? section,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'standard_id': standardId,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (section != null) 'section': section,
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      _base,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TimetableModel.fromJson(response.data as Map<String, dynamic>);
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.read(dioClientProvider));
});