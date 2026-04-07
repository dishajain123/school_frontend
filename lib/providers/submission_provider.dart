import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment/submission_model.dart';
import '../data/repositories/submission_repository.dart';

// ── List state ────────────────────────────────────────────────────────────────

class SubmissionListState {
  final List<SubmissionModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool isLoadingMore;
  final String? sectionFilter;

  const SubmissionListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 0,
    this.isLoadingMore = false,
    this.sectionFilter,
  });

  bool get hasMore => page < totalPages;

  SubmissionListState copyWith({
    List<SubmissionModel>? items,
    int? total,
    int? page,
    int? pageSize,
    int? totalPages,
    bool? isLoadingMore,
    String? sectionFilter,
  }) {
    return SubmissionListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sectionFilter: sectionFilter ?? this.sectionFilter,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SubmissionsNotifier
    extends AutoDisposeFamilyAsyncNotifier<SubmissionListState, String> {
  late final SubmissionRepository _repo;

  @override
  Future<SubmissionListState> build(String assignmentId) async {
    _repo = ref.read(submissionRepositoryProvider);
    return _fetchPage(assignmentId, 1, null);
  }

  Future<SubmissionListState> _fetchPage(
    String assignmentId,
    int page,
    String? sectionFilter,
  ) async {
    final response = await _repo.listSubmissions(
      assignmentId: assignmentId,
      section: sectionFilter,
      page: page,
    );
    return SubmissionListState(
      items: response.items,
      total: response.total,
      page: response.page,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      sectionFilter: sectionFilter,
    );
  }

  Future<void> refresh() async {
    final sectionFilter = state.valueOrNull?.sectionFilter;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(arg, 1, sectionFilter));
  }

  Future<void> applySectionFilter(String? section) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(arg, 1, section));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await _repo.listSubmissions(
        assignmentId: arg,
        section: current.sectionFilter,
        page: current.page + 1,
      );
      state = AsyncData(current.copyWith(
        items: [...current.items, ...response.items],
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<SubmissionModel> gradeSubmission(
    String submissionId, {
    String? grade,
    String? feedback,
    bool? isApproved,
  }) async {
    final updated = await _repo.gradeSubmission(
      submissionId,
      grade: grade,
      feedback: feedback,
      isApproved: isApproved,
    );

    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(
        items:
            current.items.map((s) => s.id == updated.id ? updated : s).toList(),
      ));
    }
    return updated;
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final submissionsProvider = AsyncNotifierProvider.autoDispose
    .family<SubmissionsNotifier, SubmissionListState, String>(
  SubmissionsNotifier.new,
);

// Single submission create — used in assignment detail screen
final submissionCreateProvider = StateNotifierProvider.autoDispose<
    SubmissionCreateNotifier, AsyncValue<SubmissionModel?>>(
  (ref) => SubmissionCreateNotifier(ref.read(submissionRepositoryProvider)),
);

class SubmissionCreateNotifier
    extends StateNotifier<AsyncValue<SubmissionModel?>> {
  SubmissionCreateNotifier(this._repo) : super(const AsyncData(null));
  final SubmissionRepository _repo;

  Future<SubmissionModel?> submit({
    required String assignmentId,
    required String studentId,
    String? textResponse,
    dynamic file, // MultipartFile
  }) async {
    state = const AsyncLoading();
    try {
      final submission = await _repo.createSubmission(
        assignmentId: assignmentId,
        studentId: studentId,
        textResponse: textResponse,
        file: file,
      );
      state = AsyncData(submission);
      return submission;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncData(null);
}
