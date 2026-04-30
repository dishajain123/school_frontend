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

class PrincipalDashboard extends ConsumerWidget {
  const PrincipalDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(principalDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final hasStats = stats != null;
    final statsLoading =
        statsAsync.isLoading || (statsAsync.hasError && !hasStats);

    final pendingLeaves = hasStats ? stats.pendingLeaves : 0;
    final openComplaints = hasStats ? stats.openComplaints : 0;

    final attentionItems = [
      if (hasStats && pendingLeaves > 0)
        AttentionItem(
          label: 'Leave Request${pendingLeaves == 1 ? '' : 's'} Pending',
          icon: Icons.beach_access_outlined,
          color: AppColors.warningAmber,
          count: pendingLeaves,
          onTap: () => context.go(RouteNames.leaveList),
        ),
      if (hasStats && openComplaints > 0)
        AttentionItem(
          label: 'Complaint${openComplaints == 1 ? '' : 's'}',
          icon: Icons.feedback_outlined,
          color: AppColors.errorRed,
          count: openComplaints,
          onTap: () => context.go(RouteNames.complaints),
        ),
    ];

    final primaryActions = [
      QuickActionItem(
        icon: Icons.school_outlined,
        label: 'Students',
        color: AppColors.navyMedium,
        onTap: () => context.go(RouteNames.students),
      ),
      QuickActionItem(
        icon: Icons.co_present_outlined,
        label: 'Teachers',
        color: AppColors.infoBlue,
        onTap: () => context.go(RouteNames.teachers),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.class_outlined,
        label: 'Classroom',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.classroomMonitor),
      ),
    ];

    final secondaryActions = [
      QuickActionItem(
        icon: Icons.family_restroom_outlined,
        label: 'Parents',
        color: AppColors.subjectMath,
        onTap: () => context.go(RouteNames.parents),
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fees',
        color: AppColors.goldPrimary,
        onTap: () => context.go(RouteNames.feeDashboard),
      ),
      QuickActionItem(
        icon: Icons.schedule_outlined,
        label: 'Timetable',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.timetable),
      ),
      QuickActionItem(
        icon: Icons.assessment_outlined,
        label: 'Results',
        color: AppColors.subjectHindi,
        onTap: () => context.go(RouteNames.principalResultsDistribution),
      ),
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Behaviour',
        color: AppColors.subjectHistory,
        onTap: () => context.go(RouteNames.behaviourLogs),
      ),
      QuickActionItem(
        icon: Icons.campaign_outlined,
        label: 'Announcements',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.announcements),
      ),
      QuickActionItem(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.galleryAlbums),
      ),
      QuickActionItem(
        icon: Icons.beach_access_outlined,
        label: 'Leave',
        color: AppColors.warningAmber,
        onTap: () => context.go(RouteNames.leaveList),
      ),
      QuickActionItem(
        icon: Icons.feedback_outlined,
        label: 'Complaints',
        color: AppColors.errorRed,
        onTap: () => context.go(RouteNames.complaints),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(principalDashboardStatsProvider);
          await ref.read(principalDashboardStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: 'Manage your school effectively.',
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
                  if (attentionItems.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space12),
                    NeedsAttentionSection(items: attentionItems),
                  ],
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
                label: 'Students',
                value: (stats?.totalStudents ?? 0).toString(),
                icon: Icons.school_outlined,
                iconColor: AppColors.navyMedium,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.students),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Teachers',
                value: (stats?.totalTeachers ?? 0).toString(),
                icon: Icons.co_present_outlined,
                iconColor: AppColors.infoBlue,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.teachers),
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
