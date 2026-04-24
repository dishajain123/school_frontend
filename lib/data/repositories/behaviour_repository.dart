import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/behaviour/behaviour_log_model.dart';

class BehaviourRepository {
  const BehaviourRepository(this._dio);
  final Dio _dio;

  Future<BehaviourLogListResponse> list({
    String? studentId,
    IncidentType? incidentType,
    String? standardId,
    String? section,
  }) async {
    final response = await _dio.get(
      ApiConstants.behaviour,
      queryParameters: {
        if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
        if (incidentType != null) 'incident_type': incidentType.backendValue,
        if (standardId != null && standardId.isNotEmpty) 'standard_id': standardId,
        if (section != null && section.isNotEmpty) 'section': section,
      },
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
