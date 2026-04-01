import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/user/user_model.dart';

class UserRepository {
  const UserRepository(this._dio);
  final Dio _dio;

  Future<UserModel> getMe() async {
    final response = await _dio.get(ApiConstants.usersMe);
    return UserModel.fromJson(response.data as Map<String, dynamic>);
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
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(ref.read(dioClientProvider));
});