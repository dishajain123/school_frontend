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

class TrusteeDashboard extends ConsumerWidget {
  const TrusteeDashboard({super.key});

  static String _compactAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(trusteeDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final hasStats = stats != null;
    final statsLoading =
        statsAsync.isLoading || (statsAsync.hasError && !hasStats);

    final openComplaints = hasStats ? stats.openComplaints : 0;

    final attentionItems = [
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
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fees',
        color: AppColors.goldPrimary,
        onTap: () => context.go(RouteNames.feeDashboard),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        color: AppColors.subjectScience,
        onTap: () => context.go(
          '${RouteNames.principalReportDetails}?metric=student_attendance',
        ),
      ),
    ];

    final secondaryActions = [
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.campaign_outlined,
        label: 'Announce',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.announcements),
      ),
      QuickActionItem(
        icon: Icons.feedback_outlined,
        label: 'Complaints',
        color: AppColors.errorRed,
        badge: openComplaints > 0 ? openComplaints.toString() : null,
        onTap: () => context.go(RouteNames.complaints),
      ),
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exams',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
      QuickActionItem(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.galleryAlbums),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trusteeDashboardStatsProvider);
          await ref.read(trusteeDashboardStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: 'Overview of school performance.',
              ),
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
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Students',
                              value: hasStats
                                  ? stats.totalStudents.toString()
                                  : '--',
                              icon: Icons.school_outlined,
                              iconColor: AppColors.navyMedium,
                              isLoading: statsLoading,
                              onTap: () => context.go(RouteNames.students),
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: StatCard(
                              label: 'Total Teachers',
                              value: hasStats
                                  ? stats.totalTeachers.toString()
                                  : '--',
                              icon: Icons.co_present_outlined,
                              iconColor: AppColors.infoBlue,
                              isLoading: statsLoading,
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
                              label: 'Fee Collection',
                              value: hasStats
                                  ? '₹${_compactAmount(stats.feesPaidAmount)}'
                                  : '--',
                              icon: Icons.account_balance_wallet_outlined,
                              iconColor: AppColors.goldPrimary,
                              isLoading: statsLoading,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space12),
                          Expanded(
                            child: StatCard(
                              label: 'Open Complaints',
                              value: hasStats
                                  ? stats.openComplaints.toString()
                                  : '--',
                              icon: Icons.feedback_outlined,
                              iconColor: AppColors.errorRed,
                              isLoading: statsLoading,
                              onTap: () => context.go(RouteNames.complaints),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (attentionItems.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space20),
                    NeedsAttentionSection(items: attentionItems),
                  ],
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
