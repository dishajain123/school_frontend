import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/result_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/timetable_hub_ui_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../exam_schedule/screens/exam_schedule_list_screen.dart';
import 'timetable_view_screen.dart';

/// Shell that combines **daily class timetable** and **exam schedule** (per class),
/// aligned with admin console + backend (`/timetable`, `/exam-schedules`, upload flows).
class TimetableHubScreen extends ConsumerStatefulWidget {
  const TimetableHubScreen({
    super.key,
    this.initialTabIndex = 0,
    this.standardId,
    this.section,
    this.academicYearId,
  });

  /// 0 = class timetable, 1 = exam schedule
  final int initialTabIndex;

  final String? standardId;
  final String? section;
  final String? academicYearId;

  @override
  ConsumerState<TimetableHubScreen> createState() => _TimetableHubScreenState();
}

class _TimetableHubScreenState extends ConsumerState<TimetableHubScreen> {
  late int _tabIndex;

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTabIndex == 1 ? 1 : 0;
  }

  @override
  void dispose() {
    ref.read(timetableHubExamStandardIdProvider.notifier).state = null;
    ref.read(timetableHubClassActionsProvider.notifier).state =
        const TimetableHubClassActions();
    super.dispose();
  }

  void _refreshExamTab() {
    final user = ref.read(currentUserProvider);
    final y = ref.read(activeYearProvider)?.id;
    if (user?.role == UserRole.parent) {
      ref.read(childrenNotifierProvider.notifier).loadMyChildren();
    } else if (user?.role == UserRole.student) {
      ref.invalidate(studentRepositoryProvider);
    }
    ref.invalidate(standardsProvider(y));
    if (user != null && user.role == UserRole.teacher) {
      ref.invalidate(myTeacherAssignmentsProvider(y));
      ref.invalidate(teacherAssignmentsByTeacherProvider(user.id));
    }
    ref.invalidate(examListProvider);
    ref.invalidate(examScheduleTimetableProvider);
  }

  List<Widget> _hubAppBarActions(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final examStd = ref.watch(timetableHubExamStandardIdProvider);
    final classAct = ref.watch(timetableHubClassActionsProvider);

    if (_tabIndex == 1) {
      final canUploadExamPdf = user?.role == UserRole.teacher ||
          user?.role == UserRole.principal ||
          (user?.role.isSchoolScopedAdmin ?? false);
      return [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
          tooltip: 'Refresh',
          onPressed: _refreshExamTab,
        ),
        if (canUploadExamPdf)
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf_outlined,
              color: AppColors.white,
            ),
            tooltip: 'Upload exam schedule PDF',
            onPressed: examStd != null && examStd.isNotEmpty
                ? () {
                    final uri = Uri(
                      path: RouteNames.uploadTimetable,
                      queryParameters: {
                        'standard_id': examStd,
                        'exam_mode': 'true',
                      },
                    );
                    context.push(uri.toString());
                  }
                : null,
          ),
      ];
    }

    return [
      if (classAct.loadedStandardId != null)
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
          tooltip: 'Refresh',
          onPressed: () {
            ref.invalidate(
              timetableProvider((
                standardId: classAct.loadedStandardId!,
                academicYearId: classAct.academicYearId,
                section: classAct.loadedSection,
                examId: null,
              )),
            );
          },
        ),
      if (classAct.canUpload)
        IconButton(
          icon: const Icon(Icons.upload_file_outlined, color: AppColors.white),
          tooltip: 'Upload timetable',
          onPressed: () async {
            final uri = Uri(
              path: RouteNames.uploadTimetable,
              queryParameters: {
                if (classAct.selectedStandardId != null)
                  'standard_id': classAct.selectedStandardId!,
                if (classAct.selectedSection != null &&
                    classAct.selectedSection!.trim().isNotEmpty)
                  'section': classAct.selectedSection!,
              },
            );
            await context.push(uri.toString());
            if (classAct.loadedStandardId != null && context.mounted) {
              ref.invalidate(
                timetableProvider((
                  standardId: classAct.loadedStandardId!,
                  academicYearId: classAct.academicYearId,
                  section: classAct.loadedSection,
                  examId: null,
                )),
              );
            }
          },
        ),
      if (classAct.canUpload && classAct.loadedStandardId != null)
        IconButton(
          icon:
              const Icon(Icons.delete_outline_rounded, color: AppColors.white),
          tooltip: 'Remove timetable',
          onPressed: () async {
            final standardId = classAct.loadedStandardId;
            if (standardId == null) return;
            final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Remove timetable?'),
                    content: Text(
                      classAct.loadedSection == null ||
                              classAct.loadedSection!.isEmpty
                          ? 'This will remove the class timetable for the selected academic year.'
                          : 'This will remove timetable for section ${classAct.loadedSection!}.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.errorRed,
                        ),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ) ??
                false;
            if (!confirm || !context.mounted) return;

            final success =
                await ref.read(timetableDeleteProvider.notifier).delete(
                      standardId: standardId,
                      academicYearId: classAct.academicYearId,
                      section: classAct.loadedSection,
                      examId: null,
                    );
            if (!context.mounted) return;

            if (success) {
              SnackbarUtils.showSuccess(context, 'Timetable removed');
              ref.invalidate(
                timetableProvider((
                  standardId: standardId,
                  academicYearId: classAct.academicYearId,
                  section: classAct.loadedSection,
                  examId: null,
                )),
              );
            } else {
              final error = ref.read(timetableDeleteProvider).error;
              SnackbarUtils.showError(
                context,
                error ?? 'Failed to remove timetable',
              );
            }
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: 'Timetable',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
        actions: _hubAppBarActions(context),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: SegmentedButton<int>(
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.navyDeep,
                selectedForegroundColor: AppColors.white,
                foregroundColor: AppColors.grey700,
              ),
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  icon: Icon(Icons.schedule_outlined, size: 18),
                  label: Text('Class timetable'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text('Exam PDFs'),
                ),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (Set<int> selection) {
                setState(() => _tabIndex = selection.first);
              },
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            child: Text(
              _tabIndex == 0
                  ? 'Class timetable: daily schedule PDF per class/section. Upload uses “Upload timetable” (not exam mode).'
                  : 'Exam PDFs: separate from class timetable. Pick class → exam → section, then open PDFs or use “Upload exam PDF” (exam mode).',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Expanded(
            child: IndexedStack(
              index: _tabIndex,
              sizing: StackFit.expand,
              children: [
                SizedBox.expand(
                  child: TimetableViewScreen(
                    key: const ValueKey('hub-class-timetable'),
                    embedInHub: true,
                    standardId: widget.standardId,
                    section: widget.section,
                    academicYearId: widget.academicYearId,
                  ),
                ),
                const SizedBox.expand(
                  child: ExamScheduleListScreen(
                    key: ValueKey('hub-exam-schedule'),
                    embedInHub: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
