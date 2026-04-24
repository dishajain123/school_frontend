import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/timetable/timetable_model.dart';
import '../data/repositories/timetable_repository.dart';

// ── Params ────────────────────────────────────────────────────────────────────

typedef TimetableParams = ({
  String standardId,
  String? academicYearId,
  String? section,
});

typedef TimetableSectionsParams = ({
  String standardId,
  String? academicYearId,
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
      ),
);

final timetableSectionsProvider =
    FutureProvider.family<List<String>, TimetableSectionsParams>(
  (ref, params) => ref.read(timetableRepositoryProvider).listSections(
        standardId: params.standardId,
        academicYearId: params.academicYearId,
      ),
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
        overrideFileName: overrideFileName,
      );
      state = state.copyWith(isUploading: false, result: uploaded);
      // Bust the read-cache so view screens pick up the new file
      ref.invalidate(timetableProvider);
      ref.invalidate(timetableSectionsProvider);
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
  }) async {
    state = state.copyWith(isDeleting: true, clearError: true);
    try {
      final repo = ref.read(timetableRepositoryProvider);
      await repo.deleteTimetable(
        standardId: standardId,
        academicYearId: academicYearId,
        section: section,
      );
      state = state.copyWith(isDeleting: false);
      ref.invalidate(timetableProvider);
      ref.invalidate(timetableSectionsProvider);
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
