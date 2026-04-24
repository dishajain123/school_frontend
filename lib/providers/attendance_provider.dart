import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/attendance/attendance_analytics.dart';
import '../data/models/attendance/attendance_model.dart';
import '../data/models/attendance/attendance_record_input.dart';
import '../data/models/attendance/below_threshold.dart';
import '../data/models/attendance/mark_attendance_request.dart';
import '../data/models/auth/current_user.dart';
import '../data/models/student/student_model.dart';
import '../data/models/teacher/teacher_class_subject_model.dart';
import '../data/repositories/attendance_repository.dart';
import '../data/repositories/student_repository.dart';
import '../data/repositories/teacher_repository.dart';
import 'auth_provider.dart';

typedef AttendanceListParams = ({
  String? studentId,
  String? standardId,
  String? section,
  String? academicYearId,
  String? date,
  int? month,
  int? year,
  String? subjectId,
  int? lectureNumber,
});

typedef StudentAnalyticsParams = ({
  String studentId,
  int? month,
  int? year,
});

typedef BelowThresholdParams = ({
  String standardId,
  String academicYearId,
  double threshold,
});

typedef StudentsForAttendanceParams = ({
  String standardId,
  String section,
  String academicYearId,
});

final myTeacherAssignmentsProvider =
    FutureProvider.family<List<TeacherClassSubjectModel>, String?>(
  (ref, academicYearId) async {
    final repo = ref.read(teacherClassSubjectRepositoryProvider);
    return repo.getMyAssignments(academicYearId: academicYearId);
  },
);

final studentsForAttendanceProvider =
    FutureProvider.family<List<StudentModel>, StudentsForAttendanceParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final items = <StudentModel>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await repo.list(
        standardId: params.standardId,
        section: params.section,
        academicYearId: params.academicYearId,
        page: page,
        pageSize: 100, // backend cap
      );
      items.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);

    int rollOrder(StudentModel s) {
      final raw = s.rollNumber?.trim() ?? '';
      final match = RegExp(r'\d+').firstMatch(raw);
      return int.tryParse(match?.group(0) ?? '') ?? 999999;
    }

    items.sort((a, b) {
      final byRoll = rollOrder(a).compareTo(rollOrder(b));
      if (byRoll != 0) return byRoll;
      return a.admissionNumber.toLowerCase().compareTo(
            b.admissionNumber.toLowerCase(),
          );
    });
    return items;
  },
);

final attendanceListProvider = FutureProvider.family<
    ({List<AttendanceModel> items, int total}), AttendanceListParams>(
  (ref, params) async {
    final repo = ref.read(attendanceRepositoryProvider);
    return repo.listAttendance(
      studentId: params.studentId,
      standardId: params.standardId,
      section: params.section,
      academicYearId: params.academicYearId,
      date: params.date,
      month: params.month,
      year: params.year,
      subjectId: params.subjectId,
      lectureNumber: params.lectureNumber,
    );
  },
);

final studentAnalyticsProvider =
    FutureProvider.family<StudentAttendanceAnalytics, StudentAnalyticsParams>(
  (ref, params) async {
    final repo = ref.read(attendanceRepositoryProvider);
    return repo.getStudentAnalytics(
      params.studentId,
      month: params.month,
      year: params.year,
    );
  },
);

final belowThresholdProvider =
    FutureProvider.family<BelowThresholdResponse, BelowThresholdParams>(
  (ref, params) async {
    final repo = ref.read(attendanceRepositoryProvider);
    return repo.getBelowThreshold(
      standardId: params.standardId,
      academicYearId: params.academicYearId,
      threshold: params.threshold,
    );
  },
);

class MarkAttendanceFormState {
  const MarkAttendanceFormState({
    required this.date,
    this.selectedLectureNumber = 1,
    this.selectedAcademicYearId,
    this.selectedAssignment,
    this.selectedSubjectId,
    this.attendanceMap = const {},
    this.selectedStudentIds = const <String>{},
    this.isSubmitting = false,
    this.submitError,
  });

  final DateTime date;
  final int selectedLectureNumber;
  final String? selectedAcademicYearId;
  final TeacherClassSubjectModel? selectedAssignment;
  final String? selectedSubjectId;
  final Map<String, AttendanceStatus> attendanceMap;
  final Set<String> selectedStudentIds;
  final bool isSubmitting;
  final String? submitError;

  MarkAttendanceFormState copyWith({
    DateTime? date,
    int? selectedLectureNumber,
    String? selectedAcademicYearId,
    TeacherClassSubjectModel? selectedAssignment,
    String? selectedSubjectId,
    Map<String, AttendanceStatus>? attendanceMap,
    Set<String>? selectedStudentIds,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
  }) {
    return MarkAttendanceFormState(
      date: date ?? this.date,
      selectedLectureNumber:
          selectedLectureNumber ?? this.selectedLectureNumber,
      selectedAcademicYearId:
          selectedAcademicYearId ?? this.selectedAcademicYearId,
      selectedAssignment: selectedAssignment ?? this.selectedAssignment,
      selectedSubjectId: selectedSubjectId ?? this.selectedSubjectId,
      attendanceMap: attendanceMap ?? this.attendanceMap,
      selectedStudentIds: selectedStudentIds ?? this.selectedStudentIds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
    );
  }
}

class MarkAttendanceNotifier extends Notifier<MarkAttendanceFormState> {
  @override
  MarkAttendanceFormState build() {
    return MarkAttendanceFormState(date: DateTime.now());
  }

  void setDate(DateTime date) {
    state = state.copyWith(date: date, clearSubmitError: true);
  }

  void setLectureNumber(int lectureNumber) {
    state = state.copyWith(
      selectedLectureNumber: lectureNumber,
      clearSubmitError: true,
    );
  }

  void setAcademicYear(String? academicYearId) {
    final changed = academicYearId != state.selectedAcademicYearId;
    state = state.copyWith(
      selectedAcademicYearId: academicYearId,
      selectedAssignment: changed ? null : state.selectedAssignment,
      selectedSubjectId: changed ? null : state.selectedSubjectId,
      attendanceMap: changed ? const {} : state.attendanceMap,
      selectedStudentIds: changed ? const <String>{} : state.selectedStudentIds,
      clearSubmitError: true,
    );
  }

  void setAssignment(TeacherClassSubjectModel? assignment) {
    state = state.copyWith(
      selectedAssignment: assignment,
      selectedSubjectId: null,
      attendanceMap: const {},
      selectedStudentIds: const <String>{},
      clearSubmitError: true,
    );
  }

  void setSubjectId(String? subjectId) {
    state = state.copyWith(
      selectedSubjectId: subjectId,
      attendanceMap: const {},
      selectedStudentIds: const <String>{},
      clearSubmitError: true,
    );
  }

  void initStudents(List<String> ids) {
    final next = Map<String, AttendanceStatus>.from(state.attendanceMap);
    final incoming = ids.toSet();
    for (final id in ids) {
      next.putIfAbsent(id, () => AttendanceStatus.absent);
    }
    next.removeWhere((key, _) => !incoming.contains(key));

    final selected = Set<String>.from(state.selectedStudentIds)
      ..removeWhere((id) => !incoming.contains(id));

    state = state.copyWith(
      attendanceMap: next,
      selectedStudentIds: selected,
    );
  }

  void preloadExisting(List<AttendanceModel> records) {
    final next = Map<String, AttendanceStatus>.from(state.attendanceMap);
    for (final r in records) {
      next[r.studentId] = r.status;
    }
    state = state.copyWith(attendanceMap: next);
  }

  void setStudentStatus(String studentId, AttendanceStatus status) {
    final next = Map<String, AttendanceStatus>.from(state.attendanceMap);
    next[studentId] = status;
    state = state.copyWith(attendanceMap: next, clearSubmitError: true);
  }

  void toggleStudentSelection(String studentId, bool selected) {
    final next = Set<String>.from(state.selectedStudentIds);
    if (selected) {
      next.add(studentId);
    } else {
      next.remove(studentId);
    }
    state = state.copyWith(selectedStudentIds: next, clearSubmitError: true);
  }

  void selectAll(List<String> studentIds) {
    state = state.copyWith(
      selectedStudentIds: studentIds.toSet(),
      clearSubmitError: true,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedStudentIds: const <String>{},
      clearSubmitError: true,
    );
  }

  void markAll(AttendanceStatus status, List<String> studentIds) {
    final next = Map<String, AttendanceStatus>.from(state.attendanceMap);
    for (final id in studentIds) {
      next[id] = status;
    }
    state = state.copyWith(attendanceMap: next, clearSubmitError: true);
  }

  void markSelected(AttendanceStatus status, Iterable<String> studentIds) {
    final next = Map<String, AttendanceStatus>.from(state.attendanceMap);
    for (final id in studentIds) {
      next[id] = status;
    }
    state = state.copyWith(attendanceMap: next, clearSubmitError: true);
  }

  Future<bool> submit({required List<String> orderedStudentIds}) async {
    final assignment = state.selectedAssignment;
    final subjectId = state.selectedSubjectId;
    final academicYearId = state.selectedAcademicYearId;

    if (assignment == null || subjectId == null || academicYearId == null) {
      state = state.copyWith(
        submitError: 'Please select class, subject, and academic year.',
      );
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);
    try {
      final records = orderedStudentIds
          .map(
            (id) => AttendanceRecordInput(
              studentId: id,
              status: state.attendanceMap[id] ?? AttendanceStatus.absent,
            ),
          )
          .toList();

      final request = MarkAttendanceRequest(
        standardId: assignment.standardId,
        section: assignment.section,
        subjectId: subjectId,
        academicYearId: academicYearId,
        date: state.date,
        lectureNumber: state.selectedLectureNumber,
        records: records,
      );

      final repo = ref.read(attendanceRepositoryProvider);
      await repo.markAttendance(request);

      state = state.copyWith(isSubmitting: false, clearSubmitError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, submitError: e.toString());
      return false;
    }
  }
}

final markAttendanceProvider =
    NotifierProvider<MarkAttendanceNotifier, MarkAttendanceFormState>(
  MarkAttendanceNotifier.new,
);

final currentStudentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user?.role != UserRole.student) return null;

  final repo = ref.read(studentRepositoryProvider);
  try {
    final me = await repo.getMyProfile();
    return me.id;
  } catch (_) {
    // Backward compatibility for deployments without /students/me.
    final result = await repo.list(page: 1, pageSize: 1);
    if (result.items.isEmpty) return null;
    return result.items.first.id;
  }
});
