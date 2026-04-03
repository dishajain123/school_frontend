import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/behaviour/behaviour_log_model.dart';

class BehaviourRepository {
  const BehaviourRepository(this._dio);
  final Dio _dio;

  Future<BehaviourLogListResponse> list(String studentId) async {
    final response = await _dio.get(
      ApiConstants.behaviour,
      queryParameters: {'student_id': studentId},
    );
    return BehaviourLogListResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<BehaviourLogModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiConstants.behaviour,
      data: payload,
    );
    return BehaviourLogModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final behaviourRepositoryProvider = Provider<BehaviourRepository>((ref) {
  return BehaviourRepository(ref.read(dioClientProvider));
});
