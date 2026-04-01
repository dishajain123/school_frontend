import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/student/student_model.dart';
import '../data/repositories/student_repository.dart';

class StudentFilters {
  const StudentFilters({
    this.standardId,
    this.section,
    this.academicYearId,
  });

  final String? standardId;
  final String? section;
  final String? academicYearId;

  StudentFilters copyWith({
    String? standardId,
    String? section,
    String? academicYearId,
    bool clearStandard = false,
    bool clearSection = false,
  }) {
    return StudentFilters(
      standardId: clearStandard ? null : (standardId ?? this.standardId),
      section: clearSection ? null : (section ?? this.section),
      academicYearId: academicYearId ?? this.academicYearId,
    );
  }
}

class StudentState {
  const StudentState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filters = const StudentFilters(),
  });

  final List<StudentModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final StudentFilters filters;

  bool get hasMore => items.length < total;

  StudentState copyWith({
    List<StudentModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    StudentFilters? filters,
    bool clearError = false,
  }) {
    return StudentState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class StudentNotifier extends AsyncNotifier<StudentState> {
  @override
  Future<StudentState> build() async {
    return const StudentState();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const StudentState();
    if (refresh) {
      state = AsyncData(
        current.copyWith(isLoading: true, page: 1, clearError: true),
      );
    } else {
      if (current.isLoadingMore) return;
      if (!current.hasMore && current.page > 1) return;
      state = AsyncData(current.copyWith(isLoadingMore: true));
    }

    try {
      final repo = ref.read(studentRepositoryProvider);
      final latestState = state.valueOrNull ?? const StudentState();
      final nextPage = refresh ? 1 : latestState.page;

      final result = await repo.list(
        standardId: latestState.filters.standardId,
        section: latestState.filters.section,
        academicYearId: latestState.filters.academicYearId,
        page: nextPage,
        pageSize: 20,
      );

      final newItems = refresh
          ? result.items
          : [...(state.valueOrNull?.items ?? []), ...result.items];

      state = AsyncData(
        StudentState(
          items: newItems,
          total: result.total,
          page: nextPage + 1,
          isLoading: false,
          isLoadingMore: false,
          filters: latestState.filters,
        ),
      );
    } catch (e) {
      final cur = state.valueOrNull ?? const StudentState();
      state = AsyncData(
        cur.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    await load();
  }

  Future<void> setFilters(StudentFilters filters) async {
    final current = state.valueOrNull ?? const StudentState();
    state = AsyncData(current.copyWith(filters: filters));
    await load(refresh: true);
  }

  Future<StudentModel> create(Map<String, dynamic> payload) async {
    final repo = ref.read(studentRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? const StudentState();
    state = AsyncData(
      current.copyWith(
        items: [created, ...current.items],
        total: current.total + 1,
      ),
    );
    return created;
  }

  Future<StudentModel> updateStudent(String id, Map<String, dynamic> payload) async {
    final repo = ref.read(studentRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? const StudentState();
    state = AsyncData(
      current.copyWith(
        items: current.items.map((s) => s.id == id ? updated : s).toList(),
      ),
    );
    return updated;
  }

  Future<StudentModel?> getById(String id) async {
    try {
      final repo = ref.read(studentRepositoryProvider);
      return await repo.getById(id);
    } catch (_) {
      return null;
    }
  }

  Future<StudentModel> updatePromotionStatus(
      String id, String promotionStatus) async {
    final repo = ref.read(studentRepositoryProvider);
    final updated = await repo.updatePromotionStatus(id, promotionStatus);
    final current = state.valueOrNull ?? const StudentState();
    state = AsyncData(
      current.copyWith(
        items: current.items.map((s) => s.id == id ? updated : s).toList(),
      ),
    );
    return updated;
  }
}

final studentNotifierProvider =
    AsyncNotifierProvider<StudentNotifier, StudentState>(
  () => StudentNotifier(),
);
