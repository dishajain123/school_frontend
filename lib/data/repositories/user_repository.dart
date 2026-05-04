import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/auth/current_user.dart';
import '../models/user/user_model.dart';

class UserRepository {
  const UserRepository(this._dio);
  final Dio _dio;

  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.usersMe);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Most deployments do not expose /users/me; fall back to auth/profile APIs.
      final status = e.response?.statusCode;
      if (status != 404 && status != 405) rethrow;
    }

    final authMeResp = await _dio.get(ApiConstants.authMe);
    final authMe = Map<String, dynamic>.from(authMeResp.data as Map);

    Map<String, dynamic>? profile;
    try {
      final profileResp = await _dio.get(ApiConstants.profileMe);
      profile = Map<String, dynamic>.from(profileResp.data as Map);
    } on DioException catch (_) {
      profile = null;
    }

    return _buildFromAuthMe(authMe, profile: profile);
  }

  Future<UserModel> updateMe({String? phone}) async {
    final data = <String, dynamic>{};
    if (phone != null) data['phone'] = phone;
    final response = await _dio.patch(ApiConstants.usersMe, data: data);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(
      String userId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: file.path.split('/').last),
    });
    final response = await _dio.post(
      ApiConstants.userPhoto(userId),
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  UserModel _buildFromAuthMe(
    Map<String, dynamic> authMe, {
    Map<String, dynamic>? profile,
  }) {
    final roleValue = (authMe['role'] ?? '').toString().trim().toUpperCase();
    final userPayload = profile != null
        ? Map<String, dynamic>.from((profile['user'] as Map?) ?? const {})
        : const <String, dynamic>{};
    final profilePayload = profile != null
        ? Map<String, dynamic>.from((profile['profile'] as Map?) ?? const {})
        : const <String, dynamic>{};

    final now = DateTime.now();
    return UserModel(
      id: (authMe['id'] ?? userPayload['id'] ?? '').toString(),
      email: (userPayload['email'] ?? authMe['email'])?.toString(),
      phone: (userPayload['phone'] ?? authMe['phone'])?.toString(),
      role: UserRoleX.fromBackend(roleValue),
      schoolId: (authMe['school_id'] ?? authMe['schoolId'])?.toString(),
      isActive: (authMe['is_active'] as bool?) ?? true,
      // auth/me doesn't include these timestamps; use safe defaults.
      createdAt: DateTime.tryParse((authMe['created_at'] ?? '').toString()) ?? now,
      updatedAt: DateTime.tryParse((authMe['updated_at'] ?? '').toString()) ?? now,
      profilePhotoKey: (userPayload['profile_photo_key'] ?? profilePayload['profile_photo_key'])
          ?.toString(),
      profilePhotoUrl: (userPayload['profile_photo_url'] ?? profilePayload['profile_photo_url'])
          ?.toString(),
    );
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioClientProvider));
});