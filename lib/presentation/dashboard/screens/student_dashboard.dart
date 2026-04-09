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
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';
import '../widgets/upcoming_card.dart';
import '../widgets/fee_due_banner.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meAsync = ref.watch(myStudentProfileProvider);

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
        onRefresh: () async {
          ref.invalidate(myStudentProfileProvider);
          ref.invalidate(classTeachersProvider);
        },
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
                  _StudentClassTeachersCard(meAsync: meAsync),
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

class _StudentClassTeachersCard extends ConsumerWidget {
  const _StudentClassTeachersCard({required this.meAsync});

  final AsyncValue<StudentModel> meAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return meAsync.when(
      loading: () => _ClassTeachersCardShell(
        child: Text(
          'Loading class details...',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
        ),
      ),
      error: (e, _) => _ClassTeachersCardShell(
        child: Text(
          'Could not load class details: $e',
          style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
        ),
      ),
      data: (me) {
        final standardId = me.standardId;
        final section = me.section?.trim();
        final yearId = me.academicYearId;

        if (standardId == null || standardId.isEmpty) {
          return _ClassTeachersCardShell(
            child: Text(
              'Class not assigned yet.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          );
        }

        final hasSection = section != null && section.isNotEmpty;
        final classLabel = hasSection ? 'Section $section' : 'Section not set';

        if (!hasSection) {
          return _ClassTeachersCardShell(
            sectionLabel: classLabel,
            child: Text(
              'Teachers will appear once section is assigned.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          );
        }

        final teachersAsync = ref.watch(classTeachersProvider((
          standardId: standardId,
          section: section,
          academicYearId: yearId,
        )));

        return _ClassTeachersCardShell(
          sectionLabel: classLabel,
          child: teachersAsync.when(
            loading: () => Text(
              'Loading assigned teachers...',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
            error: (e, _) => Text(
              'Could not load teachers: $e',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
            ),
            data: (rows) => _TeachersList(rows: rows),
          ),
        );
      },
    );
  }
}

class _ClassTeachersCardShell extends StatelessWidget {
  const _ClassTeachersCardShell({
    required this.child,
    this.sectionLabel,
  });

  final String? sectionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Class Teachers',
            style: AppTypography.titleSmall.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (sectionLabel != null) ...[
            const SizedBox(height: AppDimensions.space4),
            Text(
              sectionLabel!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ],
          const SizedBox(height: AppDimensions.space8),
          child,
        ],
      ),
    );
  }
}

class _TeachersList extends StatelessWidget {
  const _TeachersList({required this.rows});

  final List<TeacherClassSubjectModel> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text(
        'No teacher assignments found for this class/section.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
      );
    }

    final byTeacher = <String, List<TeacherClassSubjectModel>>{};
    for (final r in rows) {
      final code = r.teacherEmployeeCode ?? 'Teacher';
      final key = '${r.teacherId}|$code';
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
        final subjects = teacherRows.map((r) => r.subjectLabel).toSet().toList()
          ..sort();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.space8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_outline,
                  size: 18, color: AppColors.navyMedium),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  '$teacherCode: ${subjects.join(', ')}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.grey800),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
