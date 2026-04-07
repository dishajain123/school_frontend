import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/parent/child_summary.dart';
import '../models/parent/parent_model.dart';

class ParentListResult {
  const ParentListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<ParentModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  factory ParentListResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ParentListResult(
      items: rawItems
          .map((e) => ParentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}

class ParentRepository {
  const ParentRepository(this._dio);
  final Dio _dio;

  Future<ParentListResult> list({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      ApiConstants.parents,
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return ParentListResult.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ParentModel> getById(String parentId) async {
    final response = await _dio.get(ApiConstants.parentById(parentId));
    return ParentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ParentModel> create(Map<String, dynamic> payload) async {
    final response = await _dio.post(ApiConstants.parents, data: payload);
    return ParentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ParentModel> update(
      String parentId, Map<String, dynamic> payload) async {
    final response = await _dio.patch(
      ApiConstants.parentById(parentId),
      data: payload,
    );
    return ParentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ChildSummaryModel>> getChildren(String parentId) async {
    final response = await _dio.get(ApiConstants.parentChildren(parentId));
    final data = response.data as Map<String, dynamic>;
    final items = data['children'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChildSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChildSummaryModel>> assignChildren(
    String parentId,
    List<String> studentIds,
  ) async {
    final response = await _dio.patch(
      ApiConstants.parentChildren(parentId),
      data: {'student_ids': studentIds},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['children'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChildSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChildSummaryModel>> getMyChildren() async {
    final response = await _dio.get(ApiConstants.myChildren);
    final data = response.data as Map<String, dynamic>;
    final items = data['children'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChildSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChildSummaryModel>> linkMyChild({
    String? studentId,
    String? admissionNumber,
    String? studentEmail,
    String? studentPhone,
    String? studentPassword,
  }) async {
    final response = await _dio.post(
      ApiConstants.myChildrenLink,
      data: {
        if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
        if (admissionNumber != null && admissionNumber.isNotEmpty)
          'admission_number': admissionNumber,
        if (studentEmail != null && studentEmail.isNotEmpty)
          'student_email': studentEmail,
        if (studentPhone != null && studentPhone.isNotEmpty)
          'student_phone': studentPhone,
        if (studentPassword != null && studentPassword.isNotEmpty)
          'student_password': studentPassword,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['children'] as List<dynamic>? ?? [];
    return items
        .map((e) => ChildSummaryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository(ref.read(dioClientProvider));
});
