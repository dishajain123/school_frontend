import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/timetable/timetable_model.dart';
import '../data/repositories/timetable_repository.dart';

// ── Params ────────────────────────────────────────────────────────────────────

typedef TimetableParams = ({
  String standardId,
  String? academicYearId,
  String? section,
  String? examId,
});

typedef TimetableSectionsParams = ({
  String standardId,
  String? academicYearId,
});

/// Resolves exam-schedule PDFs the same way staff see them on [UploadTimetableScreen]:
/// tries active year, series year, optional/required section, exam-specific vs class-wide.
typedef ExamScheduleTimetableParams = ({
  String standardId,
  String? primaryAcademicYearId,
  String? fallbackAcademicYearId,
  String? section,
  String? examId,
});

// ── Read provider ─────────────────────────────────────────────────────────────
//
// FutureProvider.family is appropriate here:
//   • Timetable is keyed by (standardId, academicYearId, section).
//   • Presigned URL must be fetched fresh — not cached long-term.
//   • Pull-to-refresh handled by ref.invalidate in the screen.

final timetableProvider =
    FutureProvider.family<TimetableModel, TimetableParams>(
  (ref, params) => ref.read(timetableRepositoryProvider).getTimetable(
        standardId: params.standardId,
        academicYearId: params.academicYearId,
        section: params.section,
        examId: params.examId,
      ),
);

final timetableSectionsProvider =
    FutureProvider.family<List<String>, TimetableSectionsParams>(
  (ref, params) => ref.read(timetableRepositoryProvider).listSections(
        standardId: params.standardId,
        academicYearId: params.academicYearId,
      ),
);

/// Exam schedule / hub: finds any uploaded PDF that applies (upload parity).
final examScheduleTimetableProvider =
    FutureProvider.autoDispose.family<TimetableModel?, ExamScheduleTimetableParams>(
  (ref, p) async {
    final repo = ref.read(timetableRepositoryProvider);

    Future<TimetableModel?> attempt({
      required String? academicYearId,
      required String? section,
      required String? examId,
    }) async {
      try {
        final t = await repo.getTimetable(
          standardId: p.standardId,
          academicYearId: academicYearId,
          section: section,
          examId: examId,
        );
        final url = t.fileUrl?.trim();
        if (url != null && url.isNotEmpty) return t;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code != 404 && code != 422) rethrow;
      }
      return null;
    }

    final py = p.primaryAcademicYearId?.trim();
    final fy = p.fallbackAcademicYearId?.trim();
    final yearOrder = <String?>[];
    if (py != null && py.isNotEmpty) yearOrder.add(py);
    if (fy != null && fy.isNotEmpty && fy != py) yearOrder.add(fy);
    yearOrder.add(null);

    final sec = p.section?.trim();
    final normalizedSection =
        (sec != null && sec.isNotEmpty) ? sec : null;
    final ex = p.examId?.trim();
    final normalizedExam = (ex != null && ex.isNotEmpty) ? ex : null;

    final tried = <String>{};
    for (final y in yearOrder) {
      for (final tuple in <({String? s, String? e})>[
        (s: normalizedSection, e: normalizedExam),
        (s: null, e: normalizedExam),
        (s: normalizedSection, e: null),
        (s: null, e: null),
      ]) {
        final key = '${y ?? ''}|${tuple.s ?? ''}|${tuple.e ?? ''}';
        if (!tried.add(key)) continue;
        final hit = await attempt(
          academicYearId: y,
          section: tuple.s,
          examId: tuple.e,
        );
        if (hit != null) return hit;
      }
    }
    return null;
  },
);

// ── Upload state ──────────────────────────────────────────────────────────────

class TimetableUploadState {
  const TimetableUploadState({
    this.isUploading = false,
    this.error,
    this.result,
  });

  final bool isUploading;
  final String? error;
  final TimetableModel? result;

  TimetableUploadState copyWith({
    bool? isUploading,
    String? error,
    TimetableModel? result,
    bool clearError = false,
    bool clearResult = false,
  }) {
    return TimetableUploadState(
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : (error ?? this.error),
      result: clearResult ? null : (result ?? this.result),
    );
  }
}

class TimetableUploadNotifier extends Notifier<TimetableUploadState> {
  @override
  TimetableUploadState build() => const TimetableUploadState();

  Future<bool> upload({
    required String standardId,
    required PlatformFile file,
    String? academicYearId,
    String? section,
    String? examId,
    String? overrideFileName,
  }) async {
    state = state.copyWith(
      isUploading: true,
      clearError: true,
      clearResult: true,
    );
    try {
      final repo = ref.read(timetableRepositoryProvider);
      final uploaded = await repo.uploadTimetable(
        standardId: standardId,
        file: file,
        academicYearId: academicYearId,
        section: section,
        examId: examId,
        overrideFileName: overrideFileName,
      );
      state = state.copyWith(isUploading: false, result: uploaded);
      // Bust the read-cache so view screens pick up the new file
      ref.invalidate(timetableProvider);
      ref.invalidate(timetableSectionsProvider);
      ref.invalidate(examScheduleTimetableProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isUploading: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const TimetableUploadState();
}

final timetableUploadProvider =
    NotifierProvider<TimetableUploadNotifier, TimetableUploadState>(
  TimetableUploadNotifier.new,
);

class TimetableDeleteState {
  const TimetableDeleteState({
    this.isDeleting = false,
    this.error,
  });

  final bool isDeleting;
  final String? error;

  TimetableDeleteState copyWith({
    bool? isDeleting,
    String? error,
    bool clearError = false,
  }) {
    return TimetableDeleteState(
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TimetableDeleteNotifier extends Notifier<TimetableDeleteState> {
  @override
  TimetableDeleteState build() => const TimetableDeleteState();

  Future<bool> delete({
    required String standardId,
    String? academicYearId,
    String? section,
    String? examId,
  }) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      final repo = ref.read(timetableRepositoryProvider);
      await repo.deleteTimetable(
        standardId: standardId,
        academicYearId: academicYearId,
        section: section,
        examId: examId,
      );
      state = state.copyWith(isDeleting: false);
      ref.invalidate(timetableProvider);
      ref.invalidate(timetableSectionsProvider);
      ref.invalidate(examScheduleTimetableProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isDeleting: false, error: e.toString());
      return false;
    }
  }
}

final timetableDeleteProvider =
    NotifierProvider<TimetableDeleteNotifier, TimetableDeleteState>(
  TimetableDeleteNotifier.new,
);
