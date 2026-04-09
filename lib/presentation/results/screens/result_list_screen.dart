import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/result_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/grade_badge.dart';
import '../widgets/result_subject_tile.dart';

typedef _StudentsByFilterParams = ({
  String? standardId,
  String? section,
});

final _studentsByFilterProvider =
    FutureProvider.family<List<StudentModel>, _StudentsByFilterParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final rows = <StudentModel>[];
    var page = 1;
    var totalPages = 1;

    while (page <= totalPages) {
      final result = await repo.list(
        standardId: params.standardId,
        section: params.section,
        page: page,
        pageSize: 100,
      );
      rows.addAll(result.items);
      totalPages = result.totalPages;
      if (result.items.isEmpty) break;
      page += 1;
    }
    return rows;
  },
);

final _myStudentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null || user.role != UserRole.student) return null;

  final repo = ref.read(studentRepositoryProvider);
  try {
    final me = await repo.getMyProfile();
    return me.id;
  } catch (_) {
    final result = await repo.list(page: 1, pageSize: 1);
    return result.items.isNotEmpty ? result.items.first.id : null;
  }
});

class ResultListScreen extends ConsumerStatefulWidget {
  const ResultListScreen({super.key, this.studentId});

  /// When null, resolved from current user/selected child.
  final String? studentId;

  @override
  ConsumerState<ResultListScreen> createState() => _ResultListScreenState();
}

class _ResultListScreenState extends ConsumerState<ResultListScreen> {
  ExamModel? _selectedExam;
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final myStudentIdAsync = ref.watch(_myStudentIdProvider);
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final canCreate = user?.hasPermission('result:create') ?? false;
    final canPublish = user?.hasPermission('result:publish') ?? false;
    final canBrowseStudents = user != null &&
        (user.role == UserRole.principal ||
            user.role == UserRole.trustee ||
            user.role == UserRole.teacher ||
            user.role == UserRole.superadmin);

    String? resolvedStudentId;
    if (widget.studentId != null) {
      resolvedStudentId = widget.studentId;
    } else if (user?.role == UserRole.student) {
      resolvedStudentId = myStudentIdAsync.valueOrNull;
    } else if (user?.role == UserRole.parent) {
      resolvedStudentId = selectedChildId;
    } else {
      resolvedStudentId = _selectedStudentId;
    }

    if (user?.role == UserRole.student && myStudentIdAsync.isLoading) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Results', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user?.role == UserRole.student && myStudentIdAsync.hasError) {
      return AppScaffold(
        appBar: const AppAppBar(title: 'Results', showBack: true),
        body: AppErrorState(
          message: myStudentIdAsync.error.toString(),
          onRetry: () => ref.invalidate(_myStudentIdProvider),
        ),
      );
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Results',
        showBack: true,
        actions: [
          if (canPublish)
            IconButton(
              icon:
                  const Icon(Icons.add_circle_outline, color: AppColors.white),
              tooltip: 'Create Exam',
              onPressed: () => context.push(RouteNames.enterResults),
            ),
        ],
      ),
      body: _ResultListBody(
        studentId: resolvedStudentId,
        selectedExam: _selectedExam,
        onExamSelected: (exam) => setState(() => _selectedExam = exam),
        selectedStandardId: _selectedStandardId,
        selectedSection: _selectedSection,
        selectedStudentId: _selectedStudentId,
        canBrowseStudents: canBrowseStudents,
        onStandardChanged: (value) {
          setState(() {
            _selectedStandardId = value;
            _selectedSection = null;
            _selectedStudentId = null;
            _selectedExam = null;
          });
        },
        onSectionChanged: (value) {
          setState(() {
            _selectedSection = value;
            _selectedStudentId = null;
            _selectedExam = null;
          });
        },
        onStudentChanged: (value) {
          setState(() {
            _selectedStudentId = value;
            _selectedExam = null;
          });
        },
        canEnterResults: canCreate,
        canPublish: canPublish,
      ),
    );
  }
}

class _ResultListBody extends ConsumerWidget {
  const _ResultListBody({
    required this.studentId,
    required this.selectedExam,
    required this.onExamSelected,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedStudentId,
    required this.canBrowseStudents,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
    required this.canEnterResults,
    required this.canPublish,
  });

  final String? studentId;
  final ExamModel? selectedExam;
  final ValueChanged<ExamModel> onExamSelected;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedStudentId;
  final bool canBrowseStudents;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;
  final bool canEnterResults;
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeYear = ref.watch(activeYearProvider);
    final standardsAsync = ref.watch(standardsProvider(activeYear?.id));
    final sectionsAsync =
        ref.watch(studentSectionsProvider(selectedStandardId));
    final studentsAsync = ref.watch(
      _studentsByFilterProvider(
        (standardId: selectedStandardId, section: selectedSection),
      ),
    );

    final selectorCard = canBrowseStudents
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: _ResultFilterCard(
              standardsAsync: standardsAsync,
              sectionsAsync: sectionsAsync,
              studentsAsync: studentsAsync,
              selectedStandardId: selectedStandardId,
              selectedSection: selectedSection,
              selectedStudentId: selectedStudentId,
              onStandardChanged: onStandardChanged,
              onSectionChanged: onSectionChanged,
              onStudentChanged: onStudentChanged,
            ),
          )
        : const SizedBox.shrink();

    if (studentId == null) {
      return Column(
        children: [
          selectorCard,
          const Expanded(
            child: AppEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No student selected',
              subtitle: 'Please select a student to view results.',
            ),
          ),
        ],
      );
    }

    if (selectedExam == null) {
      return Column(
        children: [
          selectorCard,
          Expanded(
            child: _ExamPickerView(
              studentId: studentId!,
              standardId: selectedStandardId,
              onExamSelected: onExamSelected,
              canPublish: canPublish,
            ),
          ),
        ],
      );
    }

    final params = (studentId: studentId!, examId: selectedExam!.id);
    final resultsAsync = ref.watch(resultListProvider(params));

    return Column(
      children: [
        selectorCard,
        Expanded(
          child: resultsAsync.when(
            loading: () => AppLoading.listView(withAvatar: false),
            error: (e, _) => AppErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(resultListProvider(params)),
            ),
            data: (response) => _ResultContent(
              exam: selectedExam!,
              results: response,
              studentId: studentId!,
              canPublish: canPublish,
              onChangeExam: () => onExamSelected(selectedExam!),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Exam picker view ──────────────────────────────────────────────────────────

class _ExamPickerView extends ConsumerWidget {
  const _ExamPickerView({
    required this.studentId,
    required this.standardId,
    required this.onExamSelected,
    required this.canPublish,
  });

  final String studentId;
  final String? standardId;
  final ValueChanged<ExamModel> onExamSelected;
  final bool canPublish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeYear = ref.watch(activeYearProvider);
    final examsAsync = ref.watch(
      examListProvider(
        (
          studentId: studentId,
          academicYearId: activeYear?.id,
          standardId: standardId,
        ),
      ),
    );

    return examsAsync.when(
      loading: () => AppLoading.listView(withAvatar: false),
      error: (e, _) => AppErrorState(
        message: e.toString(),
        onRetry: () => ref.invalidate(examListProvider),
      ),
      data: (exams) {
        if (exams.isEmpty) {
          return Column(
            children: [
              const SizedBox(height: AppDimensions.space24),
              Padding(
                padding: const EdgeInsets.all(AppDimensions.space16),
                child: _InfoCard(
                  icon: Icons.quiz_outlined,
                  title: 'No exams found',
                  subtitle:
                      'No exams available for this student and class yet.',
                  color: AppColors.navyMedium,
                ),
              ),
              if (canPublish) ...[
                const SizedBox(height: AppDimensions.space16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16),
                  child: _InfoCard(
                    icon: Icons.edit_note_outlined,
                    title: 'Enter Results',
                    subtitle:
                        'Create exam and enter marks from the Enter Results screen.',
                    color: AppColors.infoBlue,
                    onTap: () => context.push(RouteNames.enterResults),
                  ),
                ),
              ],
            ],
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.space16),
          itemCount: exams.length,
          itemBuilder: (context, index) {
            final exam = exams[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space12),
              child: _InfoCard(
                icon: Icons.assignment_turned_in_outlined,
                title: exam.name,
                subtitle:
                    '${exam.examType.label} • ${exam.startDate.toLocal().toIso8601String().split("T").first} to ${exam.endDate.toLocal().toIso8601String().split("T").first}',
                color: AppColors.navyMedium,
                onTap: () => onExamSelected(exam),
              ),
            );
          },
        );
      },
    );
  }
}

class _ResultFilterCard extends StatelessWidget {
  const _ResultFilterCard({
    required this.standardsAsync,
    required this.sectionsAsync,
    required this.studentsAsync,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedStudentId,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
  });

  final AsyncValue<List<StandardModel>> standardsAsync;
  final AsyncValue<List<String>> sectionsAsync;
  final AsyncValue<List<StudentModel>> studentsAsync;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedStudentId;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: standardsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (standards) => DropdownButtonFormField<String>(
                    value: selectedStandardId,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: standards
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: onStandardChanged,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: sectionsAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (sections) => DropdownButtonFormField<String>(
                    value: selectedSection,
                    decoration: const InputDecoration(
                      labelText: 'Section',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: sections
                        .map(
                          (s) => DropdownMenuItem<String>(
                            value: s,
                            child: Text(s),
                          ),
                        )
                        .toList(),
                    onChanged: onSectionChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          studentsAsync.when(
            loading: () => const LinearProgressIndicator(minHeight: 2),
            error: (_, __) => const SizedBox.shrink(),
            data: (students) => DropdownButtonFormField<String>(
              value: selectedStudentId,
              decoration: const InputDecoration(
                labelText: 'Student',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: students
                  .map(
                    (s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(
                        '${s.admissionNumber} (${s.section ?? '-'})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onStudentChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}

// ── Result content ────────────────────────────────────────────────────────────

class _ResultContent extends ConsumerWidget {
  const _ResultContent({
    required this.exam,
    required this.results,
    required this.studentId,
    required this.canPublish,
    required this.onChangeExam,
  });

  final ExamModel exam;
  final ResultListResponse results;
  final String studentId;
  final bool canPublish;
  final VoidCallback onChangeExam;

  double get _overallPercentage {
    if (results.items.isEmpty) return 0;
    final total = results.items.fold(0.0, (sum, e) => sum + e.marksObtained);
    final max = results.items.fold(0.0, (sum, e) => sum + e.maxMarks);
    return max > 0 ? (total / max) * 100 : 0;
  }

  double get _totalMarks =>
      results.items.fold(0.0, (sum, e) => sum + e.marksObtained);
  double get _maxMarks => results.items.fold(0.0, (sum, e) => sum + e.maxMarks);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsProvider(exam.standardId));
    final subjectMap = subjectsAsync.asData?.value.fold<Map<String, String>>(
          {},
          (map, s) => map..putIfAbsent(s.id, () => s.name),
        ) ??
        {};
    final subjectCodeMap =
        subjectsAsync.asData?.value.fold<Map<String, String>>(
              {},
              (map, s) => map..putIfAbsent(s.id, () => s.code),
            ) ??
            {};

    if (results.items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grading_outlined,
        title: 'No results yet',
        subtitle: 'Results will appear here once entered and published.',
      );
    }

    final pct = _overallPercentage;

    return CustomScrollView(
      slivers: [
        // Summary card
        SliverToBoxAdapter(
          child: _SummaryCard(
            exam: exam,
            percentage: pct,
            totalMarks: _totalMarks,
            maxMarks: _maxMarks,
            canPublish: canPublish,
            studentId: studentId,
            onReportCard: () => context.push(
              RouteNames.reportCard,
              extra: {'studentId': studentId, 'examId': exam.id},
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space20,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: Text(
              'Subject-wise Results',
              style: AppTypography.headlineSmall,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
            ),
            child: Column(
              children: results.items.asMap().entries.map((entry) {
                final idx = entry.key;
                final result = entry.value;
                return ResultSubjectTile(
                  entry: result,
                  subjectName: subjectMap[result.subjectId] ?? result.subjectId,
                  subjectCode: subjectCodeMap[result.subjectId],
                  isLast: idx == results.items.length - 1,
                  showPublishedBadge: canPublish,
                );
              }).toList(),
            ),
          ),
        ),
        const SliverPadding(
            padding: EdgeInsets.only(bottom: AppDimensions.space40)),
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({
    required this.exam,
    required this.percentage,
    required this.totalMarks,
    required this.maxMarks,
    required this.canPublish,
    required this.studentId,
    required this.onReportCard,
  });

  final ExamModel exam;
  final double percentage;
  final double totalMarks;
  final double maxMarks;
  final bool canPublish;
  final String studentId;
  final VoidCallback onReportCard;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublishing =
        ref.watch(publishExamProvider.select((s) => s.isPublishing));

    return Container(
      margin: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      _ExamTypeBadge(examType: exam.examType),
                    ],
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                GradeBadge.large(percentage: percentage),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                _StatChip(
                  label: 'Total',
                  value:
                      '${totalMarks.toStringAsFixed(totalMarks % 1 == 0 ? 0 : 1)} / ${maxMarks.toStringAsFixed(maxMarks % 1 == 0 ? 0 : 1)}',
                ),
                const SizedBox(width: AppDimensions.space12),
                _StatChip(
                  label: 'Percentage',
                  value: '${percentage.toStringAsFixed(1)}%',
                  highlight: true,
                  percentage: percentage,
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _barColor(percentage),
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'Report Card',
                    onTap: onReportCard,
                  ),
                ),
                if (canPublish) ...[
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.publish_outlined,
                      label: isPublishing ? 'Publishing…' : 'Publish',
                      onTap: isPublishing
                          ? null
                          : () async {
                              final success = await ref
                                  .read(publishExamProvider.notifier)
                                  .publish(exam.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Results published!'
                                        : ref.read(publishExamProvider).error ??
                                            'Failed'),
                                    backgroundColor: success
                                        ? AppColors.successGreen
                                        : AppColors.errorRed,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      isLoading: isPublishing,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _barColor(double pct) {
    if (pct >= 75) return AppColors.successGreen;
    if (pct >= 50) return AppColors.warningAmber;
    return AppColors.errorRed;
  }
}

class _ExamTypeBadge extends StatelessWidget {
  const _ExamTypeBadge({required this.examType});
  final ExamType examType;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
      ),
      child: Text(
        examType.label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.goldPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.percentage,
  });

  final String label;
  final String value;
  final bool highlight;
  final double? percentage;

  Color get _valueColor {
    if (!highlight || percentage == null) return AppColors.white;
    if (percentage! >= 75) return AppColors.successGreen;
    if (percentage! >= 50) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12, vertical: AppDimensions.space8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              color: _valueColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.space8, horizontal: AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            else
              Icon(icon, size: 16, color: AppColors.white),
            const SizedBox(width: AppDimensions.space6),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
