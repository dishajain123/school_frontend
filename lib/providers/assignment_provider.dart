import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/assignment/assignment_model.dart';
import '../data/repositories/assignment_repository.dart';

// ── Filter state ──────────────────────────────────────────────────────────────

class AssignmentFilters {
  final String? standardId;
  final String? subjectId;
  final String? academicYearId;
  final bool? isActive;
  final bool? isOverdue;
  final bool? isSubmitted;

  const AssignmentFilters({
    this.standardId,
    this.subjectId,
    this.academicYearId,
    this.isActive,
    this.isOverdue,
    this.isSubmitted,
  });

  AssignmentFilters copyWith({
    String? standardId,
    String? subjectId,
    String? academicYearId,
    bool? isActive,
    bool? isOverdue,
    bool? isSubmitted,
    bool clearStandard = false,
    bool clearSubject = false,
    bool clearIsActive = false,
    bool clearIsOverdue = false,
    bool clearIsSubmitted = false,
  }) {
    return AssignmentFilters(
      standardId: clearStandard ? null : (standardId ?? this.standardId),
      subjectId: clearSubject ? null : (subjectId ?? this.subjectId),
      academicYearId: academicYearId ?? this.academicYearId,
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      isOverdue: clearIsOverdue ? null : (isOverdue ?? this.isOverdue),
      isSubmitted: clearIsSubmitted ? null : (isSubmitted ?? this.isSubmitted),
    );
  }
}

// ── List state ────────────────────────────────────────────────────────────────

class AssignmentListState {
  final List<AssignmentModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool isLoadingMore;
  final AssignmentFilters filters;

  const AssignmentListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 0,
    this.isLoadingMore = false,
    this.filters = const AssignmentFilters(),
  });

  bool get hasMore => page < totalPages;

  AssignmentListState copyWith({
    List<AssignmentModel>? items,
    int? total,
    int? page,
    int? pageSize,
    int? totalPages,
    bool? isLoadingMore,
    AssignmentFilters? filters,
  }) {
    return AssignmentListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filters: filters ?? this.filters,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class AssignmentsNotifier extends AsyncNotifier<AssignmentListState> {
  late final AssignmentRepository _repo;

  @override
  Future<AssignmentListState> build() async {
    _repo = ref.read(assignmentRepositoryProvider);
    return _fetchPage(1, const AssignmentFilters());
  }

  Future<AssignmentListState> _fetchPage(
      int page, AssignmentFilters filters) async {
    final response = await _repo.listAssignments(
      standardId: filters.standardId,
      subjectId: filters.subjectId,
      academicYearId: filters.academicYearId,
      isActive: filters.isActive,
      isOverdue: filters.isOverdue,
      isSubmitted: filters.isSubmitted,
      page: page,
    );
    return AssignmentListState(
      items: response.items,
      total: response.total,
      page: response.page,
      pageSize: response.pageSize,
      totalPages: response.totalPages,
      filters: filters,
    );
  }

  Future<void> applyFilters(AssignmentFilters filters) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1, filters));
  }

  Future<void> refresh() async {
    final currentFilters =
        state.valueOrNull?.filters ?? const AssignmentFilters();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(1, currentFilters));
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final response = await _repo.listAssignments(
        standardId: current.filters.standardId,
        subjectId: current.filters.subjectId,
        academicYearId: current.filters.academicYearId,
        isActive: current.filters.isActive,
        isOverdue: current.filters.isOverdue,
        isSubmitted: current.filters.isSubmitted,
        page: current.page + 1,
      );

      state = AsyncData(current.copyWith(
        items: [...current.items, ...response.items],
        page: response.page,
        totalPages: response.totalPages,
        total: response.total,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<AssignmentModel?> createAssignment({
    required String title,
    required String standardId,
    required String subjectId,
    required DateTime dueDate,
    required String academicYearId,
    String? description,
    dynamic file, // MultipartFile
  }) async {
    try {
      final created = await _repo.createAssignment(
        title: title,
        standardId: standardId,
        subjectId: subjectId,
        dueDate: dueDate,
        academicYearId: academicYearId,
        description: description,
        file: file,
      );

      // Optimistic prepend
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          items: [created, ...current.items],
          total: current.total + 1,
        ));
      }
      return created;
    } catch (e) {
      rethrow;
    }
  }

  Future<AssignmentModel?> updateAssignment(
    String assignmentId, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isActive,
  }) async {
    try {
      final updated = await _repo.updateAssignment(
        assignmentId,
        title: title,
        description: description,
        dueDate: dueDate,
        isActive: isActive,
      );

      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(current.copyWith(
          items: current.items
              .map((a) => a.id == updated.id ? updated : a)
              .toList(),
        ));
      }
      return updated;
    } catch (e) {
      rethrow;
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final assignmentsProvider =
    AsyncNotifierProvider<AssignmentsNotifier, AssignmentListState>(
  AssignmentsNotifier.new,
);

final assignmentDetailProvider =
    FutureProvider.autoDispose.family<AssignmentModel, String>(
  (ref, id) async {
    final repo = ref.read(assignmentRepositoryProvider);
    return repo.getById(id);
  },
);
