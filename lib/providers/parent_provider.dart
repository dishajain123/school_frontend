import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/storage_keys.dart';
import '../core/storage/local_storage.dart';
import '../data/models/parent/child_summary.dart';
import '../data/models/parent/parent_model.dart';
import '../data/repositories/parent_repository.dart';

// ── Children State (for PARENT role) ─────────────────────────────────────────

class ChildrenState {
  const ChildrenState({
    this.children = const [],
    this.selectedChildId,
    this.isLoading = false,
    this.error,
  });

  final List<ChildSummaryModel> children;
  final String? selectedChildId;
  final bool isLoading;
  final String? error;

  ChildSummaryModel? get selectedChild {
    if (selectedChildId == null || children.isEmpty) return null;
    try {
      return children.firstWhere((c) => c.id == selectedChildId);
    } catch (_) {
      return children.isNotEmpty ? children.first : null;
    }
  }

  ChildrenState copyWith({
    List<ChildSummaryModel>? children,
    String? selectedChildId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool clearSelectedChild = false,
  }) {
    return ChildrenState(
      children: children ?? this.children,
      selectedChildId:
          clearSelectedChild ? null : (selectedChildId ?? this.selectedChildId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChildrenNotifier extends AsyncNotifier<ChildrenState> {
  @override
  Future<ChildrenState> build() async {
    return const ChildrenState();
  }

  Future<void> loadMyChildren() async {
    state = AsyncData(
      (state.valueOrNull ?? const ChildrenState()).copyWith(
        isLoading: true,
        clearError: true,
      ),
    );

    try {
      final repo = ref.read(parentRepositoryProvider);
      final children = await repo.getMyChildren();

      final localStorage = ref.read(localStorageProvider);
      String? savedChildId =
          localStorage.getString(StorageKeys.selectedChildId);

      // Validate saved child still exists
      if (savedChildId != null) {
        final stillExists = children.any((c) => c.id == savedChildId);
        if (!stillExists) savedChildId = null;
      }

      final selectedId =
          savedChildId ?? (children.isNotEmpty ? children.first.id : null);

      state = AsyncData(ChildrenState(
        children: children,
        selectedChildId: selectedId,
        isLoading: false,
      ));
    } catch (e) {
      final current = state.valueOrNull ?? const ChildrenState();
      state = AsyncData(current.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> selectChild(String childId) async {
    final current = state.valueOrNull ?? const ChildrenState();
    state = AsyncData(current.copyWith(selectedChildId: childId));

    // Persist selection
    final localStorage = ref.read(localStorageProvider);
    await localStorage.setString(StorageKeys.selectedChildId, childId);
  }

  Future<void> refresh() async {
    await loadMyChildren();
  }
}

final childrenNotifierProvider =
    AsyncNotifierProvider<ChildrenNotifier, ChildrenState>(
  () => ChildrenNotifier(),
);

final selectedChildProvider = Provider<ChildSummaryModel?>((ref) {
  return ref.watch(childrenNotifierProvider).valueOrNull?.selectedChild;
});

final selectedChildIdProvider = Provider<String?>((ref) {
  return ref.watch(childrenNotifierProvider).valueOrNull?.selectedChildId;
});

// ── Parent List State (for ADMIN roles) ──────────────────────────────────────

class ParentListState {
  const ParentListState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<ParentModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => items.length < total;

  ParentListState copyWith({
    List<ParentModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return ParentListState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ParentNotifier extends AsyncNotifier<ParentListState> {
  @override
  Future<ParentListState> build() async {
    return const ParentListState();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const ParentListState();
    if (refresh) {
      state = AsyncData(
          current.copyWith(isLoading: true, page: 1, clearError: true));
    } else {
      if (current.isLoadingMore) return;
      if (!current.hasMore && current.page > 1) return;
      state = AsyncData(current.copyWith(isLoadingMore: true));
    }

    try {
      final repo = ref.read(parentRepositoryProvider);
      final latestState = state.valueOrNull ?? const ParentListState();
      final nextPage = refresh ? 1 : latestState.page;

      final result = await repo.list(page: nextPage, pageSize: 20);

      final List<ParentModel> newItems = refresh
          ? List<ParentModel>.from(result.items)
          : <ParentModel>[
              ...latestState.items,
              ...result.items,
            ];

      state = AsyncData(ParentListState(
        items: newItems,
        total: result.total,
        page: nextPage + 1,
        isLoading: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      final cur = state.valueOrNull ?? const ParentListState();
      state = AsyncData(cur.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;
    await load();
  }

  Future<ParentModel> create(Map<String, dynamic> payload) async {
    final repo = ref.read(parentRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? const ParentListState();
    state = AsyncData(current.copyWith(
      items: [created, ...current.items],
      total: current.total + 1,
    ));
    return created;
  }

  Future<ParentModel> updateParent(
      String id, Map<String, dynamic> payload) async {
    final repo = ref.read(parentRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? const ParentListState();
    state = AsyncData(current.copyWith(
      items: current.items.map((p) => p.id == id ? updated : p).toList(),
    ));
    return updated;
  }

  Future<ParentModel?> getById(String id) async {
    try {
      final repo = ref.read(parentRepositoryProvider);
      return await repo.getById(id);
    } catch (_) {
      return null;
    }
  }
}

final parentNotifierProvider =
    AsyncNotifierProvider<ParentNotifier, ParentListState>(
  () => ParentNotifier(),
);
