import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../data/models/exam/exam_series_model.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../providers/exam_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';
import '../../../core/utils/snackbar_utils.dart';

class CreateSeriesScreen extends ConsumerStatefulWidget {
  const CreateSeriesScreen({
    super.key,
    required this.standardId,
    this.initialStandardName,
  });

  final String standardId;
  final String? initialStandardName;

  @override
  ConsumerState<CreateSeriesScreen> createState() => _CreateSeriesScreenState();
}

class _CreateSeriesScreenState extends ConsumerState<CreateSeriesScreen>
    with SingleTickerProviderStateMixin {
  // Step 1: Create series
  final _seriesNameController = TextEditingController();
  String? _selectedAcademicYearId;
  String? _selectedExamId;
  String? _selectedExamName;
  ExamSeriesModel? _createdSeries;

  // Step 2: Add entries
  final List<_EntryDraft> _entries = [];

  int _step = 1; // 1 = create series, 2 = add entries

  @override
  void dispose() {
    _seriesNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: _step == 1 ? 'Create Exam Series' : 'Add Exam Entries',
        showBack: true,
        onBackPressed: () {
          if (_step == 2) {
            setState(() => _step = 1);
            return;
          }
          context.pop();
        },
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
        child: _step == 1
            ? _StepOneSeries(
                key: const ValueKey('step1'),
                nameController: _seriesNameController,
                standardId: widget.standardId,
                selectedAcademicYearId: _selectedAcademicYearId,
                onAcademicYearSelected: (id) =>
                    setState(() => _selectedAcademicYearId = id),
                selectedExamId: _selectedExamId,
                onExamSelected: (exam) => setState(() {
                  _selectedExamId = exam.id;
                  _selectedExamName = exam.name;
                }),
                onNext: _handleCreateSeries,
              )
            : _StepTwoEntries(
                key: const ValueKey('step2'),
                series: _createdSeries!,
                standardId: widget.standardId,
                entries: _entries,
                onAddEntry: _handleAddEntry,
                onDone: _handleDone,
              ),
      ),
    );
  }

  Future<void> _handleCreateSeries() async {
    final name = _seriesNameController.text.trim();
    if (_selectedExamId == null || _selectedExamId!.trim().isEmpty) {
      SnackbarUtils.showError(context, 'Please select an exam');
      return;
    }
    final seriesName = name.isEmpty
        ? (_selectedExamName ?? 'Exam Schedule')
        : name;

    final series =
        await ref.read(examSeriesNotifierProvider.notifier).createSeries(
              name: seriesName,
              examId: _selectedExamId!,
              section: null,
            );

    if (!mounted) return;

    if (series != null) {
      setState(() {
        _createdSeries = series;
        _step = 2;
      });
      SnackbarUtils.showSuccess(
          context, 'Series created! Now add exam entries.');
    } else {
      final err = ref.read(examSeriesNotifierProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to create series');
    }
  }

  Future<void> _handleAddEntry(_EntryDraft draft) async {
    final entry = await ref.read(examEntryNotifierProvider.notifier).addEntry(
          seriesId: _createdSeries!.id,
          subjectId: draft.subjectId,
          examDate: DateFormat('yyyy-MM-dd').format(draft.examDate),
          startTime: draft.startTime,
          durationMinutes: draft.durationMinutes,
          venue: draft.venue,
        );

    if (!mounted) return;

    if (entry != null) {
      setState(() => _entries.add(draft));
      SnackbarUtils.showSuccess(context, 'Entry added');
    } else {
      final err = ref.read(examEntryNotifierProvider).error;
      SnackbarUtils.showError(context, err ?? 'Failed to add entry');
    }
  }

  void _handleDone() {
    context.pop();
  }
}

// ── Step 1: Create series form ────────────────────────────────────────────────

class _StepOneSeries extends ConsumerWidget {
  const _StepOneSeries({
    super.key,
    required this.nameController,
    required this.standardId,
    required this.selectedAcademicYearId,
    required this.onAcademicYearSelected,
    required this.selectedExamId,
    required this.onExamSelected,
    required this.onNext,
  });

  final TextEditingController nameController;
  final String standardId;
  final String? selectedAcademicYearId;
  final ValueChanged<String> onAcademicYearSelected;
  final String? selectedExamId;
  final ValueChanged<ExamModel> onExamSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final yearsAsync = ref.watch(academicYearNotifierProvider);
    final examsAsync = ref.watch(
      examListProvider((
        studentId: null,
        academicYearId: selectedAcademicYearId,
        standardId: standardId,
      )),
    );
    final isLoading =
        ref.watch(examSeriesNotifierProvider.select((s) => s.isLoading));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(current: 1, total: 2),
          const SizedBox(height: AppDimensions.space24),
          Text(
            'Series Details',
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Give this exam series a name (e.g. "Term 1 Exams 2025")',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppDimensions.space24),
          AppTextField(
            controller: nameController,
            label: 'Series Name (optional)',
            hint: 'e.g. Class 6-A',
          ),
          const SizedBox(height: AppDimensions.space20),
          Text(
            'Exam',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          examsAsync.when(
            data: (exams) => DropdownButtonFormField<String>(
              value: selectedExamId,
              hint: const Text('Select exam'),
              decoration: const InputDecoration(),
              items: exams
                  .map((exam) => DropdownMenuItem<String>(
                        value: exam.id,
                        child: Text(exam.name),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                for (final exam in exams) {
                  if (exam.id == value) {
                    onExamSelected(exam);
                    break;
                  }
                }
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(
              'Failed to load exams',
              style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
            ),
          ),
          const SizedBox(height: AppDimensions.space20),
          // Academic year selector
          Text(
            'Academic Year (optional)',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: AppDimensions.space8),
          yearsAsync.when(
            data: (years) => _AcademicYearDropdown(
              years:
                  years.map((y) => _YearItem(id: y.id, name: y.name)).toList(),
              selectedId: selectedAcademicYearId,
              onChanged: onAcademicYearSelected,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(
              'Failed to load academic years',
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
            ),
          ),
          const SizedBox(height: AppDimensions.space32),
          AppButton.primary(
            label: 'Create Series & Continue',
            onTap: onNext,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

class _YearItem {
  const _YearItem({required this.id, required this.name});
  final String id;
  final String name;
}

class _AcademicYearDropdown extends StatelessWidget {
  const _AcademicYearDropdown({
    required this.years,
    required this.selectedId,
    required this.onChanged,
  });

  final List<_YearItem> years;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedId,
      hint: const Text('Select academic year'),
      decoration: const InputDecoration(),
      items: years
          .map((y) => DropdownMenuItem(value: y.id, child: Text(y.name)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// ── Step 2: Add entries ───────────────────────────────────────────────────────

class _EntryDraft {
  const _EntryDraft({
    required this.subjectId,
    required this.subjectName,
    required this.examDate,
    required this.startTime,
    required this.durationMinutes,
    this.venue,
  });

  final String subjectId;
  final String subjectName;
  final DateTime examDate;
  final String startTime;
  final int durationMinutes;
  final String? venue;
}

class _StepTwoEntries extends ConsumerStatefulWidget {
  const _StepTwoEntries({
    super.key,
    required this.series,
    required this.standardId,
    required this.entries,
    required this.onAddEntry,
    required this.onDone,
  });

  final ExamSeriesModel series;
  final String standardId;
  final List<_EntryDraft> entries;
  final Future<void> Function(_EntryDraft) onAddEntry;
  final VoidCallback onDone;

  @override
  ConsumerState<_StepTwoEntries> createState() => _StepTwoEntriesState();
}

class _StepTwoEntriesState extends ConsumerState<_StepTwoEntries> {
  String? _selectedSubjectId;
  String? _selectedSubjectName;
  DateTime? _examDate;
  TimeOfDay? _startTime;
  final _durationController = TextEditingController(text: '60');
  final _venueController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _durationController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _addEntry(List<SubjectModel> subjects) async {
    if (_selectedSubjectId == null ||
        _examDate == null ||
        _startTime == null ||
        _durationController.text.isEmpty) {
      SnackbarUtils.showError(context, 'Please fill all required fields');
      return;
    }
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration <= 0) {
      SnackbarUtils.showError(context, 'Duration must be positive');
      return;
    }
    final h = _startTime!.hour.toString().padLeft(2, '0');
    final m = _startTime!.minute.toString().padLeft(2, '0');
    final startTimeStr = '$h:$m:00';
    final venue = _venueController.text.trim();

    setState(() => _isAdding = true);
    await widget.onAddEntry(_EntryDraft(
      subjectId: _selectedSubjectId!,
      subjectName: _selectedSubjectName ?? '',
      examDate: _examDate!,
      startTime: startTimeStr,
      durationMinutes: duration,
      venue: venue.isEmpty ? null : venue,
    ));
    setState(() {
      _isAdding = false;
      _selectedSubjectId = null;
      _selectedSubjectName = null;
      _examDate = null;
      _startTime = null;
      _venueController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = ref.watch(subjectsProvider(widget.standardId));

    return Column(
      children: [
        // Added entries summary
        if (widget.entries.isNotEmpty) _EntryChips(entries: widget.entries),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepIndicator(current: 2, total: 2),
                const SizedBox(height: AppDimensions.space20),
                Text(
                  'Add Exam Entries',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  'Series: ${widget.series.name}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.navyDeep,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDimensions.space20),
                // Subject
                subjectsAsync.when(
                  data: (subjects) => DropdownButtonFormField<String>(
                    value: _selectedSubjectId,
                    hint: const Text('Select Subject *'),
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: subjects
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      final subject = subjects.firstWhere((s) => s.id == v);
                      setState(() {
                        _selectedSubjectId = v;
                        _selectedSubjectName = subject.name;
                      });
                    },
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text('Failed to load subjects',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.errorRed)),
                ),
                const SizedBox(height: AppDimensions.space16),
                // Exam date
                InkWell(
                  onTap: _pickDate,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Exam Date *',
                      suffixIcon: Icon(Icons.calendar_today_outlined, size: 18),
                    ),
                    child: Text(
                      _examDate != null
                          ? DateFormat('EEE, dd MMM yyyy').format(_examDate!)
                          : 'Tap to select',
                      style: _examDate != null
                          ? AppTypography.bodyMedium
                          : AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey600),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                // Start time
                InkWell(
                  onTap: _pickTime,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time *',
                      suffixIcon: Icon(Icons.access_time_outlined, size: 18),
                    ),
                    child: Text(
                      _startTime != null
                          ? _startTime!.format(context)
                          : 'Tap to select',
                      style: _startTime != null
                          ? AppTypography.bodyMedium
                          : AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey600),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.space16),
                // Duration
                AppTextField(
                  controller: _durationController,
                  label: 'Duration (minutes) *',
                  hint: '60',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimensions.space16),
                // Venue (optional)
                AppTextField(
                  controller: _venueController,
                  label: 'Venue (optional)',
                  hint: 'e.g. Hall A',
                ),
                const SizedBox(height: AppDimensions.space24),
                subjectsAsync.when(
                  data: (subjects) => AppButton.secondary(
                    label: '+ Add Entry',
                    onTap: () => _addEntry(subjects),
                    isLoading: _isAdding,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        // Done button
        Padding(
          padding: const EdgeInsets.all(AppDimensions.space16),
          child: AppButton.primary(
            label: widget.entries.isEmpty
                ? 'Skip & Finish'
                : 'Done (${widget.entries.length} entries added)',
            onTap: widget.onDone,
          ),
        ),
      ],
    );
  }
}

class _EntryChips extends StatelessWidget {
  const _EntryChips({required this.entries});
  final List<_EntryDraft> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      color: AppColors.successGreen.withOpacity(0.08),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline,
              color: AppColors.successGreen, size: 16),
          const SizedBox(width: 6),
          Text(
            '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'} added',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.successGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final step = i + 1;
        final isActive = step == current;
        final isDone = step < current;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDone || isActive
                        ? AppColors.navyDeep
                        : AppColors.surface200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (step < total) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }
}
