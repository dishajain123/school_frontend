import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  ConsumerState<SubmissionListScreen> createState() => _SubmissionListScreenState();
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
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(submissionsProvider(widget.assignmentId).notifier).loadMore();
    }
  }

  Future<void> _openSubmissionFile(String url) async {
    final lower = url.toLowerCase();
    final isPdf = lower.contains('.pdf');
    final isImage = lower.contains('.png') || lower.contains('.jpg') ||
        lower.contains('.jpeg') || lower.contains('.webp');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: isPdf
                  ? SfPdfViewer.network(url)
                  : isImage
                      ? InteractiveViewer(child: Center(child: Image.network(url)))
                      : Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Preview not available for this file type.',
                                  style: AppTypography.titleMedium),
                              const SizedBox(height: 12),
                              SelectableText(url),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () async {
                                  await Clipboard.setData(ClipboardData(text: url));
                                  if (!ctx.mounted) return;
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(content: Text('File URL copied')),
                                  );
                                },
                                child: const Text('Copy File URL'),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(submissionsProvider(widget.assignmentId));
    final assignmentAsync = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final assignmentTitle = assignmentAsync.valueOrNull?.title ?? 'Submissions';

    return AppScaffold(
      appBar: AppAppBar(title: assignmentTitle, showBack: true),
      body: submissionsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(submissionsProvider(widget.assignmentId).notifier).refresh(),
        ),
        data: (state) {
          final sections = state.items
              .map((e) => e.studentSection)
              .whereType<String>()
              .where((e) => e.trim().isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          return Column(
            children: [
              _StatsHeader(
                total: state.total,
                graded: state.items.where((s) => s.isGraded).length,
                ungraded: state.items.where((s) => !s.isGraded).length,
                late: state.items.where((s) => s.isLate).length,
              ),
              if (sections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.surface200, width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: state.sectionFilter,
                        isExpanded: true,
                        hint: Text('Filter by section',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.grey400),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All Sections')),
                          ...sections.map((s) => DropdownMenuItem<String?>(
                                value: s, child: Text('Section $s'),
                              )),
                        ],
                        onChanged: (value) => ref
                            .read(submissionsProvider(widget.assignmentId).notifier)
                            .applySectionFilter(value),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: state.items.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No submissions yet',
                        subtitle: 'Students have not submitted this assignment yet.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => ref
                            .read(submissionsProvider(widget.assignmentId).notifier)
                            .refresh(),
                        color: AppColors.navyDeep,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.navyDeep)),
                              );
                            }
                            final submission = state.items[index];
                            final isLast = index == state.items.length - 1;
                            final studentLabel = submission.studentName ??
                                submission.studentAdmissionNumber ??
                                submission.studentRollNumber ??
                                'Student ${submission.studentId.substring(0, 8)}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: AppCard(
                                padding: EdgeInsets.zero,
                                child: SubmissionTile(
                                  submission: submission,
                                  studentName: studentLabel,
                                  standardName: submission.standardName,
                                  subjectName: submission.subjectName,
                                  section: submission.studentSection,
                                  isLast: isLast,
                                  onGrade: () async {
                                    await GradeBottomSheet.show(
                                      context,
                                      submissionId: submission.id,
                                      assignmentId: widget.assignmentId,
                                      studentName: studentLabel,
                                      existingGrade: submission.grade,
                                      existingFeedback: submission.feedback,
                                      existingApproved: submission.isApproved,
                                    );
                                  },
                                  onViewFile: submission.fileUrl != null
                                      ? () => _openSubmissionFile(submission.fileUrl!)
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
          margin: const EdgeInsets.all(16),
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (_, __) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppLoading.card(height: 100),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({
    required this.total,
    required this.graded,
    required this.ungraded,
    required this.late,
  });

  final int total, graded, ungraded, late;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatItem(value: total.toString(), label: 'Total', color: AppColors.white),
          _VerticalDivider(),
          _StatItem(value: graded.toString(), label: 'Graded', color: AppColors.successGreen),
          _VerticalDivider(),
          _StatItem(value: ungraded.toString(), label: 'Pending', color: AppColors.warningAmber),
          _VerticalDivider(),
          _StatItem(value: late.toString(), label: 'Late', color: AppColors.errorRed),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTypography.headlineMedium.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 24)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.55), fontSize: 11)),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.white.withValues(alpha: 0.12),
    );
  }
}