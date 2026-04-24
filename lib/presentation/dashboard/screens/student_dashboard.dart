import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/greeting_header.dart';
import '../widgets/needs_attention_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(myStudentProfileProvider);
    final statsAsync = ref.watch(studentDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final hasStats = stats != null;
    final statsLoading =
        statsAsync.isLoading || (statsAsync.hasError && !hasStats);

    final attendance = hasStats ? stats.attendancePercentage : 0;
    final overdueAssignments = hasStats ? stats.overdueAssignments : 0;
    final openComplaints = hasStats ? stats.openComplaints : 0;

    final attentionItems = [
      if (hasStats && overdueAssignments > 0)
        AttentionItem(
          label:
              '$overdueAssignments Overdue Assignment${overdueAssignments == 1 ? '' : 's'}',
          icon: Icons.assignment_late_outlined,
          color: AppColors.warningAmber,
          count: overdueAssignments,
          onTap: () => context.go(RouteNames.assignments),
        ),
      if (hasStats && attendance > 0 && attendance < 75)
        AttentionItem(
          label: 'Low Attendance (${attendance.toStringAsFixed(1)}%)',
          icon: Icons.warning_amber_outlined,
          color: AppColors.errorRed,
          onTap: () => context.go(RouteNames.attendance),
        ),
      if (hasStats && openComplaints > 0)
        AttentionItem(
          label:
              '$openComplaints Open Complaint${openComplaints == 1 ? '' : 's'}',
          icon: Icons.feedback_outlined,
          color: AppColors.errorRed,
          count: openComplaints,
          onTap: () => context.go(RouteNames.complaints),
        ),
    ];

    final primaryActions = [
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.assignment_outlined,
        label: 'Assignments',
        color: AppColors.infoBlue,
        onTap: () => context.go(RouteNames.assignments),
      ),
      QuickActionItem(
        icon: Icons.home_work_outlined,
        label: 'Homework',
        color: AppColors.subjectMath,
        onTap: () => context.go(RouteNames.homework),
      ),
      QuickActionItem(
        icon: Icons.menu_book_outlined,
        label: 'Diary',
        color: AppColors.warningAmber,
        onTap: () => context.go(RouteNames.diary),
      ),
    ];

    final secondaryActions = [
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exams',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Results',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.results),
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fees',
        color: AppColors.goldPrimary,
        onTap: () => context.go(RouteNames.feeDashboard),
      ),
      QuickActionItem(
        icon: Icons.description_outlined,
        label: 'Documents',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.documents),
      ),
      QuickActionItem(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.galleryAlbums),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myStudentProfileProvider);
          ref.invalidate(classTeachersProvider);
          ref.invalidate(studentDashboardStatsProvider);
          await ref.read(studentDashboardStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreetingHeader(subtitle: 'Keep up the great work!'),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageHorizontal,
                AppDimensions.space20,
                AppDimensions.pageHorizontal,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StudentStatsGrid(
                    stats: stats,
                    isLoading: statsLoading,
                  ),
                  if (attentionItems.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space12),
                    NeedsAttentionSection(items: attentionItems),
                  ],
                  const SizedBox(height: AppDimensions.space16),
                  _StudentClassTeachersCard(meAsync: meAsync),
                  const SizedBox(height: AppDimensions.space20),
                  const AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(
                    actions: [...primaryActions, ...secondaryActions],
                    primaryCount: 4,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentStatsGrid extends StatelessWidget {
  const _StudentStatsGrid({
    required this.stats,
    required this.isLoading,
  });
  final dynamic stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Attendance',
                value:
                    '${(stats?.attendancePercentage ?? 0).toStringAsFixed(1)}%',
                icon: Icons.fact_check_outlined,
                iconColor: AppColors.successGreen,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.attendance),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Active Tasks',
                value: (stats?.activeAssignments ?? 0).toString(),
                icon: Icons.assignment_outlined,
                iconColor: AppColors.infoBlue,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.assignments),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Overdue Tasks',
                value: (stats?.overdueAssignments ?? 0).toString(),
                icon: Icons.assignment_late_outlined,
                iconColor: AppColors.warningAmber,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.assignments),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Upcoming Exams',
                value: (stats?.upcomingExams ?? 0).toString(),
                icon: Icons.quiz_outlined,
                iconColor: AppColors.subjectPhysics,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.examSchedules),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StudentClassTeachersCard extends ConsumerWidget {
  const _StudentClassTeachersCard({required this.meAsync});
  final AsyncValue<StudentModel> meAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return meAsync.when(
      loading: () => _ClassTeachersShell(
        child: Text(
          'Loading class details...',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
        ),
      ),
      error: (e, _) => _ClassTeachersShell(
        child: Text(
          'Could not load class details.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
        ),
      ),
      data: (me) {
        final standardId = me.standardId;
        final rawSection = me.section?.trim();
        final normalizedSection = rawSection?.toUpperCase();
        final yearId = me.academicYearId;

        if (standardId == null || standardId.isEmpty) {
          return _ClassTeachersShell(
            child: Text(
              'Class not assigned yet.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
            ),
          );
        }

        final hasSection =
            normalizedSection != null && normalizedSection.isNotEmpty;
        final classLabel =
            hasSection ? 'Section $normalizedSection' : 'Section not set';

        if (!hasSection) {
          return _ClassTeachersShell(
            sectionLabel: classLabel,
            child: Text(
              'Teachers will appear once section is assigned.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
            ),
          );
        }

        final teachersAsync = ref.watch(classTeachersProvider((
          standardId: standardId,
          section: normalizedSection,
          academicYearId: yearId,
        )));
        final teacherDirectoryAsync =
            ref.watch(teacherDirectoryByStandardProvider((
          standardId: standardId,
          academicYearId: yearId,
        )));

        return _ClassTeachersShell(
          sectionLabel: classLabel,
          child: teachersAsync.when(
            loading: () => Text('Loading teachers...',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
            error: (e, _) => Text('Could not load teachers.',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.errorRed)),
            data: (rows) => _TeachersList(
              rows: rows,
              teacherNameById: teacherDirectoryAsync.valueOrNull ?? const {},
            ),
          ),
        );
      },
    );
  }
}

class _ClassTeachersShell extends StatelessWidget {
  const _ClassTeachersShell({required this.child, this.sectionLabel});
  final String? sectionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.surface100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.co_present_outlined,
                    size: 16, color: AppColors.navyDeep),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class Teachers',
                      style: AppTypography.titleSmall.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700)),
                  if (sectionLabel != null)
                    Text(sectionLabel!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TeachersList extends StatelessWidget {
  const _TeachersList({
    required this.rows,
    required this.teacherNameById,
  });
  final List<TeacherClassSubjectModel> rows;
  final Map<String, String> teacherNameById;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text('No teacher assignments found.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey500));
    }

    final byTeacher = <String, List<TeacherClassSubjectModel>>{};
    for (final r in rows) {
      final key = r.teacherId;
      byTeacher.putIfAbsent(key, () => []).add(r);
    }

    return Column(
      children: byTeacher.entries.map((entry) {
        final teacherRows = entry.value;
        final first = teacherRows.first;
        final teacherCode =
            (first.teacherEmployeeCode?.trim().isNotEmpty ?? false)
                ? first.teacherEmployeeCode!
                : 'Teacher';
        final teacherName = teacherNameById[first.teacherId] ?? teacherCode;
        final subjects = teacherRows.map((r) => r.subjectLabel).toSet().toList()
          ..sort();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.surface100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    size: 14, color: AppColors.navyMedium),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherName,
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600)),
                    Text(teacherCode,
                        style: AppTypography.caption.copyWith(
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w500)),
                    Text(subjects.join(', '),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
