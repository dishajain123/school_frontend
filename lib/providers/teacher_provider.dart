import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/teacher/teacher_model.dart';
import '../data/repositories/teacher_repository.dart';

class TeacherState {
  const TeacherState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.academicYearFilter,
  });

  final List<TeacherModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? academicYearFilter;

  bool get hasMore => items.length < total;

  TeacherState copyWith({
    List<TeacherModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? academicYearFilter,
    bool clearError = false,
  }) {
    return TeacherState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      academicYearFilter: academicYearFilter ?? this.academicYearFilter,
    );
  }
}

class TeacherNotifier extends AsyncNotifier<TeacherState> {
  @override
  Future<TeacherState> build() async {
    return const TeacherState();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const TeacherState();
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
      final repo = ref.read(teacherRepositoryProvider);
      final latestState = state.valueOrNull ?? const TeacherState();
      final nextPage = refresh ? 1 : latestState.page;

      final result = await repo.list(
        academicYearId: latestState.academicYearFilter,
        page: nextPage,
        pageSize: 20,
      );

      final newItems = refresh
          ? result.items
          : [...(state.valueOrNull?.items ?? []), ...result.items];

      state = AsyncData(
        TeacherState(
          items: newItems,
          total: result.total,
          page: nextPage + 1,
          isLoading: false,
          isLoadingMore: false,
          academicYearFilter: latestState.academicYearFilter,
        ),
      );
    } catch (e) {
      final cur = state.valueOrNull ?? const TeacherState();
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

  Future<void> setFilter({String? academicYearId}) async {
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(academicYearFilter: academicYearId),
    );
    await load(refresh: true);
  }

  Future<TeacherModel> create(Map<String, dynamic> payload) async {
    final repo = ref.read(teacherRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(
        items: [created, ...current.items],
        total: current.total + 1,
      ),
    );
    return created;
  }

  Future<TeacherModel> updateTeacher(
      String id, Map<String, dynamic> payload) async {
    final repo = ref.read(teacherRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((t) => t.id == id ? updated : t)
            .toList(),
      ),
    );
    return updated;
  }

  Future<TeacherModel?> getById(String id) async {
    try {
      final repo = ref.read(teacherRepositoryProvider);
      return await repo.getById(id);
    } catch (_) {
      return null;
    }
  }
}

final teacherNotifierProvider =
    AsyncNotifierProvider<TeacherNotifier, TeacherState>(
  () => TeacherNotifier(),
);
