import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/leave/leave_balance_model.dart';
import '../data/models/leave/leave_model.dart';
import '../data/repositories/leave_repository.dart';

// ── Leave List State ──────────────────────────────────────────────────────────

class LeaveListState {
  const LeaveListState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.statusFilter,
    this.academicYearId,
  });

  final List<LeaveModel> items;
  final int total;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final LeaveStatus? statusFilter;
  final String? academicYearId;

  LeaveListState copyWith({
    List<LeaveModel>? items,
    int? total,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    LeaveStatus? statusFilter,
    String? academicYearId,
    bool clearError = false,
    bool clearStatusFilter = false,
  }) {
    return LeaveListState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      statusFilter:
          clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      academicYearId: academicYearId ?? this.academicYearId,
    );
  }
}

// ── Leave List Notifier ───────────────────────────────────────────────────────

class LeaveNotifier extends AsyncNotifier<LeaveListState> {
  @override
  Future<LeaveListState> build() async {
    return const LeaveListState();
  }

  // ── Load / Refresh ─────────────────────────────────────────────────────────

  Future<void> load({
    LeaveStatus? statusFilter,
    String? academicYearId,
    bool refresh = false,
  }) async {
    final current = state.valueOrNull ?? const LeaveListState();
    final effectiveStatus = statusFilter ?? current.statusFilter;
    final effectiveYear = academicYearId ?? current.academicYearId;

    state = AsyncData(
      current.copyWith(
        isLoading: true,
        statusFilter: effectiveStatus,
        academicYearId: effectiveYear,
        clearError: true,
      ),
    );

    try {
      final repo = ref.read(leaveRepositoryProvider);
      final result = await repo.list(
        status: effectiveStatus,
        academicYearId: effectiveYear,
      );
      state = AsyncData(
        (state.valueOrNull ?? const LeaveListState()).copyWith(
          items: result.items,
          total: result.total,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const LeaveListState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  // ── Filter ─────────────────────────────────────────────────────────────────

  Future<void> setStatusFilter(LeaveStatus? status) async {
    final current = state.valueOrNull ?? const LeaveListState();
    state = AsyncData(
      current.copyWith(
        statusFilter: status,
        clearStatusFilter: status == null,
      ),
    );
    await load();
  }

  // ── Apply Leave (TEACHER) ──────────────────────────────────────────────────

  Future<LeaveModel?> apply({
    required LeaveType leaveType,
    required DateTime fromDate,
    required DateTime toDate,
    String? reason,
    String? academicYearId,
  }) async {
    final current = state.valueOrNull ?? const LeaveListState();
    state = AsyncData(
      current.copyWith(isSubmitting: true, clearError: true),
    );

    try {
      final repo = ref.read(leaveRepositoryProvider);
      final created = await repo.apply(
        leaveType: leaveType,
        fromDate: fromDate,
        toDate: toDate,
        reason: reason,
        academicYearId: academicYearId,
      );

      // Optimistic prepend
      final updated = state.valueOrNull ?? const LeaveListState();
      state = AsyncData(
        updated.copyWith(
          items: [created, ...updated.items],
          total: updated.total + 1,
          isSubmitting: false,
        ),
      );

      // Invalidate balance cache since applying uses balance
      ref.invalidate(leaveBalanceProvider);

      return created;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const LeaveListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  // ── Decide Leave (PRINCIPAL) ───────────────────────────────────────────────

  Future<LeaveModel?> decide({
    required String leaveId,
    required LeaveStatus status,
    String? remarks,
  }) async {
    final current = state.valueOrNull ?? const LeaveListState();
    state = AsyncData(
      current.copyWith(isSubmitting: true, clearError: true),
    );

    try {
      final repo = ref.read(leaveRepositoryProvider);
      final updated = await repo.decide(
        leaveId: leaveId,
        status: status,
        remarks: remarks,
      );

      // Update item in list
      final cur = state.valueOrNull ?? const LeaveListState();
      state = AsyncData(
        cur.copyWith(
          items: cur.items
              .map((l) => l.id == leaveId ? updated : l)
              .toList(),
          isSubmitting: false,
        ),
      );

      return updated;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const LeaveListState()).copyWith(
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

final leaveNotifierProvider =
    AsyncNotifierProvider<LeaveNotifier, LeaveListState>(
  () => LeaveNotifier(),
);

// ── Leave Balance Provider ────────────────────────────────────────────────────
// FutureProvider.family keyed by academicYearId (nullable string).
// Invalidated when a leave is applied.

final leaveBalanceProvider = FutureProvider.family<List<LeaveBalanceModel>, String?>(
  (ref, academicYearId) async {
    final repo = ref.read(leaveRepositoryProvider);
    return repo.getBalance(academicYearId: academicYearId);
  },
);

// ── Pending Leaves Count (for PRINCIPAL dashboard badge) ──────────────────────

final pendingLeavesCountProvider = Provider<int>((ref) {
  final state = ref.watch(leaveNotifierProvider).valueOrNull;
  if (state == null) return 0;
  return state.items.where((l) => l.isPending).length;
});