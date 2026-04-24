import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/diary/diary_model.dart';
import '../data/repositories/diary_repository.dart';

// ── Params type for the list provider ────────────────────────────────────────
//
// date           — required ISO string "yyyy-MM-dd". The screen always passes
//                  today's date or the user's chosen date.
// subjectId      — optional UUID to filter by subject (used by teachers).
// academicYearId — optional UUID; when null the backend uses the active year.
//
typedef DiaryParams = ({
  String? date,
  String? standardId,
  String? subjectId,
  String? academicYearId,
});

// ── Diary list provider ───────────────────────────────────────────────────────
//
// FutureProvider.family is the right fit here:
//   • The list is purely date/filter-driven — changing date = new provider key.
//   • Each day's diary is small (≤ ~20 items) — no pagination required.
//   • Pull-to-refresh is handled by ref.invalidate in the screen.
//
final diaryListProvider = FutureProvider.family<DiaryListResponse, DiaryParams>(
  (ref, params) async {
    final repo = ref.read(diaryRepositoryProvider);
    return repo.listDiary(
      date: params.date,
      standardId: params.standardId,
      subjectId: params.subjectId,
      academicYearId: params.academicYearId,
      page: 1,
      pageSize: 100, // Daily diary lists are small; load all in one shot
    );
  },
);
