// lib/providers/enrollment_provider.dart
// Phase 6 & 7 enrollment and promotion Riverpod providers.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/enrollment/enrollment_model.dart';
import '../data/repositories/enrollment_repository.dart';

// ── Roster provider ───────────────────────────────────────────────────────────

typedef _RosterParams = ({
  String standardId,
  String academicYearId,
  String? sectionId,
});

final classRosterProvider =
    FutureProvider.family<Map<String, dynamic>, _RosterParams>((ref, params) {
  return ref.watch(enrollmentRepositoryProvider).getRoster(
        standardId: params.standardId,
        academicYearId: params.academicYearId,
        sectionId: params.sectionId,
      );
});

// ── Student history provider ──────────────────────────────────────────────────

final studentAcademicHistoryProvider =
    FutureProvider.family<StudentAcademicHistoryModel, String>(
  (ref, studentId) {
    return ref
        .watch(enrollmentRepositoryProvider)
        .getStudentHistory(studentId);
  },
);

// ── Promotion preview provider ────────────────────────────────────────────────

typedef _PromotionPreviewParams = ({
  String sourceYearId,
  String targetYearId,
  String? standardId,
});

final promotionPreviewProvider =
    FutureProvider.family<PromotionPreviewResponse, _PromotionPreviewParams>(
        (ref, params) {
  return ref.watch(enrollmentRepositoryProvider).previewPromotion(
        sourceYearId: params.sourceYearId,
        targetYearId: params.targetYearId,
        standardId: params.standardId,
      );
});

// ── Enrollment notifier (mutations) ──────────────────────────────────────────

class EnrollmentNotifier extends StateNotifier<AsyncValue<void>> {
  EnrollmentNotifier(this._repo) : super(const AsyncData(null));

  final EnrollmentRepository _repo;

  Future<EnrollmentMappingModel?> createMapping({
    required String studentId,
    required String academicYearId,
    required String standardId,
    String? sectionId,
    String? rollNumber,
    String? joinedOn,
    AdmissionType admissionType = AdmissionType.newAdmission,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.createMapping(
        studentId: studentId,
        academicYearId: academicYearId,
        standardId: standardId,
        sectionId: sectionId,
        rollNumber: rollNumber,
        joinedOn: joinedOn,
        admissionType: admissionType,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<EnrollmentMappingModel?> exitStudent(
    String mappingId, {
    required String status,
    required String leftOn,
    required String exitReason,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.exitStudent(
        mappingId,
        status: status,
        leftOn: leftOn,
        exitReason: exitReason,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<EnrollmentMappingModel?> completeMapping(
    String mappingId, {
    String? completedOn,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.completeMapping(mappingId, completedOn: completedOn);
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> executePromotion({
    required String sourceYearId,
    required String targetYearId,
    required List<Map<String, dynamic>> items,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.executePromotion(
        sourceYearId: sourceYearId,
        targetYearId: targetYearId,
        items: items,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> reenrollStudent(
    String studentId, {
    required String targetYearId,
    required String standardId,
    String? sectionId,
    String? rollNumber,
    String? joinedOn,
    String admissionType = 'READMISSION',
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.reenrollStudent(
        studentId,
        targetYearId: targetYearId,
        standardId: standardId,
        sectionId: sectionId,
        rollNumber: rollNumber,
        joinedOn: joinedOn,
        admissionType: admissionType,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> copyTeacherAssignments({
    required String sourceYearId,
    required String targetYearId,
    bool overwriteExisting = false,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _repo.copyTeacherAssignments(
        sourceYearId: sourceYearId,
        targetYearId: targetYearId,
        overwriteExisting: overwriteExisting,
      );
      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final enrollmentNotifierProvider =
    StateNotifierProvider<EnrollmentNotifier, AsyncValue<void>>((ref) {
  return EnrollmentNotifier(ref.watch(enrollmentRepositoryProvider));
});