// lib/data/repositories/enrollment_repository.dart
// Phase 6 & 7 — repository calling enrollment and promotion backend APIs.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/enrollment/enrollment_model.dart';

class EnrollmentRepository {
  const EnrollmentRepository(this._dio);
  final Dio _dio;

  // ── Enrollment Mappings ────────────────────────────────────────────────────

  /// Phase 6: Create enrollment mapping for a student in an academic year.
  Future<EnrollmentMappingModel> createMapping({
    required String studentId,
    required String academicYearId,
    required String standardId,
    String? sectionId,
    String? rollNumber,
    String? joinedOn,
    AdmissionType admissionType = AdmissionType.newAdmission,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.enrollmentMappings,
      data: {
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'standard_id': standardId,
        if (sectionId != null) 'section_id': sectionId,
        if (rollNumber != null && rollNumber.isNotEmpty) 'roll_number': rollNumber,
        if (joinedOn != null) 'joined_on': joinedOn,
        'admission_type': admissionType.backendValue,
      },
    );
    return EnrollmentMappingModel.fromJson(response.data!);
  }

  /// Get a single mapping by ID.
  Future<EnrollmentMappingModel> getMapping(String mappingId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.enrollmentMappingById(mappingId),
    );
    return EnrollmentMappingModel.fromJson(response.data!);
  }

  /// Update mapping fields (section, roll number, admission type).
  Future<EnrollmentMappingModel> updateMapping(
    String mappingId, {
    String? standardId,
    String? sectionId,
    String? rollNumber,
    String? joinedOn,
    AdmissionType? admissionType,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiConstants.enrollmentMappingById(mappingId),
      data: {
        if (standardId != null) 'standard_id': standardId,
        if (sectionId != null) 'section_id': sectionId,
        if (rollNumber != null) 'roll_number': rollNumber,
        if (joinedOn != null) 'joined_on': joinedOn,
        if (admissionType != null)
          'admission_type': admissionType.backendValue,
      },
    );
    return EnrollmentMappingModel.fromJson(response.data!);
  }

  /// Phase 6: Mark student as LEFT or TRANSFERRED.
  Future<EnrollmentMappingModel> exitStudent(
    String mappingId, {
    required String status, // 'LEFT' or 'TRANSFERRED'
    required String leftOn,
    required String exitReason,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.enrollmentExit(mappingId),
      data: {
        'status': status,
        'left_on': leftOn,
        'exit_reason': exitReason,
      },
    );
    return EnrollmentMappingModel.fromJson(response.data!);
  }

  /// Phase 7: Mark mapping COMPLETED at year end (promotion-eligible).
  Future<EnrollmentMappingModel> completeMapping(
    String mappingId, {
    String? completedOn,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.enrollmentComplete(mappingId),
      data: {
        if (completedOn != null) 'completed_on': completedOn,
      },
    );
    return EnrollmentMappingModel.fromJson(response.data!);
  }

  // ── Roster ─────────────────────────────────────────────────────────────────

  /// Get class roster for a standard/section in a year.
  Future<Map<String, dynamic>> getRoster({
    required String standardId,
    required String academicYearId,
    String? sectionId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.enrollmentRoster,
      queryParameters: {
        'standard_id': standardId,
        'academic_year_id': academicYearId,
        if (sectionId != null) 'section_id': sectionId,
      },
    );
    return response.data!;
  }

  // ── Roll Numbers ───────────────────────────────────────────────────────────

  /// Bulk-assign roll numbers (AUTO_SEQ, AUTO_ALPHA, or MANUAL).
  Future<Map<String, dynamic>> assignRollNumbers({
    required String standardId,
    required String sectionId,
    required String academicYearId,
    String policy = 'AUTO_ALPHA',
    List<Map<String, String>>? manualAssignments,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.enrollmentRollNumbers,
      data: {
        'standard_id': standardId,
        'section_id': sectionId,
        'academic_year_id': academicYearId,
        'policy': policy,
        if (manualAssignments != null) 'manual_assignments': manualAssignments,
      },
    );
    return response.data!;
  }

  // ── Academic History ───────────────────────────────────────────────────────

  /// Phase 7: Get all year mappings for a student (immutable historical record).
  Future<StudentAcademicHistoryModel> getStudentHistory(
      String studentId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.enrollmentHistory(studentId),
    );
    return StudentAcademicHistoryModel.fromJson(response.data!);
  }

  // ── Promotion Workflow ─────────────────────────────────────────────────────

  /// Phase 7: Preview promotion run (read-only).
  Future<PromotionPreviewResponse> previewPromotion({
    required String sourceYearId,
    required String targetYearId,
    String? standardId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiConstants.promotionPreview,
      queryParameters: {
        'source_year_id': sourceYearId,
        'target_year_id': targetYearId,
        if (standardId != null) 'standard_id': standardId,
      },
    );
    return PromotionPreviewResponse.fromJson(response.data!);
  }

  /// Phase 7: Execute promotion — creates new year mappings.
  Future<Map<String, dynamic>> executePromotion({
    required String sourceYearId,
    required String targetYearId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.promotionExecute,
      data: {
        'source_year_id': sourceYearId,
        'target_year_id': targetYearId,
        'items': items,
      },
    );
    return response.data!;
  }

  /// Phase 7: Re-enroll a single student in a new year.
  Future<Map<String, dynamic>> reenrollStudent(
    String studentId, {
    required String targetYearId,
    required String standardId,
    String? sectionId,
    String? rollNumber,
    String? joinedOn,
    String admissionType = 'READMISSION',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.promotionReenroll(studentId),
      data: {
        'target_year_id': targetYearId,
        'standard_id': standardId,
        if (sectionId != null) 'section_id': sectionId,
        if (rollNumber != null) 'roll_number': rollNumber,
        if (joinedOn != null) 'joined_on': joinedOn,
        'admission_type': admissionType,
      },
    );
    return response.data!;
  }

  /// Phase 7: Copy teacher assignments from source year to target year.
  Future<Map<String, dynamic>> copyTeacherAssignments({
    required String sourceYearId,
    required String targetYearId,
    bool overwriteExisting = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.promotionCopyAssignments,
      data: {
        'source_year_id': sourceYearId,
        'target_year_id': targetYearId,
        'overwrite_existing': overwriteExisting,
      },
    );
    return response.data!;
  }

  /// Annual re-enrollment for any authenticated role (self).
  Future<Map<String, dynamic>> annualReenrollUser({
    required String userId,
    required String academicYearId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.enrollmentAnnualReenroll(userId),
      data: {'academic_year_id': academicYearId},
    );
    return response.data!;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>((ref) {
  return EnrollmentRepository(ref.read(dioClientProvider));
});