import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/behaviour/behaviour_log_model.dart';
import '../data/repositories/behaviour_repository.dart';

final behaviourLogsProvider =
    FutureProvider.family<BehaviourLogListResponse, String>(
  (ref, studentId) async {
    final repo = ref.read(behaviourRepositoryProvider);
    return repo.list(studentId);
  },
);

class BehaviourActionState {
  const BehaviourActionState({
    this.isSubmitting = false,
    this.error,
  });

  final bool isSubmitting;
  final String? error;

  BehaviourActionState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return BehaviourActionState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BehaviourActionNotifier extends Notifier<BehaviourActionState> {
  @override
  BehaviourActionState build() {
    return const BehaviourActionState();
  }

  Future<BehaviourLogModel?> create(Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(behaviourRepositoryProvider);
      final created = await repo.create(payload);
      state = state.copyWith(isSubmitting: false);

      final studentId = payload['student_id']?.toString();
      if (studentId != null && studentId.isNotEmpty) {
        ref.invalidate(behaviourLogsProvider(studentId));
      }
      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        error: e.toString(),
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final behaviourActionProvider =
    NotifierProvider<BehaviourActionNotifier, BehaviourActionState>(
  BehaviourActionNotifier.new,
);
