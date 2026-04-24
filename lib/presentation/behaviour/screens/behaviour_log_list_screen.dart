import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/behaviour/behaviour_log_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/behaviour_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_chip.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/behaviour_log_tile.dart';

class BehaviourLogListScreen extends ConsumerStatefulWidget {
  const BehaviourLogListScreen({super.key, this.studentId});

  final String? studentId;

  @override
  ConsumerState<BehaviourLogListScreen> createState() =>
      _BehaviourLogListScreenState();
}

class _BehaviourLogListScreenState
    extends ConsumerState<BehaviourLogListScreen> {
  IncidentType? _incidentFilter;
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _selectedStudentId = widget.studentId;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = ref.read(currentUserProvider);
      if (user?.role == UserRole.parent) {
        await ref.read(childrenNotifierProvider.notifier).loadMyChildren();
      }
    });
  }

  String? _resolveStudentId(String? currentStudentId) {
    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      return widget.studentId;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return null;
    if (user.role == UserRole.parent) {
      return ref.read(selectedChildIdProvider);
    }
    if (user.role == UserRole.student) {
      return currentStudentId;
    }
    if (user.role == UserRole.principal ||
        user.role == UserRole.trustee ||
        user.role == UserRole.superadmin) {
      return null;
    }
    return null;
  }

  List<BehaviourLogModel> _applyFilter(List<BehaviourLogModel> items) {
    if (_incidentFilter == null) return items;
    return items.where((log) => log.incidentType == _incidentFilter).toList();
  }

  void _openLogDetails(BehaviourLogModel log) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BehaviourLogDetailSheet(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final currentStudentIdAsync = ref.watch(currentStudentIdProvider);
    final baseStudentId = _resolveStudentId(currentStudentIdAsync.valueOrNull);
    final isManagementRole = user?.role == UserRole.principal ||
        user?.role == UserRole.trustee ||
        user?.role == UserRole.superadmin;
    final isTeacherRole = user?.role == UserRole.teacher;
    final hasPinnedStudent =
        widget.studentId != null && widget.studentId!.isNotEmpty;
    final studentIdForApi = hasPinnedStudent
        ? widget.studentId
        : ((isManagementRole || isTeacherRole)
            ? _selectedStudentId
            : baseStudentId);
    final canCreate = user?.hasPermission('behaviour_log:create') ?? false;

    if (baseStudentId == null) {
      final isStudent = user?.role == UserRole.student;
      final canSeeAll = user?.role == UserRole.principal ||
          user?.role == UserRole.trustee ||
          user?.role == UserRole.superadmin ||
          user?.role == UserRole.teacher;
      if (canSeeAll) {
        // For management roles, no student filter means all-school behaviour logs.
      } else if (isStudent && currentStudentIdAsync.isLoading) {
        return const AppScaffold(
          appBar: AppAppBar(title: 'Behaviour Log', showBack: true),
          body: Center(child: CircularProgressIndicator()),
        );
      }
      if (!canSeeAll) {
        return const AppScaffold(
          appBar: AppAppBar(title: 'Behaviour Log', showBack: true),
          body: AppEmptyState(
            icon: Icons.person_search_outlined,
            title: 'No student selected',
            subtitle: 'Open this page from a student profile to view logs.',
          ),
        );
      }
    }

    final standardsAsync = isManagementRole && !hasPinnedStudent
        ? ref.watch(standardsProvider(activeYearId))
        : const AsyncValue<List<dynamic>>.data(<dynamic>[]);
    final sectionsAsync = isManagementRole &&
            !hasPinnedStudent &&
            _selectedStandardId != null &&
            _selectedStandardId!.isNotEmpty
        ? ref.watch(
            sectionsByStandardProvider((
              standardId: _selectedStandardId!,
              academicYearId: activeYearId,
            )),
          )
        : const AsyncValue<List<String>>.data(<String>[]);
    final studentsByClassAsync = isManagementRole &&
            !hasPinnedStudent &&
            _selectedStandardId != null &&
            _selectedStandardId!.isNotEmpty
        ? ref.watch(_studentsByClassSectionProvider((
            standardId: _selectedStandardId!,
            section: _selectedSection,
            academicYearId: activeYearId,
          )))
        : const AsyncValue<List<StudentModel>>.data(<StudentModel>[]);
    final teacherAssignmentsAsync = isTeacherRole && !hasPinnedStudent
        ? ref.watch(myTeacherAssignmentsProvider(activeYearId))
        : const AsyncValue<List<TeacherClassSubjectModel>>.data(
            <TeacherClassSubjectModel>[],
          );
    final teacherStudentsByClassAsync = isTeacherRole &&
            !hasPinnedStudent &&
            _selectedStandardId != null &&
            _selectedStandardId!.isNotEmpty &&
            _selectedSection != null &&
            _selectedSection!.isNotEmpty &&
            activeYearId != null &&
            activeYearId.isNotEmpty
        ? ref.watch(
            studentsForAttendanceProvider(
              (
                standardId: _selectedStandardId!,
                section: _selectedSection!,
                academicYearId: activeYearId,
              ),
            ),
          )
        : const AsyncValue<List<StudentModel>>.data(<StudentModel>[]);

    final logsQuery = (
      studentId: studentIdForApi,
      incidentType: _incidentFilter,
      standardId:
          (isManagementRole || isTeacherRole) ? _selectedStandardId : null,
      section: (isManagementRole || isTeacherRole) ? _selectedSection : null,
    );
    final logsAsync = ref.watch(behaviourLogsProvider(logsQuery));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Behaviour Log',
        showBack: true,
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton(
              onPressed: () async {
                final created = await context.push<bool>(
                  RouteNames.createBehaviourLogPath(studentId: baseStudentId),
                );
                if (created == true) {
                  ref.invalidate(behaviourLogsProvider(logsQuery));
                }
              },
              backgroundColor: AppColors.goldPrimary,
              tooltip: 'Create Behaviour Log',
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async {
          ref.invalidate(behaviourLogsProvider(logsQuery));
          await ref.read(behaviourLogsProvider(logsQuery).future);
        },
        child: logsAsync.when(
          loading: () => AppLoading.listView(count: 6, withAvatar: false),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(behaviourLogsProvider(logsQuery)),
          ),
          data: (response) {
            final filtered = _applyFilter(response.items);
            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (isManagementRole && !hasPinnedStudent)
                  SliverToBoxAdapter(
                    child: _BehaviourClassStudentFilterPanel(
                      standardsAsync: standardsAsync,
                      sectionsAsync: sectionsAsync,
                      studentsAsync: studentsByClassAsync,
                      selectedStandardId: _selectedStandardId,
                      selectedSection: _selectedSection,
                      selectedStudentId: _selectedStudentId,
                      onStandardChanged: (value) {
                        setState(() {
                          _selectedStandardId = value;
                          _selectedSection = null;
                          _selectedStudentId = null;
                        });
                      },
                      onSectionChanged: (value) {
                        setState(() {
                          _selectedSection = value;
                          _selectedStudentId = null;
                        });
                      },
                      onStudentChanged: (value) {
                        setState(() {
                          _selectedStudentId = value;
                        });
                      },
                    ),
                  ),
                if (isTeacherRole && !hasPinnedStudent)
                  SliverToBoxAdapter(
                    child: _TeacherBehaviourFilterPanel(
                      assignmentsAsync: teacherAssignmentsAsync,
                      studentsAsync: teacherStudentsByClassAsync,
                      selectedStandardId: _selectedStandardId,
                      selectedSection: _selectedSection,
                      selectedStudentId: _selectedStudentId,
                      onStandardChanged: (value) {
                        setState(() {
                          _selectedStandardId = value;
                          _selectedSection = null;
                          _selectedStudentId = null;
                        });
                      },
                      onSectionChanged: (value) {
                        setState(() {
                          _selectedSection = value;
                          _selectedStudentId = null;
                        });
                      },
                      onStudentChanged: (value) {
                        setState(() {
                          _selectedStudentId = value;
                        });
                      },
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _BehaviourFilterRow(
                    selected: _incidentFilter,
                    onSelected: (type) {
                      setState(() => _incidentFilter = type);
                    },
                  ),
                ),
                if (filtered.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.space16,
                        AppDimensions.space20,
                        AppDimensions.space16,
                        AppDimensions.pageBottomScroll,
                      ),
                      child: SizedBox(
                        height: 320,
                        child: AppEmptyState(
                          compact: true,
                          icon: Icons.fact_check_outlined,
                          title: 'No behaviour entries',
                          subtitle: _incidentFilter == null
                              ? (studentIdForApi == null
                                  ? 'No incidents logged yet.'
                                  : 'No incidents logged for this student yet.')
                              : 'No ${_incidentFilter!.label.toLowerCase()} incidents found.',
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.space16,
                      AppDimensions.space8,
                      AppDimensions.space16,
                      AppDimensions.pageBottomScroll,
                    ),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppDimensions.space12),
                      itemBuilder: (_, index) {
                        final log = filtered[index];
                        return BehaviourLogTile(
                          log: log,
                          onTap: () => _openLogDetails(log),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

typedef _StudentsFilterParams = ({
  String standardId,
  String? section,
  String? academicYearId,
});

final _studentsByClassSectionProvider =
    FutureProvider.family<List<StudentModel>, _StudentsFilterParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final items = <StudentModel>[];
    var page = 1;
    var totalPages = 1;

    do {
      final result = await repo.list(
        standardId: params.standardId,
        section: params.section,
        academicYearId: params.academicYearId,
        page: page,
        pageSize: 100,
      );
      items.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);

    final uniqueById = <String, StudentModel>{};
    for (final student in items) {
      uniqueById[student.id] = student;
    }

    final uniqueItems = uniqueById.values.toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return uniqueItems;
  },
);

class _BehaviourClassStudentFilterPanel extends StatelessWidget {
  const _BehaviourClassStudentFilterPanel({
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

  final AsyncValue<List<dynamic>> standardsAsync;
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
    final standards = standardsAsync.valueOrNull ?? const [];
    final sections = sectionsAsync.valueOrNull ?? const <String>[];
    final students = studentsAsync.valueOrNull ?? const <StudentModel>[];

    final standardOptions = <String, String>{};
    for (final standard in standards) {
      standardOptions[standard.id.toString()] = standard.name.toString();
    }

    final sectionOptions = <String>{...sections};

    final studentOptions = <String, String>{};
    for (final student in students) {
      studentOptions[student.id] = student.displayName;
    }

    final safeSelectedStandardId = selectedStandardId != null &&
            standardOptions.containsKey(selectedStandardId)
        ? selectedStandardId
        : null;
    final safeSelectedSection =
        selectedSection != null && sectionOptions.contains(selectedSection)
            ? selectedSection
            : null;
    final safeSelectedStudentId = selectedStudentId != null &&
            studentOptions.containsKey(selectedStudentId)
        ? selectedStudentId
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: safeSelectedStandardId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...standardOptions.entries.map(
                      (entry) => DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: safeSelectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...sectionOptions.map(
                      (section) => DropdownMenuItem<String?>(
                        value: section,
                        child: Text(section),
                      ),
                    ),
                  ],
                  onChanged:
                      selectedStandardId == null ? null : onSectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: safeSelectedStudentId,
            decoration: const InputDecoration(
              labelText: 'Student',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All'),
              ),
              ...studentOptions.entries.map(
                (entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: selectedStandardId == null ? null : onStudentChanged,
          ),
        ],
      ),
    );
  }
}

class _BehaviourFilterRow extends StatelessWidget {
  const _BehaviourFilterRow({
    required this.selected,
    required this.onSelected,
  });

  final IncidentType? selected;
  final ValueChanged<IncidentType?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        AppDimensions.space8,
      ),
      child: Row(
        children: [
          AppChip(
            label: 'All',
            isSelected: selected == null,
            onTap: () => onSelected(null),
            small: true,
          ),
          const SizedBox(width: AppDimensions.space8),
          ...IncidentType.values.map(
            (type) => Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space8),
              child: AppChip(
                label: type.label,
                icon: type.icon,
                isSelected: selected == type,
                onTap: () => onSelected(type),
                selectedColor: type.color,
                small: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherBehaviourFilterPanel extends StatelessWidget {
  const _TeacherBehaviourFilterPanel({
    required this.assignmentsAsync,
    required this.studentsAsync,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedStudentId,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onStudentChanged,
  });

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;
  final AsyncValue<List<StudentModel>> studentsAsync;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedStudentId;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onStudentChanged;

  @override
  Widget build(BuildContext context) {
    final assignments =
        assignmentsAsync.valueOrNull ?? const <TeacherClassSubjectModel>[];
    final students = studentsAsync.valueOrNull ?? const <StudentModel>[];

    final classOptions = <String, String>{};
    for (final assignment in assignments) {
      classOptions.putIfAbsent(
        assignment.standardId,
        () => assignment.standardName ?? assignment.standardId,
      );
    }

    final List<String> sectionOptions = assignments
        .where((a) => a.standardId == selectedStandardId)
        .map((a) => a.section.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final studentOptions = <String, String>{};
    for (final student in students) {
      studentOptions[student.id] = student.displayName;
    }

    final safeSelectedStandardId = selectedStandardId != null &&
            classOptions.containsKey(selectedStandardId)
        ? selectedStandardId
        : null;
    final safeSelectedSection =
        selectedSection != null && sectionOptions.contains(selectedSection)
            ? selectedSection
            : null;
    final safeSelectedStudentId = selectedStudentId != null &&
            studentOptions.containsKey(selectedStudentId)
        ? selectedStudentId
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: safeSelectedStandardId,
                  decoration: const InputDecoration(
                    labelText: 'Class',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...classOptions.entries.map(
                      (entry) => DropdownMenuItem<String?>(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  isExpanded: true,
                  initialValue: safeSelectedSection,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All'),
                    ),
                    ...sectionOptions.map(
                      (section) => DropdownMenuItem<String?>(
                        value: section,
                        child: Text(section),
                      ),
                    ),
                  ],
                  onChanged:
                      safeSelectedStandardId == null ? null : onSectionChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space8),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: safeSelectedStudentId,
            decoration: const InputDecoration(
              labelText: 'Student',
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All'),
              ),
              ...studentOptions.entries.map(
                (entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                ),
              ),
            ],
            onChanged: safeSelectedStandardId == null || safeSelectedSection == null
                ? null
                : onStudentChanged,
          ),
        ],
      ),
    );
  }
}

class _BehaviourLogDetailSheet extends ConsumerStatefulWidget {
  const _BehaviourLogDetailSheet({required this.log});

  final BehaviourLogModel log;

  @override
  ConsumerState<_BehaviourLogDetailSheet> createState() =>
      _BehaviourLogDetailSheetState();
}

class _BehaviourLogDetailSheetState
    extends ConsumerState<_BehaviourLogDetailSheet> {
  late final Future<StudentModel?> _studentFuture;
  late final Future<String?> _teacherNameFuture;

  @override
  void initState() {
    super.initState();
    _studentFuture = _loadStudent();
    _teacherNameFuture = _loadTeacherName();
  }

  Future<StudentModel?> _loadStudent() async {
    try {
      final repo = ref.read(studentRepositoryProvider);
      return await repo.getById(widget.log.studentId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _loadTeacherName() async {
    try {
      final repo = ref.read(teacherRepositoryProvider);
      final teacher = await repo.getById(widget.log.teacherId);
      return teacher.displayName;
    } catch (_) {
      return null;
    }
  }

  String _formatDateTime(DateTime value) {
    final d = DateFormatter.formatDate(value);
    final t = TimeOfDay.fromDateTime(value).format(context);
    return '$d, $t';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppDimensions.space16,
            AppDimensions.space12,
            AppDimensions.space16,
            AppDimensions.space16 + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'Behaviour Detail',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDeep,
                    ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: [
                  AppChip(
                    label: widget.log.incidentType.label,
                    icon: widget.log.incidentType.icon,
                    isSelected: true,
                    selectedColor: widget.log.incidentType.color,
                    small: true,
                  ),
                  AppChip(
                    label: widget.log.severity.label,
                    isSelected: true,
                    selectedColor: widget.log.severity.color,
                    small: true,
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space16),
              _DetailRow(
                label: 'Incident Date',
                value: DateFormatter.formatDate(widget.log.incidentDate),
              ),
              const SizedBox(height: AppDimensions.space8),
              _DetailRow(
                label: 'Logged On',
                value: _formatDateTime(widget.log.createdAt),
              ),
              const SizedBox(height: AppDimensions.space8),
              FutureBuilder<StudentModel?>(
                future: _studentFuture,
                builder: (context, snap) {
                  final studentName = snap.data?.displayName ?? 'Student';
                  return _DetailRow(
                    label: 'Student',
                    value: studentName,
                  );
                },
              ),
              const SizedBox(height: AppDimensions.space8),
              FutureBuilder<String?>(
                future: _teacherNameFuture,
                builder: (context, snap) {
                  final teacher = snap.data;
                  final value = (teacher == null || teacher.trim().isEmpty)
                      ? 'Teacher'
                      : teacher;
                  return _DetailRow(
                    label: 'Reported By',
                    value: value,
                  );
                },
              ),
              const SizedBox(height: AppDimensions.space16),
              Text(
                'Feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppDimensions.space8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppDimensions.space12),
                decoration: BoxDecoration(
                  color: AppColors.surface50,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(color: AppColors.surface200),
                ),
                child: Text(
                  widget.log.description.trim().isEmpty
                      ? 'No additional feedback.'
                      : widget.log.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        color: AppColors.grey700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey800,
                ),
          ),
        ),
      ],
    );
  }
}
