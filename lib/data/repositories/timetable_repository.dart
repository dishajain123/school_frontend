import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/timetable/timetable_model.dart';

class TimetableRepository {
  const TimetableRepository(this._dio);
  final Dio _dio;

  static const String _base = ApiConstants.timetable;

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
    required PlatformFile file,
    String? academicYearId,
    String? section,
  }) async {
    final fileName = file.name;
    MultipartFile multipartFile;
    if (file.bytes != null) {
      multipartFile = MultipartFile.fromBytes(
        file.bytes!,
        filename: fileName,
      );
    } else if (file.path != null) {
      multipartFile = await MultipartFile.fromFile(
        file.path!,
        filename: fileName,
      );
    } else {
      throw Exception('Selected file has no readable bytes/path');
    }

    final formData = FormData.fromMap({
      'standard_id': standardId,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (section != null) 'section': section,
      'file': multipartFile,
    });

    final response = await _dio.post(
      _base,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return TimetableModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<String>> listSections({
    required String standardId,
    String? academicYearId,
  }) async {
    final query = <String, dynamic>{
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };

    try {
      final response = await _dio.get(
        ApiConstants.timetableSections(standardId),
        queryParameters: query,
      );
      final data = response.data as List<dynamic>? ?? const [];
      return data.map((e) => e.toString()).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && e.response?.statusCode != 422) {
        rethrow;
      }
    }

    // Compatibility fallback for backends exposing:
    // /timetable/sections?standard_id=<id>&academic_year_id=<id>
    final fallback = await _dio.get(
      '/timetable/sections',
      queryParameters: {
        'standard_id': standardId,
        ...query,
      },
    );
    final data = fallback.data as List<dynamic>? ?? const [];
    return data.map((e) => e.toString()).toList();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository(ref.read(dioClientProvider));
});
