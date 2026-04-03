import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/school/school_model.dart';
import '../data/repositories/school_repository.dart';

enum SchoolActivityFilter {
  all,
  active,
  inactive,
}

class SchoolListState {
  const SchoolListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.error,
    this.filter = SchoolActivityFilter.all,
  });

  final List<SchoolModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? error;
  final SchoolActivityFilter filter;

  bool get hasMore => page <= totalPages;

  SchoolListState copyWith({
    List<SchoolModel>? items,
    int? total,
    int? page,
    int? pageSize,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? error,
    SchoolActivityFilter? filter,
    bool clearError = false,
  }) {
    return SchoolListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      filter: filter ?? this.filter,
    );
  }
}

class SchoolNotifier extends AsyncNotifier<SchoolListState> {
  @override
  Future<SchoolListState> build() async {
    return const SchoolListState();
  }

  bool? _mapFilter(SchoolActivityFilter filter) {
    switch (filter) {
      case SchoolActivityFilter.active:
        return true;
      case SchoolActivityFilter.inactive:
        return false;
      case SchoolActivityFilter.all:
        return null;
    }
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const SchoolListState();

    if (refresh) {
      state = AsyncData(
        current.copyWith(
          isLoading: true,
          page: 1,
          clearError: true,
        ),
      );
    } else {
      if (current.isLoadingMore || !current.hasMore) return;
      state = AsyncData(current.copyWith(isLoadingMore: true));
    }

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final snapshot = state.valueOrNull ?? const SchoolListState();
      final nextPage = refresh ? 1 : snapshot.page;

      final result = await repo.list(
        page: nextPage,
        pageSize: snapshot.pageSize,
        isActive: _mapFilter(snapshot.filter),
      );

      final List<SchoolModel> merged = refresh
          ? List<SchoolModel>.from(result.items)
          : <SchoolModel>[
              ...snapshot.items,
              ...result.items,
            ];

      state = AsyncData(
        snapshot.copyWith(
          items: merged,
          total: result.total,
          page: nextPage + 1,
          pageSize: result.pageSize,
          totalPages: result.totalPages,
          isLoading: false,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      final snapshot = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        snapshot.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> setFilter(SchoolActivityFilter filter) async {
    final current = state.valueOrNull ?? const SchoolListState();
    state = AsyncData(
      current.copyWith(
        filter: filter,
        page: 1,
      ),
    );
    await load(refresh: true);
  }

  Future<void> refresh() async {
    await load(refresh: true);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    await load();
  }

  Future<SchoolModel?> create(Map<String, dynamic> payload) async {
    final current = state.valueOrNull ?? const SchoolListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final created = await repo.create(payload);
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          items: [created, ...latest.items],
          total: latest.total + 1,
          isSubmitting: false,
        ),
      );
      return created;
    } catch (e) {
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<SchoolModel?> updateSchool({
    required String schoolId,
    required Map<String, dynamic> payload,
  }) async {
    final current = state.valueOrNull ?? const SchoolListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final updated = await repo.update(schoolId, payload);
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          items: latest.items
              .map((s) => s.id == updated.id ? updated : s)
              .toList(),
          isSubmitting: false,
        ),
      );
      return updated;
    } catch (e) {
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<SchoolModel?> deactivateSchool(String schoolId) async {
    final current = state.valueOrNull ?? const SchoolListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final updated = await repo.deactivate(schoolId);
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          items: latest.items
              .map((s) => s.id == updated.id ? updated : s)
              .toList(),
          isSubmitting: false,
        ),
      );
      return updated;
    } catch (e) {
      final latest = state.valueOrNull ?? const SchoolListState();
      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<SchoolModel?> getById(String schoolId) async {
    try {
      final repo = ref.read(schoolRepositoryProvider);
      return await repo.getById(schoolId);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }
}

final schoolNotifierProvider =
    AsyncNotifierProvider<SchoolNotifier, SchoolListState>(
  SchoolNotifier.new,
);

final schoolByIdProvider = Provider.family<SchoolModel?, String>((ref, id) {
  final state = ref.watch(schoolNotifierProvider).valueOrNull;
  if (state == null) return null;
  try {
    return state.items.firstWhere((item) => item.id == id);
  } catch (_) {
    return null;
  }
});

class SchoolSettingsState {
  const SchoolSettingsState({
    this.items = const [],
    this.edits = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  final List<SchoolSettingModel> items;
  final Map<String, String> edits;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  SchoolSettingsState copyWith({
    List<SchoolSettingModel>? items,
    Map<String, String>? edits,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return SchoolSettingsState(
      items: items ?? this.items,
      edits: edits ?? this.edits,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SchoolSettingsNotifier extends Notifier<SchoolSettingsState> {
  @override
  SchoolSettingsState build() {
    return const SchoolSettingsState();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final result = await repo.listSettings();
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        edits: {
          for (final item in result.items) item.settingKey: item.settingValue,
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setValue(String key, String value) {
    final next = Map<String, String>.from(state.edits);
    next[key] = value;
    state = state.copyWith(edits: next);
  }

  Future<bool> saveAll() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repo = ref.read(schoolRepositoryProvider);
      final payloadItems = state.items
          .map(
            (item) => item.copyWith(
              settingValue: state.edits[item.settingKey] ?? item.settingValue,
            ),
          )
          .toList();

      final result = await repo.updateSettings(payloadItems);
      state = state.copyWith(
        isSaving: false,
        items: result.items,
        edits: {
          for (final item in result.items) item.settingKey: item.settingValue,
        },
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final schoolSettingsProvider =
    NotifierProvider<SchoolSettingsNotifier, SchoolSettingsState>(
  SchoolSettingsNotifier.new,
);
