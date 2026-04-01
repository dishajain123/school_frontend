import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/masters/grade_master_model.dart';
import '../data/models/masters/standard_model.dart';
import '../data/models/masters/subject_model.dart';
import '../data/repositories/masters_repository.dart';

// ── Standards ─────────────────────────────────────────────────────────────────

class StandardsNotifier extends AsyncNotifier<List<StandardModel>> {
  String? _academicYearId;

  @override
  Future<List<StandardModel>> build() async {
    return _fetch();
  }

  Future<List<StandardModel>> _fetch() async {
    final repo = ref.read(mastersRepositoryProvider);
    return repo.listStandards(academicYearId: _academicYearId);
  }

  Future<void> refresh({String? academicYearId}) async {
    _academicYearId = academicYearId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final created = await repo.createStandard(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]..sort((a, b) => a.level.compareTo(b.level)));
  }

  Future<void> updateStandard(String id, Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final updated = await repo.updateStandard(id, payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((s) => s.id == id ? updated : s).toList()
        ..sort((a, b) => a.level.compareTo(b.level)),
    );
  }

  Future<void> delete(String id) async {
    final repo = ref.read(mastersRepositoryProvider);
    await repo.deleteStandard(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }
}

final standardsNotifierProvider =
    AsyncNotifierProvider<StandardsNotifier, List<StandardModel>>(
  () => StandardsNotifier(),
);

// Filtered by academic year – used by pickers in other modules
final standardsProvider = FutureProvider.family<List<StandardModel>, String?>(
  (ref, academicYearId) async {
    final repo = ref.read(mastersRepositoryProvider);
    return repo.listStandards(academicYearId: academicYearId);
  },
);

// ── Subjects ──────────────────────────────────────────────────────────────────

class SubjectsNotifier extends AsyncNotifier<List<SubjectModel>> {
  String? _standardId;

  @override
  Future<List<SubjectModel>> build() async {
    return _fetch();
  }

  Future<List<SubjectModel>> _fetch() async {
    final repo = ref.read(mastersRepositoryProvider);
    return repo.listSubjects(standardId: _standardId);
  }

  Future<void> refresh({String? standardId}) async {
    _standardId = standardId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final created = await repo.createSubject(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]);
  }

  Future<void> updateSubject(String id, Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final updated = await repo.updateSubject(id, payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((s) => s.id == id ? updated : s).toList());
  }

  Future<void> delete(String id) async {
    final repo = ref.read(mastersRepositoryProvider);
    await repo.deleteSubject(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((s) => s.id != id).toList());
  }
}

final subjectsNotifierProvider =
    AsyncNotifierProvider<SubjectsNotifier, List<SubjectModel>>(
  () => SubjectsNotifier(),
);

// Family provider – used by pickers across modules
final subjectsProvider = FutureProvider.family<List<SubjectModel>, String?>(
  (ref, standardId) async {
    final repo = ref.read(mastersRepositoryProvider);
    return repo.listSubjects(standardId: standardId);
  },
);

// ── Grades ────────────────────────────────────────────────────────────────────

class GradesNotifier extends AsyncNotifier<List<GradeMasterModel>> {
  @override
  Future<List<GradeMasterModel>> build() async {
    return _fetch();
  }

  Future<List<GradeMasterModel>> _fetch() async {
    final repo = ref.read(mastersRepositoryProvider);
    return repo.listGrades();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final created = await repo.createGrade(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]..sort((a, b) => b.minPercent.compareTo(a.minPercent)));
  }

  Future<void> updateGrade(String id, Map<String, dynamic> payload) async {
    final repo = ref.read(mastersRepositoryProvider);
    final updated = await repo.updateGrade(id, payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData(
      current.map((g) => g.id == id ? updated : g).toList()
        ..sort((a, b) => b.minPercent.compareTo(a.minPercent)),
    );
  }

  Future<void> delete(String id) async {
    final repo = ref.read(mastersRepositoryProvider);
    await repo.deleteGrade(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((g) => g.id != id).toList());
  }
}

final gradesNotifierProvider =
    AsyncNotifierProvider<GradesNotifier, List<GradeMasterModel>>(
  () => GradesNotifier(),
);

final gradesProvider = FutureProvider<List<GradeMasterModel>>((ref) async {
  final repo = ref.read(mastersRepositoryProvider);
  return repo.listGrades();
});
