import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers/submission_provider.dart';
import '../../../providers/assignment_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_card.dart';
import '../widgets/submission_tile.dart';
import '../widgets/grade_bottom_sheet.dart';

class SubmissionListScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const SubmissionListScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<SubmissionListScreen> createState() =>
      _SubmissionListScreenState();
}

class _SubmissionListScreenState extends ConsumerState<SubmissionListScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(submissionsProvider(widget.assignmentId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync =
        ref.watch(submissionsProvider(widget.assignmentId));
    final assignmentAsync =
        ref.watch(assignmentDetailProvider(widget.assignmentId));

    final assignmentTitle =
        assignmentAsync.valueOrNull?.title ?? 'Submissions';

    return AppScaffold(
      appBar: AppAppBar(
        title: assignmentTitle,
        showBack: true,
      ),
      body: submissionsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref
              .read(submissionsProvider(widget.assignmentId).notifier)
              .refresh(),
        ),
        data: (state) {
          return Column(
            children: [
              // ── Stats header ─────────────────────────────────────────
              _StatsHeader(
                total: state.total,
                graded:
                    state.items.where((s) => s.isGraded).length,
                ungraded:
                    state.items.where((s) => !s.isGraded).length,
                late: state.items.where((s) => s.isLate).length,
              ),

              // ── Submission list ──────────────────────────────────────
              Expanded(
                child: state.items.isEmpty
                    ? AppEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No submissions yet',
                        subtitle:
                            'Students have not submitted this assignment yet.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(submissionsProvider(widget.assignmentId)
                                .notifier)
                            .refresh(),
                        color: AppColors.navyDeep,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.space8),
                          itemCount: state.items.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.items.length) {
                              return const Padding(
                                padding:
                                    EdgeInsets.all(AppDimensions.space16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.navyDeep),
                                ),
                              );
                            }

                            final submission = state.items[index];
                            final isLast =
                                index == state.items.length - 1;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.space16,
                                  vertical: AppDimensions.space4),
                              child: AppCard(
                                padding: EdgeInsets.zero,
                                child: SubmissionTile(
                                  submission: submission,
                                  // In a real app, resolve student name from
                                  // student provider using submission.studentId
                                  studentName:
                                      'Student ${submission.studentId.substring(0, 8)}',
                                  isLast: isLast,
                                  onGrade: () async {
                                    final graded =
                                        await GradeBottomSheet.show(
                                      context,
                                      submissionId: submission.id,
                                      assignmentId: widget.assignmentId,
                                      studentName:
                                          'Student ${submission.studentId.substring(0, 8)}',
                                      existingGrade: submission.grade,
                                      existingFeedback: submission.feedback,
                                    );
                                    // Provider is updated inside GradeBottomSheet
                                  },
                                  onViewFile: submission.fileUrl != null
                                      ? () {
                                          // Open presigned URL
                                        }
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(AppDimensions.space16),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space4),
              child: AppLoading.card(),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Stats header widget ───────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  final int total;
  final int graded;
  final int ungraded;
  final int late;

  const _StatsHeader({
    required this.total,
    required this.graded,
    required this.ungraded,
    required this.late,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.space16),
      padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.space16,
          horizontal: AppDimensions.space20),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Row(
        children: [
          _StatItem(
              value: total.toString(),
              label: 'Total',
              color: AppColors.white),
          _Divider(),
          _StatItem(
              value: graded.toString(),
              label: 'Graded',
              color: AppColors.successGreen),
          _Divider(),
          _StatItem(
              value: ungraded.toString(),
              label: 'Pending',
              color: AppColors.warningAmber),
          _Divider(),
          _StatItem(
              value: late.toString(),
              label: 'Late',
              color: AppColors.errorRed),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.headlineMedium.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelMedium
                .copyWith(color: AppColors.white.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppColors.white.withOpacity(0.15),
    );
  }
}