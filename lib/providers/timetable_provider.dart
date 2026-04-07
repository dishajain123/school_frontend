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
      );
      state = state.copyWith(isUploading: false, result: uploaded);
      // Bust the read-cache so view screens pick up the new file
      ref.invalidate(timetableProvider);
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
