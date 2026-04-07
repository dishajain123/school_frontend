import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/result/result_model.dart';
import '../data/repositories/result_repository.dart';

// ── Params ────────────────────────────────────────────────────────────────────

typedef ResultListParams = ({
  String studentId,
  String examId,
});

typedef ExamListParams = ({
  String? studentId,
  String? academicYearId,
  String? standardId,
});

typedef ReportCardParams = ({
  String studentId,
  String examId,
});

// ── Results list provider ─────────────────────────────────────────────────────

final resultListProvider =
    FutureProvider.family<ResultListResponse, ResultListParams>(
  (ref, params) async {
    final repo = ref.read(resultRepositoryProvider);
    return repo.listResults(
      studentId: params.studentId,
      examId: params.examId,
    );
  },
);

final examListProvider = FutureProvider.family<List<ExamModel>, ExamListParams>(
  (ref, params) async {
    final repo = ref.read(resultRepositoryProvider);
    return repo.listExams(
      studentId: params.studentId,
      academicYearId: params.academicYearId,
      standardId: params.standardId,
    );
  },
);

// ── Report card provider ──────────────────────────────────────────────────────

final reportCardProvider =
    FutureProvider.family<ReportCardModel, ReportCardParams>(
  (ref, params) async {
    final repo = ref.read(resultRepositoryProvider);
    return repo.getReportCard(
      studentId: params.studentId,
      examId: params.examId,
    );
  },
);

// ── Create exam state ─────────────────────────────────────────────────────────

class CreateExamState {
  const CreateExamState({
    this.isLoading = false,
    this.error,
    this.createdExam,
  });

  final bool isLoading;
  final String? error;
  final ExamModel? createdExam;

  CreateExamState copyWith({
    bool? isLoading,
    String? error,
    ExamModel? createdExam,
    bool clearError = false,
  }) {
    return CreateExamState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      createdExam: createdExam ?? this.createdExam,
    );
  }
}

class CreateExamNotifier extends Notifier<CreateExamState> {
  @override
  CreateExamState build() => const CreateExamState();

  Future<ExamModel?> createExam({
    required String name,
    required String examType,
    required String standardId,
    required String startDate,
    required String endDate,
    String? academicYearId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final exam = await ref.read(resultRepositoryProvider).createExam(
            name: name,
            examType: examType,
            standardId: standardId,
            startDate: startDate,
            endDate: endDate,
            academicYearId: academicYearId,
          );
      state = state.copyWith(isLoading: false, createdExam: exam);
      return exam;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const CreateExamState();
}

final createExamProvider =
    NotifierProvider<CreateExamNotifier, CreateExamState>(
  CreateExamNotifier.new,
);

// ── Enter results state ───────────────────────────────────────────────────────

class EnterResultsState {
  const EnterResultsState({
    this.isLoading = false,
    this.error,
    this.result,
  });

  final bool isLoading;
  final String? error;
  final ResultListResponse? result;

  EnterResultsState copyWith({
    bool? isLoading,
    String? error,
    ResultListResponse? result,
    bool clearError = false,
  }) {
    return EnterResultsState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      result: result ?? this.result,
    );
  }
}

class EnterResultsNotifier extends Notifier<EnterResultsState> {
  @override
  EnterResultsState build() => const EnterResultsState();

  Future<ResultListResponse?> bulkEnter({
    required String examId,
    required List<Map<String, dynamic>> entries,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await ref.read(resultRepositoryProvider).bulkEnterResults(
            examId: examId,
            entries: entries,
          );
      state = state.copyWith(isLoading: false, result: result);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const EnterResultsState();
}

final enterResultsProvider =
    NotifierProvider<EnterResultsNotifier, EnterResultsState>(
  EnterResultsNotifier.new,
);

// ── Publish exam state ────────────────────────────────────────────────────────

class PublishExamState {
  const PublishExamState({
    this.isPublishing = false,
    this.error,
  });

  final bool isPublishing;
  final String? error;

  PublishExamState copyWith({
    bool? isPublishing,
    String? error,
    bool clearError = false,
  }) {
    return PublishExamState(
      isPublishing: isPublishing ?? this.isPublishing,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PublishExamNotifier extends Notifier<PublishExamState> {
  @override
  PublishExamState build() => const PublishExamState();

  Future<bool> publish(String examId) async {
    state = state.copyWith(isPublishing: true, clearError: true);
    try {
      await ref.read(resultRepositoryProvider).publishExam(examId);
      state = state.copyWith(isPublishing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPublishing: false, error: e.toString());
      return false;
    }
  }
}

final publishExamProvider =
    NotifierProvider<PublishExamNotifier, PublishExamState>(
  PublishExamNotifier.new,
);
