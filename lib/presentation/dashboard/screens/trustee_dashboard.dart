import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';

class TrusteeDashboard extends ConsumerWidget {
  const TrusteeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickActions = [
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
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fees',
        color: AppColors.goldPrimary,
        onTap: () => context.go(RouteNames.feeDashboard),
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
        onTap: () => context.go(RouteNames.complaints),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exams',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: 'Overview of school performance.',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.space8),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Total Students',
                          value: '--',
                          icon: Icons.school_outlined,
                          iconColor: AppColors.navyMedium,
                          onTap: () => context.go(RouteNames.students),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: StatCard(
                          label: 'Total Teachers',
                          value: '--',
                          icon: Icons.co_present_outlined,
                          iconColor: AppColors.infoBlue,
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
                          value: '--',
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.goldPrimary,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: StatCard(
                          label: 'Open Complaints',
                          value: '--',
                          icon: Icons.feedback_outlined,
                          iconColor: AppColors.errorRed,
                          onTap: () => context.go(RouteNames.complaints),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(actions: quickActions),
                  const SizedBox(height: AppDimensions.space40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}