import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/school/school_model.dart';

class SchoolRepository {
  const SchoolRepository(this._dio);
  final Dio _dio;

  Future<SchoolListResponse> list({
    bool? isActive,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      ApiConstants.schools,
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        if (isActive != null) 'is_active': isActive,
      },
    );
    return SchoolListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiConstants.schools,
      data: payload,
    );
    return SchoolModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolModel> getById(String id) async {
    final response = await _dio.get(ApiConstants.schoolById(id));
    return SchoolModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.schoolById(id),
      data: payload,
    );
    return SchoolModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolModel> deactivate(String id) async {
    final response = await _dio.patch(ApiConstants.schoolDeactivate(id));
    return SchoolModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SchoolSettingsListResponse> listSettings() async {
    final response = await _dio.get(ApiConstants.settings);
    return SchoolSettingsListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<SchoolSettingsListResponse> updateSettings(
    List<SchoolSettingModel> items,
  ) async {
    final response = await _dio.patch(
      ApiConstants.settings,
      data: {
        'items': items
            .map(
              (item) => {
                'key': item.settingKey,
                'value': item.settingValue,
              },
            )
            .toList(),
      },
    );
    return SchoolSettingsListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(ref.read(dioClientProvider));
});
