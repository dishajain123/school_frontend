import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_entry_model.dart';
import '../../../data/models/exam/exam_series_model.dart';
import '../../../providers/academic_year_provider.dart';
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
    final activeYear = ref.watch(activeYearProvider);
    final seriesListAsync = ref.watch(examSeriesListProvider((
      standardId: widget.standardId,
      academicYearId: activeYear?.id,
    )));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Exam Schedule',
        actions: canManage
            ? [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add Series',
                  onPressed: () async {
                    await context.push<void>(
                      RouteNames.createExamSeries,
                      extra: {'standard_id': widget.standardId},
                    );
                    if (!mounted) return;
                    ref.invalidate(examSeriesListProvider((
                      standardId: widget.standardId,
                      academicYearId: activeYear?.id,
                    )));
                  },
                ),
              ]
            : const [],
      ),
      body: seriesListAsync.when(
        loading: () => const _ScheduleLoading(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(examSeriesListProvider((
            standardId: widget.standardId,
            academicYearId: activeYear?.id,
          ))),
        ),
        data: (seriesList) {
          if (_selectedSeriesId == null && widget.seriesId != null) {
            _selectedSeriesId = widget.seriesId;
          }
          if (_selectedSeriesId == null && seriesList.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedSeriesId = seriesList.first.id);
            });
          }

          if (seriesList.isEmpty) {
            return AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No exam series yet',
              subtitle: canManage
                  ? 'Create a series, then add exam entries or upload a timetable file.'
                  : 'Exam schedule has not been published yet for this class.',
            );
          }

          final selected = seriesList.where((s) => s.id == _selectedSeriesId);
          final selectedSeries =
              selected.isNotEmpty ? selected.first : seriesList.first;
          if (_selectedSeriesId != selectedSeries.id) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _selectedSeriesId = selectedSeries.id);
            });
          }

          return Column(
            children: [
              _SeriesSelectorBar(
                seriesList: seriesList,
                selectedSeriesId: selectedSeries.id,
                onChanged: (id) => setState(() => _selectedSeriesId = id),
              ),
              Expanded(
                child: _buildScheduleContent(
                  canManage,
                  selectedSeries.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleContent(bool canManage, String selectedSeriesId) {
    final scheduleAsync = ref.watch(examScheduleProvider((
      standardId: widget.standardId,
      seriesId: selectedSeriesId,
    )));

    return scheduleAsync.when(
      data: (schedule) {
        _cachedSchedule = schedule;
        return _ScheduleBody(
          schedule: schedule,
          canManage: canManage,
          standardId: widget.standardId,
          onPublish: () => _handlePublish(schedule.series),
          onCancelEntry: (entry) => _handleCancelEntry(entry),
          isPublishing: _isPublishing,
        );
      },
      loading: () => _cachedSchedule != null
          ? _ScheduleBody(
              schedule: _cachedSchedule!,
              canManage: canManage,
              standardId: widget.standardId,
              onPublish: () => _handlePublish(_cachedSchedule!.series),
              onCancelEntry: (entry) => _handleCancelEntry(entry),
              isPublishing: _isPublishing,
            )
          : const _ScheduleLoading(),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(examScheduleProvider((
          standardId: widget.standardId,
          seriesId: selectedSeriesId,
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
        seriesId: series.id,
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
        seriesId: entry.seriesId,
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
    required this.standardId,
    required this.onPublish,
    required this.onCancelEntry,
    required this.isPublishing,
  });

  final ExamScheduleTable schedule;
  final bool canManage;
  final String standardId;
  final VoidCallback onPublish;
  final ValueChanged<ExamEntryModel> onCancelEntry;
  final bool isPublishing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync =
        ref.watch(subjectsProvider(schedule.series.standardId));

    final subjectMap = subjectsAsync.asData?.value.fold<Map<String, String>>(
          {},
          (map, s) => map..putIfAbsent(s.id, () => s.name),
        ) ??
        {};

    final entries = schedule.entries;
    // Sort by date then start time
    final sorted = [...entries]..sort((a, b) {
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
              child: Column(
                children: [
                  SeriesHeader(
                    series: schedule.series,
                    entryCount: entries.length,
                    canPublish: canManage,
                    onPublish: isPublishing ? null : onPublish,
                  ),
                  if (canManage) ...[
                    const SizedBox(height: AppDimensions.space12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          '${RouteNames.uploadTimetable}?standard_id=$standardId&exam_mode=true',
                        ),
                        icon: const Icon(Icons.upload_file_outlined, size: 18),
                        label: const Text('Upload PDF/DOC Schedule'),
                      ),
                    ),
                  ],
                ],
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

class _SeriesSelectorBar extends StatelessWidget {
  const _SeriesSelectorBar({
    required this.seriesList,
    required this.selectedSeriesId,
    required this.onChanged,
  });

  final List<ExamSeriesModel> seriesList;
  final String selectedSeriesId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        AppDimensions.space8,
      ),
      child: DropdownButtonFormField<String>(
        value: selectedSeriesId,
        decoration: const InputDecoration(
          labelText: 'Exam Series',
          prefixIcon: Icon(Icons.event_note_outlined),
        ),
        items: seriesList
            .map(
              (series) => DropdownMenuItem<String>(
                value: series.id,
                child: Text(series.name),
              ),
            )
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          onChanged(value);
        },
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
          ...List.generate(
              4,
              (_) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: AppDimensions.space8),
                    child: AppLoading.listTile(),
                  )),
        ],
      ),
    );
  }
}
