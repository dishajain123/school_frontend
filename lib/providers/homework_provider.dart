import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/homework/homework_model.dart';
import '../data/repositories/homework_repository.dart';

// ── Params type for the list provider ────────────────────────────────────────
//
// date          — required ISO string "yyyy-MM-dd". The screen always passes
//                 today's date or the user's chosen date.
// subjectId     — optional UUID to filter by subject (used by teachers).
// academicYearId — optional UUID; when null the backend uses the active year.
//
typedef HomeworkParams = ({
  String date,
  String? subjectId,
  String? academicYearId,
});

// ── Homework list provider ────────────────────────────────────────────────────
//
// FutureProvider.family is the right fit here:
//   • The list is purely date/filter-driven — changing date = new provider key.
//   • Each day's homework is small (≤ ~20 items) — no pagination required.
//   • Pull-to-refresh is handled by ref.invalidate in the screen.
//
final homeworkListProvider =
    FutureProvider.family<HomeworkListResponse, HomeworkParams>(
  (ref, params) async {
    final repo = ref.read(homeworkRepositoryProvider);
    return repo.listHomework(
      date: params.date,
      subjectId: params.subjectId,
      academicYearId: params.academicYearId,
      page: 1,
      pageSize: 100, // Daily homework lists are small; load all in one shot
    );
  },
);