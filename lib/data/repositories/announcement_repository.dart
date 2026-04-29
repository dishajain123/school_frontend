import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/announcement/announcement_model.dart';

class AnnouncementRepository {
  const AnnouncementRepository(this._dio);
  final Dio _dio;

  Future<List<AnnouncementModel>> list({
    bool includeInactive = false,
    String? targetRole,
    String? targetStandardId,
  }) async {
    final response = await _dio.get(
      ApiConstants.announcements,
      queryParameters: {
        'include_inactive': includeInactive,
        if (targetRole != null && targetRole.trim().isNotEmpty) 'target_role': targetRole,
        if (targetStandardId != null && targetStandardId.trim().isNotEmpty) 'target_standard_id': targetStandardId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => AnnouncementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnnouncementModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.announcements, data: payload);
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AnnouncementModel> update(String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.announcementById(id),
      data: payload,
    );
    return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiConstants.announcementById(id));
  }

  Future<AnnouncementModel?> getById(String id) async {
    try {
      final response = await _dio.get(ApiConstants.announcementById(id));
      return AnnouncementModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
}

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository(ref.read(dioClientProvider));
});