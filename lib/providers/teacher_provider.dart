import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth/current_user.dart';
import '../data/models/teacher/teacher_model.dart';
import '../data/models/teacher/teacher_class_subject_model.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/teacher_repository.dart';
import 'academic_year_provider.dart';
import 'auth_provider.dart';
import 'timetable_provider.dart';

class TeacherFilters {
  const TeacherFilters({
    this.academicYearId,
    this.standardId,
    this.subjectId,
    this.subjectName,
  });

  final String? academicYearId;
  final String? standardId;
  final String? subjectId;
  final String? subjectName;
}

class TeacherState {
  const TeacherState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.filters = const TeacherFilters(),
  });

  final List<TeacherModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final TeacherFilters filters;

  bool get hasMore => items.length < total;

  TeacherState copyWith({
    List<TeacherModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    TeacherFilters? filters,
    bool clearError = false,
  }) {
    return TeacherState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

class TeacherNotifier extends AsyncNotifier<TeacherState> {
  @override
  Future<TeacherState> build() async {
    return const TeacherState();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const TeacherState();
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
      final repo = ref.read(teacherRepositoryProvider);
      final latestState = state.valueOrNull ?? const TeacherState();
      final nextPage = refresh ? 1 : latestState.page;

      final result = await repo.list(
        academicYearId: latestState.filters.academicYearId,
        standardId: latestState.filters.standardId,
        subjectId: latestState.filters.subjectId,
        subjectName: latestState.filters.subjectName,
        page: nextPage,
        pageSize: 20,
      );

      final List<TeacherModel> newItems = refresh
          ? List<TeacherModel>.from(result.items)
          : <TeacherModel>[
              ...latestState.items,
              ...result.items,
            ];

      state = AsyncData(
        TeacherState(
          items: newItems,
          total: result.total,
          page: nextPage + 1,
          isLoading: false,
          isLoadingMore: false,
          filters: latestState.filters,
        ),
      );
    } catch (e) {
      final cur = state.valueOrNull ?? const TeacherState();
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
    await load();
  }

  Future<void> setFilter(TeacherFilters filters) async {
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(filters: filters),
    );
    await load(refresh: true);
  }

  Future<TeacherModel> create(Map<String, dynamic> payload) async {
    final repo = ref.read(teacherRepositoryProvider);
    final created = await repo.create(payload);
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(
        items: [created, ...current.items],
        total: current.total + 1,
      ),
    );
    return created;
  }

  Future<TeacherModel> updateTeacher(
      String id, Map<String, dynamic> payload) async {
    final repo = ref.read(teacherRepositoryProvider);
    final updated = await repo.update(id, payload);
    final current = state.valueOrNull ?? const TeacherState();
    state = AsyncData(
      current.copyWith(
        items: current.items.map((t) => t.id == id ? updated : t).toList(),
      ),
    );
    return updated;
  }

  Future<TeacherModel?> getById(String id) async {
    try {
      final repo = ref.read(teacherRepositoryProvider);
      return await repo.getById(id);
    } catch (_) {
      return null;
    }
  }

  Future<TeacherClassSubjectModel> createTeacherAssignment({
    required String teacherId,
    required String standardId,
    required String section,
    required String subjectId,
    required String academicYearId,
  }) async {
    final repo = ref.read(teacherClassSubjectRepositoryProvider);
    final created = await repo.createAssignment(
      teacherId: teacherId,
      standardId: standardId,
      section: section,
      subjectId: subjectId,
      academicYearId: academicYearId,
    );
    ref.invalidate(teacherAssignmentsByTeacherProvider(teacherId));
    ref.invalidate(
      sectionsByStandardProvider(
        (
          standardId: standardId,
          academicYearId: academicYearId,
        ),
      ),
    );
    ref.invalidate(
      timetableSectionsProvider(
        (
          standardId: standardId,
          academicYearId: academicYearId,
        ),
      ),
    );
    return created;
  }

  Future<TeacherClassSubjectModel> updateTeacherAssignment({
    required String assignmentId,
    required String teacherId,
    required String standardId,
    required String section,
    required String subjectId,
    required String academicYearId,
  }) async {
    final repo = ref.read(teacherClassSubjectRepositoryProvider);
    final updated = await repo.updateAssignment(
      assignmentId: assignmentId,
      standardId: standardId,
      section: section,
      subjectId: subjectId,
      academicYearId: academicYearId,
    );
    ref.invalidate(teacherAssignmentsByTeacherProvider(teacherId));
    ref.invalidate(
      sectionsByStandardProvider(
        (
          standardId: standardId,
          academicYearId: academicYearId,
        ),
      ),
    );
    ref.invalidate(
      timetableSectionsProvider(
        (
          standardId: standardId,
          academicYearId: academicYearId,
        ),
      ),
    );
    return updated;
  }

  Future<void> deleteTeacherAssignment({
    required String assignmentId,
    required String teacherId,
  }) async {
    final repo = ref.read(teacherClassSubjectRepositoryProvider);
    await repo.deleteAssignment(assignmentId);
    ref.invalidate(teacherAssignmentsByTeacherProvider(teacherId));
  }
}

final teacherNotifierProvider =
    AsyncNotifierProvider<TeacherNotifier, TeacherState>(
  () => TeacherNotifier(),
);

final teacherAssignmentsByTeacherProvider =
    FutureProvider.family<List<TeacherClassSubjectModel>, String>(
  (ref, teacherId) async {
    final user = ref.watch(currentUserProvider);
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final repo = ref.read(teacherClassSubjectRepositoryProvider);

    // Principals/superadmins should browse the selected teacher;
    // teachers can still see only their own assignments through /mine.
    if (user?.role == UserRole.teacher) {
      return repo.getMyAssignments(academicYearId: activeYearId);
    }
    return repo.listByTeacher(
      teacherId: teacherId,
      academicYearId: activeYearId,
    );
  },
);

typedef SectionsByStandardParams = ({String? standardId, String? academicYearId});

final sectionsByStandardProvider =
    FutureProvider.family<List<String>, SectionsByStandardParams>((ref, params) async {
  final standardId = params.standardId;
  if (standardId == null || standardId.isEmpty) return const <String>[];
  final repo = ref.read(studentRepositoryProvider);
  final sections = await repo.listSections(
    standardId: standardId,
    academicYearId: params.academicYearId,
  );
  return sections.where((s) => s.trim().isNotEmpty).toList();
});
