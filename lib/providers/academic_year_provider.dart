import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/academic_year/academic_year_model.dart';
import '../data/repositories/academic_year_repository.dart';

class AcademicYearNotifier extends AsyncNotifier<List<AcademicYearModel>> {
  @override
  Future<List<AcademicYearModel>> build() async {
    return _fetch();
  }

  Future<List<AcademicYearModel>> _fetch() async {
    final repo = ref.read(academicYearRepositoryProvider);
    return repo.list();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<AcademicYearModel> create(Map<String, dynamic> payload) async {
    final repo = ref.read(academicYearRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([...current, created]);
    return created;
  }

  Future<AcademicYearModel> updateAcademicYear(
      String id, Map<String, dynamic> payload) async {
    final repo = ref.read(academicYearRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((y) => y.id == id ? updated : y).toList());
    return updated;
  }

  Future<AcademicYearModel> activate(String id) async {
    final repo = ref.read(academicYearRepositoryProvider);
    final activated = await repo.activate(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current
        .map((y) => y.id == id ? activated : AcademicYearModel.fromJson({...y.toJson(), 'is_active': false}))
        .toList());
    return activated;
  }

  Future<Map<String, int>> rollover(String oldYearId, {String? newYearId}) async {
    final repo = ref.read(academicYearRepositoryProvider);
    return repo.rollover(oldYearId, newYearId: newYearId);
  }
}

final academicYearNotifierProvider =
    AsyncNotifierProvider<AcademicYearNotifier, List<AcademicYearModel>>(
  () => AcademicYearNotifier(),
);

final activeYearProvider = Provider<AcademicYearModel?>((ref) {
  final years = ref.watch(academicYearNotifierProvider).valueOrNull ?? [];
  try {
    return years.firstWhere((y) => y.isActive);
  } catch (_) {
    return null;
  }
});
