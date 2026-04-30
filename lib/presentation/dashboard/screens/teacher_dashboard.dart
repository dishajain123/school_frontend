import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers/dashboard_provider.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/greeting_header.dart';
import '../widgets/needs_attention_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(teacherDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final statsLoading = statsAsync.isLoading && stats == null;

    final pendingLeaves = stats?.pendingLeaves ?? 0;
    final overdueAssignments = stats?.overdueAssignments ?? 0;

    final attentionItems = [
      AttentionItem(
        label: 'Leave Request${pendingLeaves == 1 ? '' : 's'} Pending',
        icon: Icons.beach_access_outlined,
        color: AppColors.warningAmber,
        count: pendingLeaves,
        onTap: () => context.go(RouteNames.leaveList),
      ),
      AttentionItem(
        label: 'Overdue Assignment${overdueAssignments == 1 ? '' : 's'}',
        icon: Icons.assignment_late_outlined,
        color: AppColors.errorRed,
        count: overdueAssignments,
        onTap: () => context.go(RouteNames.assignments),
      ),
    ];

    final primaryActions = [
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.markAttendance),
      ),
      QuickActionItem(
        icon: Icons.class_outlined,
        label: 'Classroom',
        color: AppColors.infoBlue,
        onTap: () => context.go(RouteNames.teacherMyClass),
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
        icon: Icons.beach_access_outlined,
        label: 'Leave',
        color: AppColors.subjectHistory,
        onTap: () => context.go(RouteNames.leaveList),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Analytics',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.teacherAnalytics),
      ),
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exam',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
      QuickActionItem(
        icon: Icons.grading_outlined,
        label: 'Results',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.results),
      ),
      QuickActionItem(
        icon: Icons.edit_note_outlined,
        label: 'Enter Marks',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.enterResults),
      ),
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Behaviour',
        color: AppColors.subjectHistory,
        onTap: () => context.go(RouteNames.behaviourLogs),
      ),
      QuickActionItem(
        icon: Icons.campaign_outlined,
        label: 'Announce',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.announcements),
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
          ref.invalidate(teacherDashboardStatsProvider);
          await ref.read(teacherDashboardStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: 'Have a great teaching day!',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageHorizontal,
                AppDimensions.space16,
                AppDimensions.pageHorizontal,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _StatsGrid(
                    stats: stats,
                    isLoading: statsLoading,
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  NeedsAttentionSection(items: attentionItems),
                  const SizedBox(height: AppDimensions.space16),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
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
                label: 'Classroom',
                value: (stats?.myClasses ?? 0).toString(),
                icon: Icons.class_outlined,
                iconColor: AppColors.navyMedium,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.teacherMyClass),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Attendance',
                value:
                    '${(stats?.teacherAttendancePercentage ?? 0).toStringAsFixed(1)}%',
                icon: Icons.bar_chart_outlined,
                iconColor: AppColors.infoBlue,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.attendance),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Leave Pending',
                value: (stats?.pendingLeaves ?? 0).toString(),
                icon: Icons.beach_access_outlined,
                iconColor: AppColors.warningAmber,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.leaveList),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Complaints',
                value: (stats?.openComplaints ?? 0).toString(),
                icon: Icons.feedback_outlined,
                iconColor: AppColors.errorRed,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.complaints),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
