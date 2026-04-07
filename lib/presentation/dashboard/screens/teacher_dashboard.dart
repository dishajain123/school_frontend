import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';
import '../widgets/upcoming_card.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final quickActions = [
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.markAttendance),
      ),
      QuickActionItem(
        icon: Icons.assignment_outlined,
        label: 'Assignment',
        color: AppColors.infoBlue,
        onTap: () => context.go(RouteNames.createAssignment),
      ),
      QuickActionItem(
        icon: Icons.home_work_outlined,
        label: 'Homework',
        color: AppColors.subjectMath,
        onTap: () => context.go(RouteNames.createHomework),
      ),
      QuickActionItem(
        icon: Icons.menu_book_outlined,
        label: 'Diary',
        color: AppColors.warningAmber,
        onTap: () => context.go(RouteNames.createDiary),
      ),
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
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exam',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
      QuickActionItem(
        icon: Icons.campaign_outlined,
        label: 'Announce',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.announcements),
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
                subtitle: 'Have a great teaching day!',
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.space8),
                  AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(actions: quickActions),
                  const SizedBox(height: AppDimensions.space24),
                  AppSectionHeader(
                    title: 'This Week',
                    actionLabel: 'See all',
                    onAction: () => context.go(RouteNames.assignments),
                  ),
                  const SizedBox(height: AppDimensions.space12),
                  UpcomingCard(
                    title: 'Upcoming Deadlines',
                    items: const [],
                    onSeeAll: () => context.go(RouteNames.assignments),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Classes Today',
                          value: '--',
                          icon: Icons.class_outlined,
                          iconColor: AppColors.navyMedium,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: StatCard(
                          label: 'Pending Grading',
                          value: '--',
                          icon: Icons.grading_outlined,
                          iconColor: AppColors.warningAmber,
                        ),
                      ),
                    ],
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
