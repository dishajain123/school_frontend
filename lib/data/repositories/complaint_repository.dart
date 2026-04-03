import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/complaint/complaint_model.dart';

class ComplaintRepository {
  const ComplaintRepository(this._dio);
  final Dio _dio;

  Future<ComplaintListResponse> list({ComplaintStatus? status}) async {
    final response = await _dio.get(
      ApiConstants.complaints,
      queryParameters: {
        if (status != null) 'status': status.backendValue,
      },
    );
    return ComplaintListResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<ComplaintModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiConstants.complaints,
      data: payload,
    );
    return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ComplaintModel> updateStatus(
      String id, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.complaintStatus(id),
      data: payload,
    );
    return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FeedbackModel> createFeedback(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiConstants.feedback,
      data: payload,
    );
    return FeedbackModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepository(ref.read(dioClientProvider));
});
