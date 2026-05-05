import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/timetable_hub_ui_provider.dart';
import '../../../providers/result_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../timetable/widgets/timetable_compact_preview.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';

bool _canUploadExamSchedulePdf(CurrentUser? user) {
  if (user == null) return false;
  return user.role == UserRole.teacher ||
      user.role == UserRole.principal ||
      user.role.isSchoolScopedAdmin;
}

/// Section default for timetable GET — uses the child in [standardId] for parents.
String? _sectionForExamDocuments(
  WidgetRef ref,
  CurrentUser? user,
  String standardId,
) {
  final sid = standardId.trim();
  if (user?.role == UserRole.parent) {
    final children =
        ref.watch(childrenNotifierProvider).valueOrNull?.children ??
            const <ChildSummaryModel>[];
    ChildSummaryModel? match;
    for (final c in children) {
      if (c.standardId?.trim() == sid) {
        match = c;
        break;
      }
    }
    if (match == null) {
      final sel = ref.watch(selectedChildProvider);
      if (sel?.standardId?.trim() == sid) match = sel;
    }
    if (match == null) return null;
    final sec = match.section?.trim();
    return (sec != null && sec.isNotEmpty) ? sec.toUpperCase() : null;
  }
  if (user?.role == UserRole.student) {
    final prof = ref.watch(myStudentProfileProvider).valueOrNull;
    if (prof?.standardId?.trim() != sid) return null;
    final sec = prof?.section?.trim();
    return (sec != null && sec.isNotEmpty) ? sec.toUpperCase() : null;
  }
  return null;
}

/// Student id for [examListProvider] — must match the selected class where applicable.
String? _studentIdForExamList(
  WidgetRef ref,
  CurrentUser? user,
  String? selectedStandardId,
) {
  if (selectedStandardId == null || selectedStandardId.trim().isEmpty) {
    return null;
  }
  final std = selectedStandardId.trim();
  if (user?.role == UserRole.parent) {
    final children =
        ref.watch(childrenNotifierProvider).valueOrNull?.children ??
            const <ChildSummaryModel>[];
    for (final c in children) {
      if (c.standardId?.trim() == std) return c.id;
    }
    return ref.watch(selectedChildProvider)?.id;
  }
  if (user?.role == UserRole.student) {
    final prof = ref.watch(myStudentProfileProvider).valueOrNull;
    return prof?.id ?? ref.watch(currentStudentIdProvider).valueOrNull;
  }
  return null;
}

/// Class for parent/student is **not** user-selectable — from profile / linked child.
String? _resolveScopedStandardId(WidgetRef ref, CurrentUser? user) {
  if (user == null) return null;
  if (user.role == UserRole.student) {
    return ref.watch(myStudentProfileProvider).valueOrNull?.standardId?.trim();
  }
  if (user.role == UserRole.parent) {
    final sel = ref.watch(selectedChildProvider);
    final fromSel = sel?.standardId?.trim();
    if (fromSel != null && fromSel.isNotEmpty) return fromSel;
    final list = ref.watch(childrenNotifierProvider).valueOrNull?.children ??
        const <ChildSummaryModel>[];
    for (final c in list) {
      final id = c.standardId?.trim();
      if (id != null && id.isNotEmpty) return id;
    }
    return null;
  }
  return null;
}

class ExamScheduleListScreen extends ConsumerStatefulWidget {
  const ExamScheduleListScreen({super.key, this.embedInHub = false});

  /// When [true], no duplicate app bar (used inside [TimetableHubScreen]).
  final bool embedInHub;

  @override
  ConsumerState<ExamScheduleListScreen> createState() =>
      _ExamScheduleListScreenState();
}

class _ExamScheduleListScreenState extends ConsumerState<ExamScheduleListScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => widget.embedInHub;

  Future<void> _refreshScoped(CurrentUser? user) async {
    if (user?.role == UserRole.parent) {
      await ref.read(childrenNotifierProvider.notifier).loadMyChildren();
    } else if (user?.role == UserRole.student) {
      ref.invalidate(studentRepositoryProvider);
    }
  }

  void _invalidateExamData(CurrentUser? user, String? activeYearId) {
    ref.invalidate(examScheduleTimetableProvider);
    ref.invalidate(standardsProvider(activeYearId));
    if (user?.role == UserRole.parent) {
      ref.invalidate(childrenNotifierProvider);
    }
    if (user?.role == UserRole.student) {
      ref.invalidate(myStudentProfileProvider);
      ref.invalidate(currentStudentIdProvider);
    }
    if (user?.role == UserRole.teacher && user != null) {
      ref.invalidate(teacherAssignmentsByTeacherProvider(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final canUploadExamPdf = _canUploadExamSchedulePdf(currentUser);
    final isScopedRole = currentUser?.role == UserRole.parent ||
        currentUser?.role == UserRole.student;

    if (isScopedRole) {
      final scopedBody = SizedBox.expand(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.space16,
            AppDimensions.space16,
            AppDimensions.space16,
            widget.embedInHub ? AppDimensions.space24 : 100,
          ),
          child: _ExamScheduleContent(
            key: ValueKey('exam-scoped-${currentUser?.role}'),
            embedInHub: widget.embedInHub,
          ),
        ),
      );

      if (widget.embedInHub) {
        return scopedBody;
      }

      return AppScaffold(
        appBar: AppAppBar(
          title: 'Exam schedule',
          showBack: true,
          onBackPressed: () => context.go(RouteNames.dashboard),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: () {
                _refreshScoped(currentUser);
                _invalidateExamData(currentUser, activeYear?.id);
              },
            ),
          ],
        ),
        body: scopedBody,
      );
    }

    final listBody = SizedBox.expand(
      child: _ExamScheduleContent(
        embedInHub: widget.embedInHub,
      ),
    );

    if (widget.embedInHub) {
      return listBody;
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Exam schedule',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                _invalidateExamData(currentUser, activeYear?.id),
          ),
          if (canUploadExamPdf)
            Consumer(
              builder: (context, ref, _) {
                final selected =
                    ref.watch(timetableHubExamStandardIdProvider);
                return IconButton(
                  icon: const Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.white,
                  ),
                  tooltip: 'Upload exam schedule PDF',
                  onPressed: selected != null && selected.isNotEmpty
                      ? () {
                          final uri = Uri(
                            path: RouteNames.uploadTimetable,
                            queryParameters: {
                              'standard_id': selected,
                              'exam_mode': 'true',
                            },
                          );
                          context.push(uri.toString());
                        }
                      : null,
                );
              },
            ),
        ],
      ),
      body: listBody,
    );
  }
}

// ── Upload-aligned filters + preview (same semantics as UploadTimetable exam mode)

class _ExamScheduleContent extends ConsumerStatefulWidget {
  const _ExamScheduleContent({
    super.key,
    required this.embedInHub,
  });

  final bool embedInHub;

  @override
  ConsumerState<_ExamScheduleContent> createState() =>
      _ExamScheduleContentState();
}

class _ExamScheduleContentState extends ConsumerState<_ExamScheduleContent> {
  String? _selectedStandardId;
  String? _selectedExamId;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user?.role == UserRole.parent) {
        ref.read(childrenNotifierProvider.notifier).loadMyChildren();
      }
    });
  }

  void _setStandard(String? id) {
    setState(() {
      _selectedStandardId = id;
      _selectedExamId = null;
      _selectedSection = null;
    });
    // Single source for exam-PDF upload (`exam_mode`) — hub app bar + standalone.
    ref.read(timetableHubExamStandardIdProvider.notifier).state = id;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final scopedRole = currentUser?.role == UserRole.parent ||
        currentUser?.role == UserRole.student;
    // Parents/students: load all standards so the child's class always resolves
    // (year-filtered lists can omit a valid standard_id from the API).
    final standardsAsync = ref.watch(
      standardsProvider(scopedRole ? null : activeYear?.id),
    );
    final teacherAssignmentsAsync = (currentUser?.role == UserRole.teacher)
        ? ref.watch(teacherAssignmentsByTeacherProvider(currentUser!.id))
        : const AsyncData<List<TeacherClassSubjectModel>>(
            <TeacherClassSubjectModel>[],
          );

    final scopedSid = scopedRole
        ? _resolveScopedStandardId(ref, currentUser)
        : null;
    final sid = scopedRole ? scopedSid : _selectedStandardId;

    if (widget.embedInHub && scopedRole && sid != null) {
      final hubId = ref.read(timetableHubExamStandardIdProvider);
      if (hubId != sid) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(timetableHubExamStandardIdProvider.notifier).state = sid;
          }
        });
      }
    }

    final examStudentId = _studentIdForExamList(ref, currentUser, sid);
    final parentNeedsStudentForExams =
        currentUser?.role == UserRole.parent &&
            sid != null &&
            (examStudentId == null || examStudentId.isEmpty);
    final studentSectionsAsync = sid == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(sectionsByStandardProvider((
            standardId: sid,
            academicYearId: activeYear?.id,
          )));
    final timetableSectionsAsync = sid == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(timetableSectionsProvider((
            standardId: sid,
            academicYearId: activeYear?.id,
          )));

    final mergedSections = <String>{
      ...studentSectionsAsync.valueOrNull?.map((s) => s.trim().toUpperCase()) ??
          const <String>{},
      ...timetableSectionsAsync.valueOrNull
              ?.map((s) => s.trim().toUpperCase()) ??
          const <String>{},
    }.where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final profileSection =
        (currentUser?.role == UserRole.parent ||
                currentUser?.role == UserRole.student) &&
            sid != null
        ? _sectionForExamDocuments(ref, currentUser, sid)
        : null;
    final sectionCandidate = _selectedSection ?? profileSection;
    final safeSelectedSection =
        mergedSections.contains(sectionCandidate) ? sectionCandidate : null;

    final examsAsync = sid == null || parentNeedsStudentForExams
        ? const AsyncData<List<ExamModel>>(<ExamModel>[])
        : ref.watch(
            examListProvider((
              studentId: examStudentId,
              academicYearId: activeYear?.id,
              standardId: sid,
            )),
          );

    if (scopedRole && sid != null && !parentNeedsStudentForExams) {
      ref.listen(
        examListProvider((
          studentId: examStudentId,
          academicYearId: activeYear?.id,
          standardId: sid,
        )),
        (prev, next) {
          next.whenData((exams) {
            if (exams.isEmpty) return;
            if (_selectedExamId != null) return;
            if (!mounted) return;
            setState(() {
              _selectedExamId = exams.first.id;
            });
          });
        },
      );
    }

    final bottomInset = widget.embedInHub ? AppDimensions.space24 : 100.0;

    final standardsAsyncWhen = standardsAsync.when(
      loading: () => AppLoading.card(height: 46),
      error: (_, __) => _InlineError('Could not load classes'),
      data: (standards) {
        if (currentUser?.role == UserRole.parent) {
          final childrenAsync = ref.watch(childrenNotifierProvider);
          return childrenAsync.when(
            loading: () => AppLoading.card(height: 46),
            error: (e, _) =>
                _InlineError('Could not load children. Pull to refresh.'),
            data: (cs) {
              if (cs.isLoading && cs.children.isEmpty) {
                return AppLoading.card(height: 46);
              }
              final resolved = _resolveScopedStandardId(ref, currentUser);
              if (resolved == null || resolved.isEmpty) {
                return _InlineError(
                  'No class is assigned to your children yet. '
                  'Link a child from the dashboard or ask the school to assign a class.',
                );
              }
              return const SizedBox.shrink();
            },
          );
        }
        if (currentUser?.role == UserRole.student) {
          final profAsync = ref.watch(myStudentProfileProvider);
          return profAsync.when(
            loading: () => AppLoading.card(height: 46),
            error: (_, __) =>
                _InlineError('Could not load your profile. Pull to refresh.'),
            data: (prof) {
              final pid = prof.standardId?.trim();
              if (pid == null || pid.isEmpty) {
                return _InlineError(
                  'Your class is not set yet. Please contact the school.',
                );
              }
              return const SizedBox.shrink();
            },
          );
        }
        if (currentUser?.role == UserRole.teacher) {
          return teacherAssignmentsAsync.when(
            loading: () => AppLoading.card(height: 46),
            error: (_, __) => _InlineError('Could not load classes'),
            data: (assignments) {
              final allowedStandardIds =
                  assignments.map((a) => a.standardId).toSet();
              final allowedStandards = standards
                  .where((s) => allowedStandardIds.contains(s.id))
                  .toList();
              final safeValue = allowedStandardIds.contains(_selectedStandardId)
                  ? _selectedStandardId
                  : null;
              if (safeValue != _selectedStandardId) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _setStandard(safeValue);
                });
              }
              if (allowedStandards.isEmpty) {
                return _InlineError(
                  'No assigned classes. Exam schedule classes appear after principal assignment.',
                );
              }
              return _StyledDropdown<String>(
                hint: 'Select class',
                value: safeValue,
                items: allowedStandards
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                            s.name,
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800),
                          ),
                        ))
                    .toList(),
                onChanged: (id) => _setStandard(id),
              );
            },
          );
        }
        return _StyledDropdown<String>(
          hint: 'Select class',
          value: _selectedStandardId,
          items: standards
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(
                      s.name,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.grey800),
                    ),
                  ))
              .toList(),
          onChanged: (id) => _setStandard(id),
        );
      },
    );

    final fallbackExamYear = examsAsync.maybeWhen(
      data: (exams) =>
          exams.where((e) => e.id == _selectedExamId).firstOrNull?.academicYearId,
      orElse: () => null,
    );

    final ExamScheduleTimetableParams? previewParams =
        sid != null && _selectedExamId != null
            ? (
                standardId: sid,
                primaryAcademicYearId: activeYear?.id,
                fallbackAcademicYearId: fallbackExamYear,
                section: safeSelectedSection,
                examId: _selectedExamId,
              )
            : null;

    final String? previewExamName = examsAsync.maybeWhen(
      data: (exams) => exams
          .where((e) => e.id == _selectedExamId)
          .firstOrNull
          ?.name,
      orElse: () => null,
    );

    // IndexedStack + Padding: avoid zero-height flex bugs; pin minimum scroll height.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.maxHeight;
        final minScrollHeight = maxH.isFinite && maxH > 0
            ? maxH
            : (MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                kToolbarHeight -
                160);

        final scrollBody = SingleChildScrollView(
            physics: scopedRole
                ? const ClampingScrollPhysics()
                : const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              bottomInset,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: minScrollHeight > 0 ? minScrollHeight : 400,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FormCard(
                  title: 'Exam Timetable Details',
                  icon: Icons.school_outlined,
                  children: [
                    if (!scopedRole) ...[
                      const _FieldLabel('Class'),
                      const SizedBox(height: 8),
                      standardsAsyncWhen,
                      const SizedBox(height: 16),
                    ],
                    if (scopedRole) ...[
                      standardsAsyncWhen,
                      const SizedBox(height: 16),
                    ],
                    _FieldLabel('Exam'),
                    const SizedBox(height: 8),
                    examsAsync.when(
                      loading: () => AppLoading.card(height: 46),
                      error: (_, __) => _InlineError('Could not load exams'),
                      data: (exams) {
                        if (parentNeedsStudentForExams) {
                          return _InlineError(
                            scopedRole
                                ? 'Link your child on the dashboard so we can load exams '
                                    '(we need a student id for your account).'
                                : 'Link your child or pick the class your child is in so '
                                    'we can load exams (backend requires a student id for parents).',
                          );
                        }
                        return _StyledDropdown<String>(
                          hint: sid == null
                              ? (scopedRole
                                  ? 'Waiting for class…'
                                  : 'Select class first')
                              : 'Select exam',
                          value: _selectedExamId,
                          items: exams
                              .map(
                                (exam) => DropdownMenuItem(
                                  value: exam.id,
                                  child: Text(
                                    exam.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.grey800,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: sid == null
                              ? (_) {}
                              : (value) =>
                                  setState(() => _selectedExamId = value),
                        );
                      },
                    ),
                    if (!scopedRole) ...[
                      const SizedBox(height: 16),
                      _FieldLabel('Section (optional)'),
                      const SizedBox(height: 8),
                      _StyledDropdown<String?>(
                        hint: sid == null
                            ? 'Select class first'
                            : 'All sections',
                        value: safeSelectedSection,
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'All sections',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.grey800,
                              ),
                            ),
                          ),
                          ...mergedSections.map(
                            (section) => DropdownMenuItem<String?>(
                              value: section,
                              child: Text(
                                section,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.grey800,
                                ),
                              ),
                            ),
                          ),
                        ],
                        onChanged: sid == null
                            ? (_) {}
                            : (value) =>
                                setState(() => _selectedSection = value),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _FieldLabel('Academic Year'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: AppColors.surface50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surface100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.date_range_outlined,
                              size: 16, color: AppColors.grey400),
                          const SizedBox(width: 10),
                          Text(
                            activeYear?.name ?? '—',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _FormCard(
                  title: 'Exam schedule PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  children: [
                    if (sid == null)
                      AppEmptyState(
                        icon: Icons.calendar_month_outlined,
                        title: scopedRole
                            ? 'Class not assigned yet'
                            : 'Choose a class',
                        subtitle: scopedRole
                            ? 'Link a child on the dashboard or ask the school to assign a class.'
                            : 'Select a class above to load exams and view PDFs',
                      )
                    else if (parentNeedsStudentForExams)
                      AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'Link your child',
                        subtitle:
                            'We need a linked student to load exams. Use the dashboard to link a child, then refresh.',
                      )
                    else if (_selectedExamId == null)
                      AppEmptyState(
                        icon: Icons.quiz_outlined,
                        title: 'Choose an exam',
                        subtitle:
                            'Pick an exam above — same filters as Upload Timetable (exam mode)',
                      )
                    else
                      _ExamPdfPreviewCard(
                        params: previewParams!,
                        heading: previewExamName,
                      ),
                  ],
                ),
                ],
              ),
            ),
          );

        if (!scopedRole) {
          return RefreshIndicator(
            onRefresh: () async {
              if (sid != null && !parentNeedsStudentForExams) {
                ref.invalidate(
                  examListProvider((
                    studentId: examStudentId,
                    academicYearId: activeYear?.id,
                    standardId: sid,
                  )),
                );
                ref.invalidate(sectionsByStandardProvider((
                  standardId: sid,
                  academicYearId: activeYear?.id,
                )));
                ref.invalidate(timetableSectionsProvider((
                  standardId: sid,
                  academicYearId: activeYear?.id,
                )));
              }
              ref.invalidate(examScheduleTimetableProvider);
            },
            child: scrollBody,
          );
        }
        return scrollBody;
      },
    );
  }
}

/// Isolated so [ref.watch] on [examScheduleTimetableProvider] is unconditional.
class _ExamPdfPreviewCard extends ConsumerWidget {
  const _ExamPdfPreviewCard({
    required this.params,
    this.heading,
  });

  final ExamScheduleTimetableParams params;
  final String? heading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ttAsync = ref.watch(examScheduleTimetableProvider(params));
    return ttAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(examScheduleTimetableProvider),
      ),
      data: (timetable) {
        if (timetable == null ||
            timetable.fileUrl == null ||
            timetable.fileUrl!.trim().isEmpty) {
          return AppEmptyState(
            icon: Icons.picture_as_pdf_outlined,
            title: 'No PDF for this selection',
            subtitle:
                'Staff can upload from Timetable → Upload (exam mode) for this class and exam.',
          );
        }
        return TimetableCompactPreview(
          timetable: timetable,
          heading: heading ?? 'Exam schedule',
        );
      },
    );
  }
}

// ── Shared with Upload Timetable styling ─────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? AppColors.navyMedium.withValues(alpha: 0.5)
              : AppColors.surface200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(
            hint,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
          ),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 15, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
