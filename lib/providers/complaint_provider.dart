import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/complaint/complaint_model.dart';
import '../data/repositories/complaint_repository.dart';

class ComplaintListState {
  const ComplaintListState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.statusFilter,
    this.categoryFilter,
    this.complainantTypeFilter,
  });

  final List<ComplaintModel> items;
  final int total;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final ComplaintStatus? statusFilter;
  final ComplaintCategory? categoryFilter;
  final ComplainantType? complainantTypeFilter;

  ComplaintListState copyWith({
    List<ComplaintModel>? items,
    int? total,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    ComplaintStatus? statusFilter,
    ComplaintCategory? categoryFilter,
    ComplainantType? complainantTypeFilter,
    bool clearError = false,
    bool clearStatusFilter = false,
    bool clearCategoryFilter = false,
    bool clearComplainantTypeFilter = false,
  }) {
    return ComplaintListState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      categoryFilter:
          clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      complainantTypeFilter: clearComplainantTypeFilter
          ? null
          : (complainantTypeFilter ?? this.complainantTypeFilter),
    );
  }
}

class ComplaintNotifier extends AsyncNotifier<ComplaintListState> {
  @override
  Future<ComplaintListState> build() async {
    return const ComplaintListState();
  }

  Future<void> load({
    ComplaintStatus? statusFilter,
    ComplaintCategory? categoryFilter,
    ComplainantType? complainantTypeFilter,
    bool refresh = false,
  }) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    final effectiveStatus = statusFilter ?? current.statusFilter;
    final effectiveCategory = categoryFilter ?? current.categoryFilter;
    final effectiveComplainantType =
        complainantTypeFilter ?? current.complainantTypeFilter;

    state = AsyncData(
      current.copyWith(
        isLoading: true,
        statusFilter: effectiveStatus,
        categoryFilter: effectiveCategory,
        complainantTypeFilter: effectiveComplainantType,
        clearError: true,
      ),
    );

    try {
      final repo = ref.read(complaintRepositoryProvider);
      final result = await repo.list(
        status: effectiveStatus,
        category: effectiveCategory,
        complainantType: effectiveComplainantType,
      );

      state = AsyncData(
        (state.valueOrNull ?? const ComplaintListState()).copyWith(
          items: result.items,
          total: result.total,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const ComplaintListState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> setStatusFilter(ComplaintStatus? status) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(
      current.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
      ),
    );
    await load();
  }

  Future<void> setCategoryFilter(ComplaintCategory? category) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(
      current.copyWith(
        categoryFilter: category,
        clearCategoryFilter: category == null,
      ),
    );
    await load();
  }

  Future<void> setComplainantTypeFilter(ComplainantType? type) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(
      current.copyWith(
        complainantTypeFilter: type,
        clearComplainantTypeFilter: type == null,
      ),
    );
    await load();
  }

  Future<ComplaintModel?> create(Map<String, dynamic> payload) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(complaintRepositoryProvider);
      final created = await repo.create(payload);
      final latest = state.valueOrNull ?? const ComplaintListState();

      state = AsyncData(
        latest.copyWith(
          items: [created, ...latest.items],
          total: latest.total + 1,
          isSubmitting: false,
        ),
      );

      return created;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const ComplaintListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<ComplaintModel?> updateStatus({
    required String complaintId,
    required ComplaintStatus nextStatus,
    String? resolutionNote,
  }) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(complaintRepositoryProvider);
      final updated = await repo.updateStatus(
        complaintId,
        {
          'status': nextStatus.backendValue,
          if (resolutionNote != null && resolutionNote.trim().isNotEmpty)
            'resolution_note': resolutionNote.trim(),
        },
      );

      final latest = state.valueOrNull ?? const ComplaintListState();
      state = AsyncData(
        latest.copyWith(
          items: latest.items
              .map((c) => c.id == complaintId ? updated : c)
              .toList(),
          isSubmitting: false,
        ),
      );

      return updated;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const ComplaintListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<FeedbackModel?> createFeedback(Map<String, dynamic> payload) async {
    final current = state.valueOrNull ?? const ComplaintListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(complaintRepositoryProvider);
      final created = await repo.createFeedback(payload);
      final latest = state.valueOrNull ?? const ComplaintListState();
      state = AsyncData(latest.copyWith(isSubmitting: false));
      return created;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const ComplaintListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(clearError: true));
    }
  }
}

final complaintNotifierProvider =
    AsyncNotifierProvider<ComplaintNotifier, ComplaintListState>(
  ComplaintNotifier.new,
);

final complaintByIdProvider =
    Provider.family<ComplaintModel?, String>((ref, id) {
  final state = ref.watch(complaintNotifierProvider).valueOrNull;
  if (state == null) return null;
  try {
    return state.items.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
