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
  }) async {
    final body = <String, dynamic>{
      'student_id': studentId,
      'document_type': documentType.backendValue,
      if (academicYearId != null) 'academic_year_id': academicYearId,
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
      'file': multipartFile,
    });
    final response = await _dio.post(ApiConstants.documentUpload, data: data);
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /documents?student_id={id} ─────────────────────────────────────────
  // Permission: document:generate
  // Backend enforces RBAC — STUDENT sees only own, PARENT sees only child's

  Future<DocumentListResponse> listDocuments(String studentId) async {
    final response = await _dio.get(
      ApiConstants.documents,
      queryParameters: {'student_id': studentId},
    );
    return DocumentListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // ── GET /documents/{document_id}/download ───────────────────────────────────
  // Permission: document:generate
  // Returns { status, url? } — url is a presigned MinIO URL (short-lived)
  // Only populated when status == READY

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
  }) async {
    final response = await _dio.patch(
      ApiConstants.documentVerify(documentId),
      data: {'approve': approve},
    );
    return DocumentModel.fromJson(response.data as Map<String, dynamic>);
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(ref.read(dioClientProvider));
});
