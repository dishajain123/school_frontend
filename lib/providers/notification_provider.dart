import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/notification/notification_model.dart';
import '../data/repositories/notification_repository.dart';

class NotificationState {
  const NotificationState({
    this.items = const [],
    this.total = 0,
    this.unreadCount = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.typeFilter,
    this.isReadFilter,
  });

  final List<NotificationModel> items;
  final int total;
  final int unreadCount;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String? typeFilter;
  final bool? isReadFilter;

  bool get hasMore => items.length < total;

  NotificationState copyWith({
    List<NotificationModel>? items,
    int? total,
    int? unreadCount,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? typeFilter,
    bool? isReadFilter,
    bool clearError = false,
    bool clearTypeFilter = false,
    bool clearIsReadFilter = false,
  }) {
    return NotificationState(
      items: items ?? this.items,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      isReadFilter:
          clearIsReadFilter ? null : (isReadFilter ?? this.isReadFilter),
    );
  }
}

class NotificationNotifier extends AsyncNotifier<NotificationState> {
  @override
  Future<NotificationState> build() async {
    return const NotificationState();
  }

  Future<void> loadInbox({bool refresh = false}) async {
    final current = state.valueOrNull ?? const NotificationState();

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
      final repo = ref.read(notificationRepositoryProvider);
      final latestState = state.valueOrNull ?? const NotificationState();
      final nextPage = refresh ? 1 : latestState.page;

      final result = await repo.getInbox(
        isRead: latestState.isReadFilter,
        type: latestState.typeFilter,
        page: nextPage,
        pageSize: 20,
      );

      final newItems = refresh
          ? result.items
          : [...(state.valueOrNull?.items ?? []), ...result.items];

      state = AsyncData(
        NotificationState(
          items: newItems,
          total: result.total,
          unreadCount: result.unreadCount,
          page: nextPage + 1,
          isLoading: false,
          isLoadingMore: false,
          typeFilter: latestState.typeFilter,
          isReadFilter: latestState.isReadFilter,
        ),
      );
    } catch (e) {
      final cur = state.valueOrNull ?? const NotificationState();
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
    await loadInbox();
  }

  Future<void> setFilter({
    String? typeFilter,
    bool? isReadFilter,
    bool clearType = false,
    bool clearRead = false,
  }) async {
    final current = state.valueOrNull ?? const NotificationState();
    state = AsyncData(
      current.copyWith(
        typeFilter: typeFilter,
        isReadFilter: isReadFilter,
        clearTypeFilter: clearType,
        clearIsReadFilter: clearRead,
      ),
    );
    await loadInbox(refresh: true);
  }

  Future<void> markRead(List<String> ids) async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markRead(ids);
      final current = state.valueOrNull ?? const NotificationState();
      final updatedItems = current.items.map((n) {
        if (ids.contains(n.id)) return n.copyWith(isRead: true);
        return n;
      }).toList();
      final newlyRead = current.items
          .where((n) => ids.contains(n.id) && !n.isRead)
          .length;
      state = AsyncData(
        current.copyWith(
          items: updatedItems,
          unreadCount: (current.unreadCount - newlyRead).clamp(0, current.total),
        ),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.markAllRead();
      final current = state.valueOrNull ?? const NotificationState();
      final updatedItems =
          current.items.map((n) => n.copyWith(isRead: true)).toList();
      state = AsyncData(
        current.copyWith(items: updatedItems, unreadCount: 0),
      );
    } catch (_) {}
  }

  Future<void> clearRead() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      await repo.clearRead();
      await loadInbox(refresh: true);
    } catch (_) {}
  }

  Future<void> loadUnreadCount() async {
    try {
      final repo = ref.read(notificationRepositoryProvider);
      final count = await repo.getUnreadCount();
      final current = state.valueOrNull ?? const NotificationState();
      state = AsyncData(current.copyWith(unreadCount: count));
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    AsyncNotifierProvider<NotificationNotifier, NotificationState>(
  () => NotificationNotifier(),
);

final unreadCountProvider = Provider<int>((ref) {
  return ref.watch(notificationNotifierProvider).valueOrNull?.unreadCount ?? 0;
});