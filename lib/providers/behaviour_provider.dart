import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/behaviour/behaviour_log_model.dart';
import '../data/repositories/behaviour_repository.dart';

typedef BehaviourLogsQuery = ({
  String? studentId,
  IncidentType? incidentType,
  String? standardId,
  String? section,
});

final behaviourLogsProvider =
    FutureProvider.family<BehaviourLogListResponse, BehaviourLogsQuery>(
  (ref, query) async {
    final repo = ref.read(behaviourRepositoryProvider);
    return repo.list(
      studentId: query.studentId,
      incidentType: query.incidentType,
      standardId: query.standardId,
      section: query.section,
    );
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
      ref.invalidate(
        behaviourLogsProvider(
          (
            studentId: (studentId != null && studentId.isNotEmpty)
                ? studentId
                : null,
            incidentType: null,
            standardId: null,
            section: null,
          ),
        ),
      );
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
