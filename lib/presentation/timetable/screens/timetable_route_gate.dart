import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import 'timetable_hub_screen.dart';
import 'timetable_view_screen.dart';

/// Dual **Class timetable + Exam schedule** hub is shown **only for principals**.
/// Other roles get the standard single timetable screen.
class TimetableRouteGate extends ConsumerWidget {
  const TimetableRouteGate({
    super.key,
    required this.initialTabIndex,
    this.standardId,
    this.section,
    this.academicYearId,
  });

  final int initialTabIndex;
  final String? standardId;
  final String? section;
  final String? academicYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role;
    if (role == UserRole.principal) {
      return TimetableHubScreen(
        initialTabIndex: initialTabIndex,
        standardId: standardId,
        section: section,
        academicYearId: academicYearId,
      );
    }
    return TimetableViewScreen(
      embedInHub: false,
      standardId: standardId,
      section: section,
      academicYearId: academicYearId,
    );
  }
}
