import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/announcement/announcement_model.dart';
import '../data/repositories/announcement_repository.dart';

class AnnouncementNotifier extends AsyncNotifier<List<AnnouncementModel>> {
  @override
  Future<List<AnnouncementModel>> build() async {
    return _fetch();
  }

  Future<List<AnnouncementModel>> _fetch({bool includeInactive = false}) async {
    final repo = ref.read(announcementRepositoryProvider);
    return repo.list(includeInactive: includeInactive);
  }

  Future<void> refresh({bool includeInactive = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(includeInactive: includeInactive));
  }

  Future<void> create(Map<String, dynamic> payload) async {
    final repo = ref.read(announcementRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData([created, ...current]);
  }

  Future<void> updateAnnouncement(String id, Map<String, dynamic> payload) async {
    final repo = ref.read(announcementRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((a) => a.id == id ? updated : a).toList());
  }
}

final announcementNotifierProvider =
    AsyncNotifierProvider<AnnouncementNotifier, List<AnnouncementModel>>(
  () => AnnouncementNotifier(),
);
