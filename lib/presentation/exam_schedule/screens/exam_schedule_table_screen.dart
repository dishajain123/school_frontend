import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_entry_model.dart';
import '../../../data/models/exam/exam_series_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exam_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_dialog.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../widgets/series_header.dart';
import '../widgets/exam_entry_tile.dart';

class ExamScheduleTableScreen extends ConsumerStatefulWidget {
  const ExamScheduleTableScreen({
    super.key,
    required this.standardId,
    this.seriesId,
  });

  final String standardId;
  final String? seriesId;

  @override
  ConsumerState<ExamScheduleTableScreen> createState() =>
      _ExamScheduleTableScreenState();
}

class _ExamScheduleTableScreenState
    extends ConsumerState<ExamScheduleTableScreen> {
  String? _selectedSeriesId;
  ExamScheduleTable? _cachedSchedule;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _selectedSeriesId = widget.seriesId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final canManage =
        currentUser?.hasPermission('exam_schedule:create') ?? false;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Exam Schedule',
        actions: canManage
            ? [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Series',
                  onPressed: () => context.push(
                    RouteNames.createExamSeries,
                    extra: {'standard_id': widget.standardId},
                  ),
                ),
              ]
            : const [],
      ),
      body: _selectedSeriesId == null
          ? _SeriesIdPrompt(
              onSeriesIdEntered: (id) =>
                  setState(() => _selectedSeriesId = id),
            )
          : _buildScheduleContent(canManage),
    );
  }

  Widget _buildScheduleContent(bool canManage) {
    final scheduleAsync = ref.watch(examScheduleProvider((
      standardId: widget.standardId,
      seriesId: _selectedSeriesId!,
    )));

    return scheduleAsync.when(
      data: (schedule) {
        _cachedSchedule = schedule;
        return _ScheduleBody(
          schedule: schedule,
          canManage: canManage,
          onPublish: () => _handlePublish(schedule.series),
          onCancelEntry: (entry) => _handleCancelEntry(entry),
          isPublishing: _isPublishing,
        );
      },
      loading: () => _cachedSchedule != null
          ? _ScheduleBody(
              schedule: _cachedSchedule!,
              canManage: canManage,
              onPublish: () => _handlePublish(_cachedSchedule!.series),
              onCancelEntry: (entry) => _handleCancelEntry(entry),
              isPublishing: _isPublishing,
            )
          : const _ScheduleLoading(),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(examScheduleProvider((
          standardId: widget.standardId,
          seriesId: _selectedSeriesId!,
        ))),
      ),
    );
  }

  Future<void> _handlePublish(ExamSeriesModel series) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Publish Exam Schedule',
      message:
          'Publishing will make this schedule visible to all students and parents. This action cannot be undone.',
      confirmLabel: 'Publish',
    );

    if (confirmed != true) return;

    setState(() => _isPublishing = true);
    final updated =
        await ref.read(examSeriesNotifierProvider.notifier).publishSeries(
              series.id,
            );
    setState(() => _isPublishing = false);

    if (!mounted) return;
    if (updated != null) {
      SnackbarUtils.showSuccess(context, 'Exam schedule published!');
      ref.invalidate(examScheduleProvider((
        standardId: widget.standardId,
        seriesId: _selectedSeriesId!,
      )));
    } else {
      final err = ref.read(examSeriesNotifierProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to publish');
    }
  }

  Future<void> _handleCancelEntry(ExamEntryModel entry) async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Cancel Exam Entry',
      message:
          'Cancel the ${entry.formattedStartTime} exam on this date? Students will be notified.',
      confirmLabel: 'Cancel Entry',
    );

    if (confirmed != true) return;

    final cancelled =
        await ref.read(examEntryNotifierProvider.notifier).cancelEntry(
              entry.id,
            );

    if (!mounted) return;
    if (cancelled != null) {
      SnackbarUtils.showSuccess(context, 'Entry cancelled');
      ref.invalidate(examScheduleProvider((
        standardId: widget.standardId,
        seriesId: _selectedSeriesId!,
      )));
    } else {
      final err = ref.read(examEntryNotifierProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to cancel entry');
    }
  }
}

// ── Schedule body ─────────────────────────────────────────────────────────────

class _ScheduleBody extends ConsumerWidget {
  const _ScheduleBody({
    required this.schedule,
    required this.canManage,
    required this.onPublish,
    required this.onCancelEntry,
    required this.isPublishing,
  });

  final ExamScheduleTable schedule;
  final bool canManage;
  final VoidCallback onPublish;
  final ValueChanged<ExamEntryModel> onCancelEntry;
  final bool isPublishing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync =
        ref.watch(subjectsProvider(schedule.series.standardId));

    final subjectMap = subjectsAsync.asData?.value
            .fold<Map<String, String>>(
              {},
              (map, s) => map..putIfAbsent(s.id, () => s.name),
            ) ??
        {};

    final entries = schedule.entries;
    // Sort by date then start time
    final sorted = [...entries]
      ..sort((a, b) {
        final dateCmp = a.examDate.compareTo(b.examDate);
        if (dateCmp != 0) return dateCmp;
        return a.startTime.compareTo(b.startTime);
      });

    return RefreshIndicator(
      onRefresh: () async {
        // Pull-to-refresh: parent will rebuild via ref.invalidate
      },
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            sliver: SliverToBoxAdapter(
              child: SeriesHeader(
                series: schedule.series,
                entryCount: entries.length,
                canPublish: canManage,
                onPublish: isPublishing ? null : onPublish,
              ),
            ),
          ),
          if (isPublishing)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(),
            ),
          if (sorted.isEmpty)
            SliverFillRemaining(
              child: AppEmptyState(
                icon: Icons.event_note_outlined,
                title: 'No Exam Entries',
                subtitle: canManage
                    ? 'Add exam entries to build the schedule'
                    : 'No exams scheduled yet',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                0,
                AppDimensions.space16,
                AppDimensions.space32,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = sorted[index];
                    final subjectName =
                        subjectMap[entry.subjectId] ?? 'Unknown Subject';
                    return ExamEntryTile(
                      entry: entry,
                      subjectName: subjectName,
                      canCancel: canManage && !entry.isCancelled,
                      onCancel: () => onCancelEntry(entry),
                      isLast: index == sorted.length - 1,
                    );
                  },
                  childCount: sorted.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Series ID prompt (when navigated without a seriesId) ──────────────────────

class _SeriesIdPrompt extends StatefulWidget {
  const _SeriesIdPrompt({required this.onSeriesIdEntered});
  final ValueChanged<String> onSeriesIdEntered;

  @override
  State<_SeriesIdPrompt> createState() => _SeriesIdPromptState();
}

class _SeriesIdPromptState extends State<_SeriesIdPrompt> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppColors.navyDeep.withOpacity(0.4)),
          const SizedBox(height: AppDimensions.space16),
          Text(
            'Enter Series ID',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Enter the exam series ID to view its schedule',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.space24),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Exam series UUID',
              prefixIcon: Icon(Icons.tag_outlined),
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final id = _controller.text.trim();
                if (id.isNotEmpty) widget.onSeriesIdEntered(id);
              },
              child: const Text('View Schedule'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer loading ───────────────────────────────────────────────────────────

class _ScheduleLoading extends StatelessWidget {
  const _ScheduleLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        children: [
          AppLoading.card(),
          const SizedBox(height: AppDimensions.space12),
          ...List.generate(4, (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppDimensions.space8),
                child: AppLoading.listTile(),
              )),
        ],
      ),
    );
  }
}
