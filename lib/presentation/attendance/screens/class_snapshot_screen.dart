import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../data/models/attendance/attendance_snapshot.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../data/repositories/teacher_repository.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';

typedef _AttendanceOverviewParams = ({
  String metric,
  String? academicYearId,
  String? reportDate,
  String? standardId,
  String? section,
  String? studentId,
  String? teacherId,
  String? subjectId,
});

final _attendanceOverviewProvider =
    FutureProvider.family<Map<String, dynamic>, _AttendanceOverviewParams>(
  (ref, params) async {
    final dio = ref.read(dioClientProvider);
    final response = await dio.get(
      '/principal-reports/details',
      queryParameters: {
        'metric': params.metric,
        if (params.academicYearId != null)
          'academic_year_id': params.academicYearId,
        if (params.reportDate != null) 'report_date': params.reportDate,
        if (params.standardId != null) 'standard_id': params.standardId,
        if (params.section != null && params.section!.isNotEmpty)
          'section': params.section,
        if (params.studentId != null) 'student_id': params.studentId,
        if (params.teacherId != null) 'teacher_id': params.teacherId,
        if (params.subjectId != null) 'subject_id': params.subjectId,
      },
    );
    return Map<String, dynamic>.from(response.data as Map);
  },
);

typedef _OverviewStudentsParams = ({
  String? academicYearId,
  String? standardId,
  String? section,
});

final _overviewStudentsProvider =
    FutureProvider.family<List<StudentModel>, _OverviewStudentsParams>(
  (ref, params) async {
    final repo = ref.read(studentRepositoryProvider);
    final allItems = <StudentModel>[];
    var page = 1;
    var totalPages = 1;
    do {
      final result = await repo.list(
        academicYearId: params.academicYearId,
        standardId: params.standardId,
        section: params.section,
        page: page,
        pageSize: 100,
      );
      allItems.addAll(result.items);
      totalPages = result.totalPages;
      page += 1;
    } while (page <= totalPages);
    return allItems;
  },
);

final _overviewTeachersProvider =
    FutureProvider.family<List<TeacherModel>, String?>(
  (ref, academicYearId) async {
    final repo = ref.read(teacherRepositoryProvider);
    final result = await repo.list(
      academicYearId: academicYearId,
      page: 1,
      pageSize: 200,
    );
    return result.items;
  },
);

typedef _OverviewSectionsParams = ({
  String? standardId,
  String? academicYearId,
});

final _overviewSectionsProvider =
    FutureProvider.family<List<String>, _OverviewSectionsParams>(
  (ref, params) async {
    if (params.standardId == null || params.standardId!.isEmpty) {
      return const <String>[];
    }
    final repo = ref.read(studentRepositoryProvider);
    final sections = await repo.listSections(
      standardId: params.standardId,
      academicYearId: params.academicYearId,
    );
    return sections.where((s) => s.trim().isNotEmpty).toList();
  },
);

class ClassSnapshotScreen extends ConsumerStatefulWidget {
  const ClassSnapshotScreen({super.key});

  @override
  ConsumerState<ClassSnapshotScreen> createState() =>
      _ClassSnapshotScreenState();
}

class _ClassSnapshotScreenState extends ConsumerState<ClassSnapshotScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  String? _selectedStandardId;
  String? _activeYearId;
  bool _hasFetched = false;
  ClassSnapshotParams? _currentParams;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapSnapshotFilters();
    });
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0 && _currentParams != null) {
      ref.invalidate(classSnapshotProvider(_currentParams!));
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapSnapshotFilters() async {
    final year = ref.read(activeYearProvider);
    if (year == null || !mounted) return;

    final standards = await ref.read(standardsProvider(year.id).future);
    if (!mounted) return;

    final defaultStandardId = _selectedStandardId ??
        (standards.isNotEmpty ? standards.first.id : null);

    setState(() {
      _activeYearId = year.id;
      _selectedStandardId = defaultStandardId;
    });

    if (defaultStandardId != null) {
      _load();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: AppColors.navyDeep, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _load() {
    if (_selectedStandardId == null || _activeYearId == null) {
      SnackbarUtils.showError(context, 'Please select a class first');
      return;
    }
    final date =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    setState(() {
      _hasFetched = true;
      _currentParams = (
        standardId: _selectedStandardId!,
        academicYearId: _activeYearId!,
        date: date,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppAppBar(
        title: 'Class Snapshot',
        showBack: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Snapshot'), Tab(text: 'Overview')],
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.55),
          indicatorColor: AppColors.goldPrimary,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle:
              AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _SnapshotTab(
            selectedDate: _selectedDate,
            selectedStandardId: _selectedStandardId,
            activeYearId: _activeYearId,
            hasFetched: _hasFetched,
            currentParams: _currentParams,
            onPickDate: _pickDate,
            onStandardChanged: (id) => setState(() => _selectedStandardId = id),
            onLoad: _load,
          ),
          _OverviewTab(
            selectedDate: _selectedDate,
            selectedStandardId: _selectedStandardId,
            activeYearId: _activeYearId,
          ),
        ],
      ),
    );
  }
}

class _SnapshotTab extends ConsumerWidget {
  const _SnapshotTab({
    required this.selectedDate,
    required this.selectedStandardId,
    required this.activeYearId,
    required this.hasFetched,
    required this.currentParams,
    required this.onPickDate,
    required this.onStandardChanged,
    required this.onLoad,
  });

  final DateTime selectedDate;
  final String? selectedStandardId;
  final String? activeYearId;
  final bool hasFetched;
  final ClassSnapshotParams? currentParams;
  final VoidCallback onPickDate;
  final ValueChanged<String?> onStandardChanged;
  final VoidCallback onLoad;

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      key: const PageStorageKey<String>('attendance-snapshot-scroll'),
      primary: false,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onPickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                      color: AppColors.surface50,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.surface200, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 16, color: AppColors.navyMedium),
                        const SizedBox(width: 10),
                        Text(_formatDate(selectedDate),
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800)),
                        const Spacer(),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.grey400, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  if (activeYearId == null) return AppLoading.listTile();
                  return ref.watch(standardsProvider(activeYearId)).when(
                        data: (standards) => DropdownButtonFormField<String>(
                          initialValue: selectedStandardId,
                          decoration: _inputDecoration('Select class'),
                          items: standards
                              .map((s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name,
                                        style: AppTypography.bodyMedium),
                                  ))
                              .toList(),
                          onChanged: onStandardChanged,
                        ),
                        loading: () => AppLoading.listTile(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                }),
                const SizedBox(height: 12),
                AppButton.primary(
                    label: 'Load Snapshot',
                    onTap: onLoad,
                    icon: Icons.refresh_rounded),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
            child: Divider(height: 1, color: AppColors.surface100)),
        if (!hasFetched || currentParams == null)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.groups_outlined,
              title: 'Select a class and date',
              subtitle:
                  'Choose a class and date above, then tap Load Snapshot.',
            ),
          )
        else
          _SnapshotContent(currentParams: currentParams!, onLoad: onLoad),
      ],
    );
  }
}

class _SnapshotContent extends ConsumerWidget {
  const _SnapshotContent({required this.currentParams, required this.onLoad});
  final ClassSnapshotParams currentParams;
  final VoidCallback onLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(classSnapshotProvider(currentParams));

    return snapshotAsync.when(
      data: (snapshot) {
        if (snapshot.records.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: AppEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No records found',
              subtitle: 'No attendance was marked for this class on this date.',
            ),
          );
        }

        return SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(child: _SnapshotSummaryBar(snapshot: snapshot)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverList.builder(
              itemCount: snapshot.records.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SnapshotRecordTile(
                  record: snapshot.records[index],
                  isLast: index == snapshot.records.length - 1,
                  onTap: () => context.push(
                    RouteNames.attendanceAnalyticsPath(
                        snapshot.records[index].studentId),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ]);
      },
      loading: () => SliverFillRemaining(
        hasScrollBody: false,
        child: SizedBox.expand(child: AppLoading.fullPage()),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: AppErrorState(message: e.toString(), onRetry: onLoad),
      ),
    );
  }
}

enum _AttendanceOverviewAudience { students, teachers }

class _OverviewTab extends ConsumerStatefulWidget {
  const _OverviewTab({
    required this.selectedDate,
    required this.selectedStandardId,
    required this.activeYearId,
  });

  final DateTime selectedDate;
  final String? selectedStandardId;
  final String? activeYearId;

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  String? _standardId;
  String? _section;
  String? _studentId;
  String? _teacherId;
  String? _subjectId;
  _AttendanceOverviewAudience _audience = _AttendanceOverviewAudience.students;

  @override
  void initState() {
    super.initState();
    _standardId = widget.selectedStandardId;
  }

  @override
  void didUpdateWidget(covariant _OverviewTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_standardId == null && widget.selectedStandardId != null) {
      _standardId = widget.selectedStandardId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportDate =
        '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

    final standardsAsync = ref.watch(standardsProvider(widget.activeYearId));
    final sectionsAsync = ref.watch(_overviewSectionsProvider((
      standardId: _standardId,
      academicYearId: widget.activeYearId,
    )));
    final AsyncValue<List<StudentModel>> studentsAsync =
        _audience == _AttendanceOverviewAudience.students
            ? ref.watch(
                _overviewStudentsProvider((
                  academicYearId: widget.activeYearId,
                  standardId: _standardId,
                  section: _section,
                )),
              )
            : const AsyncData(<StudentModel>[]);
    final AsyncValue<List<TeacherModel>> teachersAsync =
        _audience == _AttendanceOverviewAudience.teachers
            ? ref.watch(_overviewTeachersProvider(widget.activeYearId))
            : const AsyncData(<TeacherModel>[]);
    final AsyncValue<List<dynamic>> subjectsAsync = _audience ==
            _AttendanceOverviewAudience.students
        ? ref.watch(subjectsProvider(_standardId)).whenData((items) => items)
        : const AsyncData(<dynamic>[]);

    final detailsAsync = ref.watch(
      _attendanceOverviewProvider((
        metric: _audience == _AttendanceOverviewAudience.students
            ? 'student_attendance'
            : 'teacher_attendance',
        academicYearId: widget.activeYearId,
        reportDate: reportDate,
        standardId: _standardId,
        section: _section,
        studentId: _audience == _AttendanceOverviewAudience.students
            ? _studentId
            : null,
        teacherId: _audience == _AttendanceOverviewAudience.teachers
            ? _teacherId
            : null,
        subjectId: _audience == _AttendanceOverviewAudience.students
            ? _subjectId
            : null,
      )),
    );

    return SingleChildScrollView(
      key: const PageStorageKey<String>('attendance-overview-scroll'),
      primary: false,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterPanel(
            standardsAsync: standardsAsync,
            sectionsAsync: sectionsAsync,
            studentsAsync: studentsAsync,
            teachersAsync: teachersAsync,
            subjectsAsync: subjectsAsync,
          ),
          const SizedBox(height: 12),
          if (_audience == _AttendanceOverviewAudience.students) ...[
            _buildStudentKpi(detailsAsync),
            const SizedBox(height: 12),
            _buildStudentSubjectBreakdown(detailsAsync),
          ] else ...[
            _buildTeacherKpi(detailsAsync),
            const SizedBox(height: 12),
            _buildTeacherAttendanceList(detailsAsync),
          ],
        ],
      ),
    );
  }

  T? _valueIfPresent<T>(Object? value, List<T> items) {
    if (value is! T) return null;
    return items.contains(value) ? value : null;
  }

  Widget _buildFilterPanel({
    required AsyncValue<dynamic> standardsAsync,
    required AsyncValue<dynamic> sectionsAsync,
    required AsyncValue<List<StudentModel>> studentsAsync,
    required AsyncValue<List<TeacherModel>> teachersAsync,
    required AsyncValue<dynamic> subjectsAsync,
  }) {
    final standards = (standardsAsync.valueOrNull as List?) ?? const [];
    final sections = (sectionsAsync.valueOrNull as List?) ?? const [];
    final students = studentsAsync.valueOrNull ?? const <StudentModel>[];
    final teachers = teachersAsync.valueOrNull ?? const <TeacherModel>[];
    final subjects = (subjectsAsync.valueOrNull as List?) ?? const [];

    final standardIds = standards
        .map((s) => s.id.toString())
        .where((s) => s.isNotEmpty)
        .toList();
    final sectionIds =
        sections.map((s) => s.toString()).where((s) => s.isNotEmpty).toList();
    final studentIds =
        students.map((s) => s.id).where((s) => s.isNotEmpty).toList();
    final teacherIds =
        teachers.map((t) => t.id).where((t) => t.isNotEmpty).toList();
    final subjectIds = subjects
        .map((s) => s.id.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    final standardValue = _valueIfPresent(_standardId, standardIds);
    final sectionValue = _valueIfPresent(_section, sectionIds);
    final studentValue = _valueIfPresent(_studentId, studentIds);
    final teacherValue = _valueIfPresent(_teacherId, teacherIds);
    final subjectValue = _valueIfPresent(_subjectId, subjectIds);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Type',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Students'),
                selected: _audience == _AttendanceOverviewAudience.students,
                onSelected: (_) => setState(() {
                  _audience = _AttendanceOverviewAudience.students;
                  _teacherId = null;
                }),
              ),
              ChoiceChip(
                label: const Text('Teachers'),
                selected: _audience == _AttendanceOverviewAudience.teachers,
                onSelected: (_) => setState(() {
                  _audience = _AttendanceOverviewAudience.teachers;
                  _studentId = null;
                  _subjectId = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(
                      'std-${standardIds.join(',')}-${standardValue ?? 'all'}'),
                  initialValue: standardValue,
                  isExpanded: true,
                  decoration: _inputDecoration('Class'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...standards.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.id.toString(),
                        child: Text(s.name.toString()),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _standardId = value;
                    _section = null;
                    _studentId = null;
                    _subjectId = null;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  key: ValueKey(
                      'sec-${sectionIds.join(',')}-${sectionValue ?? 'all'}'),
                  initialValue: sectionValue,
                  isExpanded: true,
                  decoration: _inputDecoration('Section'),
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('All')),
                    ...sectionIds.map(
                      (section) => DropdownMenuItem<String?>(
                        value: section,
                        child: Text(section),
                      ),
                    ),
                  ],
                  onChanged: _standardId == null
                      ? null
                      : (value) => setState(() {
                            _section = value;
                            _studentId = null;
                          }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_audience == _AttendanceOverviewAudience.students)
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(
                        'stu-${studentIds.join(',')}-${studentValue ?? 'all'}'),
                    initialValue: studentValue,
                    isExpanded: true,
                    decoration: _inputDecoration('Student'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      ...students.map(
                        (student) => DropdownMenuItem<String?>(
                          value: student.id,
                          child: Text(student.displayName),
                        ),
                      ),
                    ],
                    onChanged: _standardId == null
                        ? null
                        : (value) => setState(() => _studentId = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    key: ValueKey(
                        'sub-${subjectIds.join(',')}-${subjectValue ?? 'all'}'),
                    initialValue: subjectValue,
                    isExpanded: true,
                    decoration: _inputDecoration('Subject'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('All')),
                      ...subjects.map(
                        (subject) => DropdownMenuItem<String?>(
                          value: subject.id.toString(),
                          child: Text(subject.name.toString()),
                        ),
                      ),
                    ],
                    onChanged: _standardId == null
                        ? null
                        : (value) => setState(() => _subjectId = value),
                  ),
                ),
              ],
            )
          else
            DropdownButtonFormField<String?>(
              key: ValueKey(
                  'tea-${teacherIds.join(',')}-${teacherValue ?? 'all'}'),
              initialValue: teacherValue,
              isExpanded: true,
              decoration: _inputDecoration('Teacher'),
              items: [
                const DropdownMenuItem<String?>(
                    value: null, child: Text('All')),
                ...teachers.map(
                  (teacher) => DropdownMenuItem<String?>(
                    value: teacher.id,
                    child: Text(teacher.displayName),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _teacherId = value),
            ),
        ],
      ),
    );
  }

  Widget _buildStudentKpi(AsyncValue<Map<String, dynamic>> detailsAsync) {
    if (detailsAsync.isLoading) return AppLoading.card(height: 128);
    if (detailsAsync.hasError) {
      return AppErrorState(message: detailsAsync.error.toString());
    }

    final summary = Map<String, dynamic>.from(
      detailsAsync.valueOrNull?['student_attendance'] as Map? ?? {},
    );
    final percent = (summary['value'] as num?)?.toDouble() ?? 0;
    final present = summary['numerator']?.toString() ?? '0';
    final total = summary['denominator']?.toString() ?? '0';

    return _KpiCard(
      title: 'Student Attendance',
      value: '${percent.toStringAsFixed(1)}%',
      subtitle: '$present present / $total records',
      icon: Icons.groups_outlined,
      color: AppColors.successGreen,
    );
  }

  Widget _buildTeacherKpi(AsyncValue<Map<String, dynamic>> detailsAsync) {
    if (detailsAsync.isLoading) return AppLoading.card(height: 128);
    if (detailsAsync.hasError) {
      return AppErrorState(message: detailsAsync.error.toString());
    }

    final summary = Map<String, dynamic>.from(
      detailsAsync.valueOrNull?['teacher_attendance'] as Map? ?? {},
    );
    final percent = (summary['value'] as num?)?.toDouble() ?? 0;
    final present = summary['numerator']?.toString() ?? '0';
    final total = summary['denominator']?.toString() ?? '0';

    return _KpiCard(
      title: 'Teacher Attendance',
      value: '${percent.toStringAsFixed(1)}%',
      subtitle: '$present present / $total teachers',
      icon: Icons.co_present_outlined,
      color: AppColors.infoBlue,
    );
  }

  Widget _buildStudentSubjectBreakdown(
    AsyncValue<Map<String, dynamic>> studentDetailsAsync,
  ) {
    if (studentDetailsAsync.isLoading) return AppLoading.card(height: 160);
    if (studentDetailsAsync.hasError) {
      return AppErrorState(message: studentDetailsAsync.error.toString());
    }

    final data = studentDetailsAsync.valueOrNull ?? const <String, dynamic>{};
    final rows = List<Map<String, dynamic>>.from(
      data['attendance_by_subject'] as List? ?? const [],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Attendance by Subject',
            style:
                AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'No student attendance data found for selected filters.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
            )
          else
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (row['subject_name'] ?? 'Subject').toString(),
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    Text(
                      '${((row['percentage'] as num?)?.toDouble() ?? 0).toStringAsFixed(1)}%',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTeacherAttendanceList(
    AsyncValue<Map<String, dynamic>> teacherDetailsAsync,
  ) {
    if (teacherDetailsAsync.isLoading) return AppLoading.card(height: 180);
    if (teacherDetailsAsync.hasError) {
      return AppErrorState(message: teacherDetailsAsync.error.toString());
    }

    final data = teacherDetailsAsync.valueOrNull ?? const <String, dynamic>{};
    final rows = List<Map<String, dynamic>>.from(
      data['teacher_attendance_items'] as List? ?? const [],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teacher Attendance Details',
            style:
                AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Text(
              'No teacher attendance data found for selected filters.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
            )
          else
            ...rows.map(
              (row) {
                final onLeave = row['on_leave'] == true;
                final isPresent = row['is_present'] == true;
                final status =
                    onLeave ? 'On Leave' : (isPresent ? 'Present' : 'Absent');
                final statusColor = onLeave
                    ? AppColors.warningAmber
                    : (isPresent ? AppColors.successGreen : AppColors.errorRed);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (row['teacher_label'] ?? 'Teacher').toString(),
                          style: AppTypography.bodyMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTypography.caption.copyWith(color: AppColors.grey500),
          ),
        ],
      ),
    );
  }
}

class _SnapshotSummaryBar extends StatelessWidget {
  const _SnapshotSummaryBar({required this.snapshot});
  final ClassAttendanceSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SnapStat(
                  value: '${snapshot.present}',
                  label: 'Present',
                  color: AppColors.successGreen),
              _SnapStat(
                  value: '${snapshot.absent}',
                  label: 'Absent',
                  color: AppColors.errorRed),
              _SnapStat(
                  value: '${snapshot.late}',
                  label: 'Late',
                  color: AppColors.warningAmber),
              _SnapStat(
                  value: '${snapshot.notMarked}',
                  label: 'Not Marked',
                  color: AppColors.grey400),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            child: LinearProgressIndicator(
              value: snapshot.presentPercentage / 100,
              backgroundColor: AppColors.white.withValues(alpha: 0.12),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${snapshot.presentPercentage.toStringAsFixed(1)}% present today',
            style: AppTypography.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapStat extends StatelessWidget {
  const _SnapStat(
      {required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTypography.headlineMedium
                .copyWith(color: color, fontWeight: FontWeight.w800)),
        Text(label,
            style: AppTypography.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
    );
  }
}

class _SnapshotRecordTile extends StatelessWidget {
  const _SnapshotRecordTile({
    required this.record,
    required this.isLast,
    this.onTap,
  });
  final ClassSnapshotRecord record;
  final bool isLast;
  final VoidCallback? onTap;

  Color get _statusColor {
    if (record.status == null) return AppColors.grey400;
    switch (record.status!) {
      case AttendanceStatus.present:
        return AppColors.successGreen;
      case AttendanceStatus.absent:
        return AppColors.errorRed;
      case AttendanceStatus.late:
        return AppColors.warningAmber;
    }
  }

  Color get _statusBg {
    if (record.status == null) return AppColors.surface100;
    switch (record.status!) {
      case AttendanceStatus.present:
        return AppColors.successLight;
      case AttendanceStatus.absent:
        return AppColors.errorLight;
      case AttendanceStatus.late:
        return AppColors.warningLight;
    }
  }

  String get _statusLabel {
    if (record.status == null) return 'Not Marked';
    switch (record.status!) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.late:
        return 'Late';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.05),
              blurRadius: 8,
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
                color: AppColors.navyDeep.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  record.admissionNumber.length >= 2
                      ? record.admissionNumber.substring(0, 2).toUpperCase()
                      : record.admissionNumber.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                      color: AppColors.navyMedium, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.admissionNumber,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w600)),
                  if (record.rollNumber != null &&
                      record.rollNumber!.trim().isNotEmpty)
                    Text('Roll ${record.rollNumber}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey500)),
                  if (record.section.isNotEmpty)
                    Text('Sec ${record.section}',
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey400)),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: AppTypography.labelSmall.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11)),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded,
                      size: 16, color: AppColors.grey400),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
      filled: true,
      fillColor: AppColors.surface50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.surface200, width: 1.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.surface200, width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.navyMedium, width: 1.5)),
    );
