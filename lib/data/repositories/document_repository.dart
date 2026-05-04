import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/document/document_model.dart';

class DocumentRepository {
  const DocumentRepository(this._dio);
  final Dio _dio;

  // ── POST /documents/request ─────────────────────────────────────────────────
  // Permission: document:generate
  // STUDENT: can only request for themselves
  // PARENT: can only request for their children
  // PRINCIPAL/TRUSTEE/TEACHER: can request for any student in their school

  Future<DocumentModel> requestDocument({
    required String studentId,
    required DocumentType documentType,
    String? academicYearId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'document_type': documentType.backendValue,
      if (academicYearId != null) 'academic_year_id': academicYearId,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };
    final response = await _dio.post(
      ApiConstants.documentRequest,
      data: body,
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DocumentModel> uploadDocument({
    required String studentId,
    required DocumentType documentType,
    required PlatformFile file,
    String? note,
  }) async {
    if ((file.bytes == null || file.bytes!.isEmpty) &&
        (file.path == null || file.path!.isEmpty)) {
      throw const FormatException('Selected file is empty or unavailable');
    }
    final multipartFile = file.bytes != null
        ? MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          )
        : await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          );

    final data = FormData.fromMap({
      'student_id': studentId,
      'document_type': documentType.backendValue,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      'file': multipartFile,
    });
    final response = await _dio.post(ApiConstants.documentUpload, data: data);
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /documents?student_id={id} ─────────────────────────────────────────
  // Permission: document:generate
  // Backend enforces RBAC — STUDENT sees only own, PARENT sees only child's

  Future<DocumentListResponse> listDocuments(
    String? studentId, {
    DocumentListStatusFilter statusFilter = DocumentListStatusFilter.all,
  }) async {
    final qp = <String, dynamic>{
      if (studentId != null && studentId.isNotEmpty) 'student_id': studentId,
      if (statusFilter.statusQueryParam != null)
        'status': statusFilter.statusQueryParam,
    };
    final response = await _dio.get(
      ApiConstants.documents,
      queryParameters: qp.isEmpty ? null : qp,
    );
    return DocumentListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /documents/{document_id}/download ───────────────────────────────────
  // Permission: document:generate
  // Returns { status, url? } — url is a presigned MinIO URL (short-lived).
  // Populated when a file exists (including PROCESSING / FAILED for review).

  Future<DocumentDownloadResponse> downloadDocument(String documentId) async {
    final response = await _dio.get(
      ApiConstants.documentDownload(documentId),
    );
    return DocumentDownloadResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<DocumentModel> verifyDocument({
    required String documentId,
    required bool approve,
    String? reason,
  }) async {
    final response = await _dio.patch(
      ApiConstants.documentVerify(documentId),
      data: {
        'approve': approve,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RequiredDocumentModel>> listRequiredDocuments() async {
    final response = await _dio.get(ApiConstants.documentRequirements);
    final items =
        (response.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
            const [];
    return items
        .map((e) => RequiredDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RequiredDocumentModel>> upsertRequiredDocuments(
    List<RequiredDocumentModel> items,
  ) async {
    final response = await _dio.put(
      ApiConstants.documentRequirements,
      data: {
        'items': items.map((e) => e.toJson()).toList(),
      },
    );
    final raw =
        (response.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
            const [];
    return raw
        .map((e) => RequiredDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RequiredDocumentStatusModel>> listRequiredStatusForStudent(
      String studentId) async {
    final response = await _dio.get(
      ApiConstants.documentRequirementStatus,
      queryParameters: {'student_id': studentId},
    );
    final raw = response.data as List<dynamic>? ?? const [];
    return raw
        .map((e) =>
            RequiredDocumentStatusModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.read(dioClientProvider));
});
