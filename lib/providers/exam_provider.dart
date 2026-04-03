import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exam/exam_series_model.dart';
import '../data/models/exam/exam_entry_model.dart';
import '../data/repositories/exam_repository.dart';

// ── Schedule params ───────────────────────────────────────────────────────────

typedef ExamScheduleParams = ({
  String standardId,
  String seriesId,
});

// ── Schedule provider (load full table: series + entries) ─────────────────────

final examScheduleProvider =
    FutureProvider.family<ExamScheduleTable, ExamScheduleParams>(
  (ref, params) => ref.read(examRepositoryProvider).getSchedule(
        standardId: params.standardId,
        seriesId: params.seriesId,
      ),
);

// ── Create / manage series state ──────────────────────────────────────────────

class ExamSeriesState {
  const ExamSeriesState({
    this.isLoading = false,
    this.error,
    this.createdSeries,
  });

  final bool isLoading;
  final String? error;
  final ExamSeriesModel? createdSeries;

  ExamSeriesState copyWith({
    bool? isLoading,
    String? error,
    ExamSeriesModel? createdSeries,
    bool clearError = false,
  }) {
    return ExamSeriesState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      createdSeries: createdSeries ?? this.createdSeries,
    );
  }
}

class ExamSeriesNotifier extends Notifier<ExamSeriesState> {
  @override
  ExamSeriesState build() => const ExamSeriesState();

  Future<ExamSeriesModel?> createSeries({
    required String name,
    required String standardId,
    String? academicYearId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final series = await ref.read(examRepositoryProvider).createSeries(
            name: name,
            standardId: standardId,
            academicYearId: academicYearId,
          );
      state = state.copyWith(isLoading: false, createdSeries: series);
      return series;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<ExamSeriesModel?> publishSeries(String seriesId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated =
          await ref.read(examRepositoryProvider).publishSeries(seriesId);
      state = state.copyWith(isLoading: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const ExamSeriesState();
}

final examSeriesNotifierProvider =
    NotifierProvider<ExamSeriesNotifier, ExamSeriesState>(
  ExamSeriesNotifier.new,
);

// ── Add entry / cancel entry state ────────────────────────────────────────────

class ExamEntryState {
  const ExamEntryState({
    this.isLoading = false,
    this.error,
  });

  final bool isLoading;
  final String? error;

  ExamEntryState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ExamEntryState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExamEntryNotifier extends Notifier<ExamEntryState> {
  @override
  ExamEntryState build() => const ExamEntryState();

  Future<ExamEntryModel?> addEntry({
    required String seriesId,
    required String subjectId,
    required String examDate,
    required String startTime,
    required int durationMinutes,
    String? venue,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entry = await ref.read(examRepositoryProvider).addEntry(
            seriesId: seriesId,
            subjectId: subjectId,
            examDate: examDate,
            startTime: startTime,
            durationMinutes: durationMinutes,
            venue: venue,
          );
      state = state.copyWith(isLoading: false);
      return entry;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  Future<ExamEntryModel?> cancelEntry(String entryId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated =
          await ref.read(examRepositoryProvider).cancelEntry(entryId);
      state = state.copyWith(isLoading: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const ExamEntryState();
}

final examEntryNotifierProvider =
    NotifierProvider<ExamEntryNotifier, ExamEntryState>(
  ExamEntryNotifier.new,
);