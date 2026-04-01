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
import '../widgets/upcoming_card.dart';
import '../widgets/fee_due_banner.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quickActions = [
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
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {},
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: 'Keep up the great work!',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.space8),
                  FeeDueBanner(
                    amountDue: 0,
                    onTap: () => context.go(RouteNames.feeDashboard),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(actions: quickActions),
                  const SizedBox(height: AppDimensions.space24),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Attendance',
                          value: '--%',
                          icon: Icons.fact_check_outlined,
                          iconColor: AppColors.successGreen,
                          onTap: () => context.go(RouteNames.attendance),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: StatCard(
                          label: 'Assignments',
                          value: '--',
                          icon: Icons.assignment_outlined,
                          iconColor: AppColors.infoBlue,
                          onTap: () => context.go(RouteNames.assignments),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  AppSectionHeader(
                    title: 'Upcoming',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.assignments),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  UpcomingCard(
                    title: 'Upcoming Assignments',
                    items: const [],
                    onSeeAll: () => context.go(RouteNames.assignments),
                  ),
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