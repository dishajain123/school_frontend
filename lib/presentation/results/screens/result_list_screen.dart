import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import 'principal_results_distribution_screen.dart';

class ResultListScreen extends ConsumerWidget {
  const ResultListScreen({
    super.key,
    this.studentId,
  });

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser?.role == UserRole.teacher) {
      return const PrincipalResultsDistributionScreen();
    }
    final selectedChild = ref.watch(selectedChildProvider);
    final currentStudentIdAsync = ref.watch(currentStudentIdProvider);
    final activeYear = ref.watch(activeYearProvider);
    final isStudentOrParent = currentUser?.role == UserRole.student ||
        currentUser?.role == UserRole.parent;

    final resolvedStudentId = studentId ??
        (currentUser?.role == UserRole.parent
            ? selectedChild?.id
            : currentStudentIdAsync.valueOrNull);

    if (resolvedStudentId == null || resolvedStudentId.isEmpty) {
      return AppScaffold(
        appBar: AppAppBar(
          title: 'Results',
          showBack: true,
          onBackPressed: currentUser?.role == UserRole.parent
              ? () => context.go(RouteNames.dashboard)
              : null,
        ),
        body: const AppEmptyState(
          icon: Icons.analytics_outlined,
          title: 'Student not selected',
          subtitle: 'Select a student to view results.',
        ),
      );
    }

    final params = (
      studentId: resolvedStudentId,
      academicYearId: isStudentOrParent ? null : activeYear?.id,
      standardId: null,
    );

    final examsAsync = ref.watch(examListProvider(params));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Results',
        showBack: true,
        onBackPressed: currentUser?.role == UserRole.parent
            ? () => context.go(RouteNames.dashboard)
            : null,
      ),
      body: examsAsync.when(
        loading: _buildShimmer,
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(examListProvider(params)),
        ),
        data: (exams) {
          if (exams.isEmpty) {
            return const AppEmptyState(
              icon: Icons.analytics_outlined,
              title: 'No results yet',
              subtitle: 'Uploaded exam results will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(examListProvider(params)),
            color: AppColors.navyDeep,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExamCard(
                    exam: exam,
                    onTap: () => context.push(
                      RouteNames.reportCard,
                      extra: {
                        'studentId': resolvedStudentId,
                        'examId': exam.id,
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 110),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.onTap,
  });

  final ExamModel exam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_outlined,
                  size: 18,
                  color: AppColors.navyDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.name,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _dateRangeLabel(exam),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateRangeLabel(ExamModel exam) {
    final start = DateFormatter.formatDate(exam.startDate);
    final end = DateFormatter.formatDate(exam.endDate);
    return start == end ? start : '$start - $end';
  }
}
