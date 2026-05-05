import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected **standard (class)** for **exam PDF** flows only — distinct from
/// [timetableHubClassActionsProvider] (daily class timetable tab).
///
/// Updated when the user picks a class on [ExamScheduleListScreen] (hub or
/// standalone). Drives the hub app bar **Upload exam PDF** action (`exam_mode`).
final timetableHubExamStandardIdProvider = StateProvider<String?>(
  (ref) => null,
);

/// Snapshot of class-timetable filters + load state from the admin timetable
/// view when embedded in the hub — drives app bar upload / refresh / delete.
class TimetableHubClassActions {
  const TimetableHubClassActions({
    this.academicYearId,
    this.canUpload = false,
    this.selectedStandardId,
    this.selectedSection,
    this.loadedStandardId,
    this.loadedSection,
  });

  final String? academicYearId;
  final bool canUpload;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? loadedStandardId;
  final String? loadedSection;

  @override
  bool operator ==(Object other) {
    return other is TimetableHubClassActions &&
        other.academicYearId == academicYearId &&
        other.canUpload == canUpload &&
        other.selectedStandardId == selectedStandardId &&
        other.selectedSection == selectedSection &&
        other.loadedStandardId == loadedStandardId &&
        other.loadedSection == loadedSection;
  }

  @override
  int get hashCode => Object.hash(
        academicYearId,
        canUpload,
        selectedStandardId,
        selectedSection,
        loadedStandardId,
        loadedSection,
      );
}

final timetableHubClassActionsProvider =
    StateProvider<TimetableHubClassActions>(
  (ref) => const TimetableHubClassActions(),
);
