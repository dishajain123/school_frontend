import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/timetable_placeholder.dart';
import '../widgets/timetable_viewer.dart';

final _myStudentProfileProvider =
    FutureProvider.autoDispose<StudentModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.read(studentNotifierProvider.notifier).getById(user.id);
});

class TimetableViewScreen extends ConsumerWidget {
  /// Pass [standardId] to view a specific class (PRINCIPAL/TEACHER use case).
  /// When null the screen resolves standardId from the viewer's role context.
  const TimetableViewScreen({
    super.key,
    this.standardId,
    this.section,
  });

  final String? standardId;
  final String? section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);

    if (currentUser == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Timetable', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // STUDENT — scope to own standard
    if (currentUser.role.name == 'STUDENT') {
      return _StudentTimetableView(
        section: section,
        academicYearId: activeYear?.id,
      );
    }

    // PARENT — scope to selected child's standard
    if (currentUser.role.name == 'PARENT') {
      return _ParentTimetableView(
        section: section,
        academicYearId: activeYear?.id,
      );
    }

    // PRINCIPAL / TEACHER / etc — standardId must be provided
    if (standardId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Timetable', showBack: true),
        body: AppEmptyState(
          icon: Icons.schedule_outlined,
          title: 'No class selected',
          subtitle: 'Please navigate here from a class page.',
        ),
      );
    }

    return _TimetableContent(
      standardId: standardId!,
      section: section,
      academicYearId: activeYear?.id,
    );
  }
}

// ── Student-scoped view ───────────────────────────────────────────────────────

class _StudentTimetableView extends ConsumerWidget {
  const _StudentTimetableView({this.section, this.academicYearId});
  final String? section;
  final String? academicYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(_myStudentProfileProvider);

    return studentAsync.when(
      loading: () => AppScaffold(
        appBar: const AppAppBar(title: 'Timetable', showBack: true),
        body: AppLoading.fullPage(),
      ),
      error: (e, _) => AppScaffold(
        appBar: const AppAppBar(title: 'Timetable', showBack: true),
        body: AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_myStudentProfileProvider),
        ),
      ),
      data: (student) {
        if (student == null) {
          return AppScaffold(
            appBar: const AppAppBar(title: 'Timetable', showBack: true),
            body: AppEmptyState(
              icon: Icons.schedule_outlined,
              title: 'Class not found',
              subtitle: 'Your class information is not available yet.',
            ),
          );
        }
        if (student.standardId == null) {
          return AppScaffold(
            appBar: const AppAppBar(title: 'Timetable', showBack: true),
            body: AppEmptyState(
              icon: Icons.schedule_outlined,
              title: 'Class not found',
              subtitle: 'Your class information is not available yet.',
            ),
          );
        }
        return _TimetableContent(
          standardId: student.standardId!,
          section: section ?? student.section,
          academicYearId: academicYearId,
        );
      },
    );
  }
}

// ── Parent-scoped view ────────────────────────────────────────────────────────

class _ParentTimetableView extends ConsumerWidget {
  const _ParentTimetableView({this.section, this.academicYearId});
  final String? section;
  final String? academicYearId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Timetable', showBack: true),
        body: AppEmptyState(
          icon: Icons.schedule_outlined,
          title: 'No child selected',
          subtitle:
              'Select a child from the dashboard to view their timetable.',
        ),
      );
    }

    if (selectedChild.standardId == null) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Timetable', showBack: true),
        body: AppEmptyState(
          icon: Icons.schedule_outlined,
          title: 'Class not found',
          subtitle: 'Child class information is not available yet.',
        ),
      );
    }

    return _TimetableContent(
      standardId: selectedChild.standardId!,
      section: section ?? selectedChild.section,
      academicYearId: academicYearId,
    );
  }
}

// ── Core timetable content ────────────────────────────────────────────────────

class _TimetableContent extends ConsumerWidget {
  const _TimetableContent({
    required this.standardId,
    this.section,
    this.academicYearId,
  });

  final String standardId;
  final String? section;
  final String? academicYearId;

  TimetableParams get _params => (
        standardId: standardId,
        academicYearId: academicYearId,
        section: section,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isPrincipal = currentUser?.role.name == 'PRINCIPAL';
    final timetableAsync = ref.watch(timetableProvider(_params));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Timetable',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(timetableProvider(_params)),
          ),
          if (isPrincipal)
            IconButton(
              icon: const Icon(Icons.upload_file_outlined,
                  color: AppColors.white),
              tooltip: 'Upload new timetable',
              onPressed: () async {
                final uploaded = await context.push<bool>('/timetable/upload');
                if (uploaded == true) {
                  ref.invalidate(timetableProvider(_params));
                }
              },
            ),
        ],
      ),
      body: timetableAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) {
          final msg = e.toString();
          // 404 / "Timetable" → no timetable uploaded yet
          if (msg.contains('404') ||
              msg.toLowerCase().contains('timetable') ||
              msg.contains('Not Found')) {
            return TimetablePlaceholder(canUpload: isPrincipal);
          }
          return AppErrorState(
            message: msg,
            onRetry: () => ref.invalidate(timetableProvider(_params)),
          );
        },
        data: (timetable) {
          if (timetable.fileUrl == null) {
            return TimetablePlaceholder(canUpload: isPrincipal);
          }
          return Column(
            children: [
              _TimetableMetaBar(timetable: timetable),
              Expanded(
                child: TimetableViewer(timetable: timetable),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Meta info strip ───────────────────────────────────────────────────────────

class _TimetableMetaBar extends StatelessWidget {
  const _TimetableMetaBar({required this.timetable});
  final TimetableModel timetable;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          // File type icon badge
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              timetable.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              size: 18,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          // File name + effective date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timetable.fileName,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timetable.effectiveFrom != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'From ${DateFormatter.formatDate(timetable.effectiveFrom!)}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            DateFormatter.formatRelative(timetable.updatedAt),
            style: AppTypography.caption.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}
