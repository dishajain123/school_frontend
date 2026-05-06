import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/timetable_hub_ui_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/timetable_placeholder.dart';
import '../widgets/timetable_viewer.dart';

/// School registry (admin) + any section keys from existing timetable rows.
List<String> _mergeRegistryAndTimetableSections(
  List<String> registry,
  List<String> fromTimetable,
) {
  final out = <String>[];
  bool has(String x) =>
      out.any((e) => e.toUpperCase() == x.trim().toUpperCase());
  for (final s in registry) {
    final t = s.trim();
    if (t.isNotEmpty && !has(t)) out.add(t);
  }
  for (final s in fromTimetable) {
    final t = s.trim();
    if (t.isNotEmpty && !has(t)) out.add(t);
  }
  out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return out;
}

/// Teachers only see sections they are assigned to for the selected class;
/// assignment labels are included even if the registry list lags.
List<String> _sectionsForTeacher(
  List<String> mergedSchoolSections,
  List<TeacherClassSubjectModel> assignments,
  String standardId,
) {
  final allowedRaw = assignments
      .where((a) => a.standardId == standardId)
      .map((a) => a.section.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (allowedRaw.isEmpty) return const [];

  final out = <String>[];
  void addDistinct(String s) {
    final t = s.trim();
    if (t.isEmpty) {
      return;
    }
    if (!allowedRaw.any((a) => a.toUpperCase() == t.toUpperCase())) {
      return;
    }
    if (!out.any((e) => e.toUpperCase() == t.toUpperCase())) {
      out.add(t);
    }
  }

  for (final s in mergedSchoolSections) {
    addDistinct(s);
  }
  for (final a in allowedRaw) {
    addDistinct(a);
  }
  out.sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
  return out;
}

String? _canonicalSectionPickerValue(
  String? selected,
  List<String> options,
) {
  if (selected == null || selected.trim().isEmpty) return null;
  final want = selected.trim();
  for (final o in options) {
    if (o.toUpperCase() == want.toUpperCase()) return o;
  }
  return null;
}

final _myStudentProfileProvider =
    FutureProvider.autoDispose<StudentModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.read(studentRepositoryProvider);
  try {
    return await repo.getMyProfile();
  } catch (_) {
    return await ref.read(studentNotifierProvider.notifier).getById(user.id);
  }
});

class TimetableViewScreen extends ConsumerWidget {
  /// Pass [standardId] to view a specific class (PRINCIPAL/TEACHER use case).
  /// When null the screen resolves standardId from the viewer's role context.
  /// [academicYearId] (e.g. from exam deep-link) overrides active academic year.
  const TimetableViewScreen({
    super.key,
    this.standardId,
    this.section,
    this.academicYearId,
    this.embedInHub = false,
  });

  final String? standardId;
  final String? section;
  final String? academicYearId;

  /// When [true], rendered inside [TimetableHubScreen] without a duplicate app bar.
  final bool embedInHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final resolvedYearId = (academicYearId != null &&
            academicYearId!.trim().isNotEmpty)
        ? academicYearId!.trim()
        : activeYear?.id;
    final canUpload = currentUser != null &&
        (currentUser.role.isSchoolScopedAdmin ||
            currentUser.role == UserRole.teacher);

    if (currentUser == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Timetable', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // STUDENT — scope to own standard
    if (currentUser.role == UserRole.student) {
      return _StudentTimetableView(
        academicYearId: resolvedYearId,
        embedInHub: embedInHub,
      );
    }

    // PARENT — scope to selected child's class/section
    if (currentUser.role == UserRole.parent) {
      return _ParentTimetableView(
        section: section,
        academicYearId: resolvedYearId,
        embedInHub: embedInHub,
      );
    }

    return _AdminTimetableView(
      initialStandardId: standardId,
      initialSection: section,
      academicYearId: resolvedYearId,
      canUpload: canUpload,
      embedInHub: embedInHub,
    );
  }
}

class _AdminTimetableView extends ConsumerStatefulWidget {
  const _AdminTimetableView({
    required this.academicYearId,
    required this.canUpload,
    this.initialStandardId,
    this.initialSection,
    this.embedInHub = false,
  });

  final String? initialStandardId;
  final String? initialSection;
  final String? academicYearId;
  final bool canUpload;
  final bool embedInHub;

  @override
  ConsumerState<_AdminTimetableView> createState() =>
      _AdminTimetableViewState();
}

class _AdminTimetableViewState extends ConsumerState<_AdminTimetableView> {
  String? _selectedStandardId;
  String? _selectedSection;
  String? _loadedStandardId;
  String? _loadedSection;

  @override
  void initState() {
    super.initState();
    _selectedStandardId = widget.initialStandardId;
    _selectedSection = widget.initialSection;
    _loadedStandardId = widget.initialStandardId;
    _loadedSection = widget.initialSection;
  }

  void _loadTimetable() {
    if (_selectedStandardId == null || _selectedStandardId!.isEmpty) return;
    setState(() {
      _loadedStandardId = _selectedStandardId;
      _loadedSection = _selectedSection;
    });
  }

  @override
  Widget build(BuildContext context) {
    final standardsAsync = ref.watch(standardsProvider(widget.academicYearId));
    final currentUser = ref.watch(currentUserProvider);
    final isTeacher = currentUser?.role == UserRole.teacher;
    final teacherAssignmentsAsync = isTeacher
        ? ref.watch(teacherAssignmentsByTeacherProvider(currentUser!.id))
        : const AsyncData<List<TeacherClassSubjectModel>>(
            <TeacherClassSubjectModel>[],
          );
    final registryAsync = _selectedStandardId == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(
            sectionsByStandardProvider((
              standardId: _selectedStandardId,
              academicYearId: widget.academicYearId,
            )),
          );
    final timetableSecAsync = _selectedStandardId == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(
            timetableSectionsProvider((
              standardId: _selectedStandardId!,
              academicYearId: widget.academicYearId,
            )),
          );

    if (widget.embedInHub) {
      final next = TimetableHubClassActions(
        academicYearId: widget.academicYearId,
        canUpload: widget.canUpload,
        selectedStandardId: _selectedStandardId,
        selectedSection: _selectedSection,
        loadedStandardId: _loadedStandardId,
        loadedSection: _loadedSection,
      );
      if (next != ref.read(timetableHubClassActionsProvider)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(timetableHubClassActionsProvider.notifier).state = next;
        });
      }
    }

    final bodyColumn = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space12,
            ),
            child: Column(
              children: [
                standardsAsync.when(
                  loading: () => AppLoading.card(height: 52),
                  error: (e, _) => _FilterError(message: e.toString()),
                  data: (standards) {
                    if (currentUser?.role == UserRole.teacher) {
                      return teacherAssignmentsAsync.when(
                        loading: () => AppLoading.card(height: 52),
                        error: (e, _) => _FilterError(message: e.toString()),
                        data: (assignments) {
                          final allowedStandardIds =
                              assignments.map((a) => a.standardId).toSet();
                          final allowedStandards = standards
                              .where((s) => allowedStandardIds.contains(s.id))
                              .toList();
                          final safeValue =
                              allowedStandardIds.contains(_selectedStandardId)
                                  ? _selectedStandardId
                                  : null;
                          return _ClassFilterField(
                            standards: allowedStandards,
                            value: safeValue,
                            onChanged: (value) {
                              setState(() {
                                _selectedStandardId = value;
                                _selectedSection = null;
                              });
                            },
                          );
                        },
                      );
                    }
                    return _ClassFilterField(
                      standards: standards,
                      value: _selectedStandardId,
                      onChanged: (value) {
                        setState(() {
                          _selectedStandardId = value;
                          _selectedSection = null;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                registryAsync.when(
                  loading: () => AppLoading.card(height: 52),
                  error: (e, _) => _FilterError(
                    message: 'Could not load sections: $e',
                  ),
                  data: (registry) {
                    final fromTt =
                        timetableSecAsync.valueOrNull ?? const <String>[];
                    final merged =
                        _mergeRegistryAndTimetableSections(registry, fromTt);
                    if (isTeacher) {
                      return teacherAssignmentsAsync.when(
                        loading: () => AppLoading.card(height: 52),
                        error: (e, _) => _FilterError(message: e.toString()),
                        data: (assignments) {
                          final sid = _selectedStandardId;
                          if (sid == null || sid.isEmpty) {
                            return _SectionFilterField(
                              sections: const [],
                              value: null,
                              enabled: false,
                              onChanged: (_) {},
                            );
                          }
                          final sections = _sectionsForTeacher(
                            merged,
                            assignments,
                            sid,
                          );
                          final safe = _canonicalSectionPickerValue(
                            _selectedSection,
                            sections,
                          );
                          return _SectionFilterField(
                            sections: sections,
                            value: safe,
                            enabled: true,
                            onChanged: (value) =>
                                setState(() => _selectedSection = value),
                          );
                        },
                      );
                    }
                    final safe = _canonicalSectionPickerValue(
                      _selectedSection,
                      merged,
                    );
                    return _SectionFilterField(
                      sections: merged,
                      value: safe,
                      enabled: _selectedStandardId != null,
                      onChanged: (value) =>
                          setState(() => _selectedSection = value),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.space12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed:
                        _selectedStandardId == null ? null : _loadTimetable,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.navyDeep,
                      foregroundColor: AppColors.white,
                    ),
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Load Timetable'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loadedStandardId == null
                ? const AppEmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'Select Class',
                    subtitle:
                        'Choose class and section filter to view timetable.',
                  )
                : _TimetableDataBody(
                    standardId: _loadedStandardId!,
                    section: _loadedSection,
                    academicYearId: widget.academicYearId,
                    canUpload: widget.canUpload,
                  ),
          ),
        ],
    );

    if (widget.embedInHub) {
      return bodyColumn;
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Timetable',
        showBack: true,
        actions: [
          if (_loadedStandardId != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(
                  timetableProvider((
                    standardId: _loadedStandardId!,
                    academicYearId: widget.academicYearId,
                    section: _loadedSection,
                    examId: null,
                  )),
                );
              },
            ),
          if (widget.canUpload)
            IconButton(
              icon: const Icon(Icons.upload_file_outlined,
                  color: AppColors.white),
              tooltip: 'Upload timetable',
              onPressed: () async {
                final uri = Uri(
                  path: '/timetable/upload',
                  queryParameters: {
                    if (_selectedStandardId != null)
                      'standard_id': _selectedStandardId!,
                    if (_selectedSection != null &&
                        _selectedSection!.trim().isNotEmpty)
                      'section': _selectedSection!,
                  },
                );
                await context.push(uri.toString());
                if (_loadedStandardId != null) {
                  ref.invalidate(
                    timetableProvider((
                      standardId: _loadedStandardId!,
                      academicYearId: widget.academicYearId,
                      section: _loadedSection,
                      examId: null,
                    )),
                  );
                }
              },
            ),
          if (widget.canUpload && _loadedStandardId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.white),
              tooltip: 'Remove timetable',
              onPressed: () async {
                final standardId = _loadedStandardId;
                if (standardId == null) return;

                final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Remove timetable?'),
                        content: Text(
                          _loadedSection == null || _loadedSection!.isEmpty
                              ? 'This will remove the class timetable for the selected academic year.'
                              : 'This will remove timetable for section ${_loadedSection!}.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.errorRed,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (!confirm) return;

                final success =
                    await ref.read(timetableDeleteProvider.notifier).delete(
                          standardId: standardId,
                          academicYearId: widget.academicYearId,
                          section: _loadedSection,
                          examId: null,
                        );
                if (!context.mounted) return;

                if (success) {
                  SnackbarUtils.showSuccess(context, 'Timetable removed');
                  ref.invalidate(
                    timetableProvider((
                      standardId: standardId,
                      academicYearId: widget.academicYearId,
                      section: _loadedSection,
                      examId: null,
                    )),
                  );
                } else {
                  final error = ref.read(timetableDeleteProvider).error;
                  SnackbarUtils.showError(
                    context,
                    error ?? 'Failed to remove timetable',
                  );
                }
              },
            ),
        ],
      ),
      body: bodyColumn,
    );
  }
}

// ── Student-scoped view ───────────────────────────────────────────────────────

class _StudentTimetableView extends ConsumerWidget {
  const _StudentTimetableView({
    this.academicYearId,
    this.embedInHub = false,
  });
  final String? academicYearId;
  final bool embedInHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(_myStudentProfileProvider);

    return studentAsync.when(
      loading: () => embedInHub
          ? AppLoading.fullPage()
          : AppScaffold(
              appBar: const AppAppBar(title: 'Timetable', showBack: true),
              body: AppLoading.fullPage(),
            ),
      error: (e, _) => embedInHub
          ? AppErrorState(
              message: e.toString(),
              onRetry: () => ref.invalidate(_myStudentProfileProvider),
            )
          : AppScaffold(
              appBar: const AppAppBar(title: 'Timetable', showBack: true),
              body: AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(_myStudentProfileProvider),
              ),
            ),
      data: (student) {
        if (student == null) {
          return embedInHub
              ? const AppEmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Class not found',
                  subtitle:
                      'Your class information is not available yet.',
                )
              : const AppScaffold(
                  appBar: AppAppBar(title: 'Timetable', showBack: true),
                  body: AppEmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'Class not found',
                    subtitle:
                        'Your class information is not available yet.',
                  ),
                );
        }
        if (student.standardId == null) {
          return embedInHub
              ? const AppEmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Class not found',
                  subtitle:
                      'Your class information is not available yet.',
                )
              : const AppScaffold(
                  appBar: AppAppBar(title: 'Timetable', showBack: true),
                  body: AppEmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'Class not found',
                    subtitle:
                        'Your class information is not available yet.',
                  ),
                );
        }
        final studentSection = student.section?.trim();
        if (studentSection == null || studentSection.isEmpty) {
          return embedInHub
              ? const AppEmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'Section not assigned',
                  subtitle:
                      'Your section is not assigned yet, so timetable cannot be shown.',
                )
              : const AppScaffold(
                  appBar: AppAppBar(title: 'Timetable', showBack: true),
                  body: AppEmptyState(
                    icon: Icons.schedule_outlined,
                    title: 'Section not assigned',
                    subtitle:
                        'Your section is not assigned yet, so timetable cannot be shown.',
                  ),
                );
        }
        return _TimetableContent(
          standardId: student.standardId!,
          section: studentSection,
          academicYearId: academicYearId,
          embedInHub: embedInHub,
        );
      },
    );
  }
}

// ── Parent-scoped view ────────────────────────────────────────────────────────

class _ParentTimetableView extends ConsumerWidget {
  const _ParentTimetableView({
    this.section,
    this.academicYearId,
    this.embedInHub = false,
  });
  final String? section;
  final String? academicYearId;
  final bool embedInHub;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedChild = ref.watch(selectedChildProvider);

    if (selectedChild == null) {
      return embedInHub
          ? const AppEmptyState(
              icon: Icons.schedule_outlined,
              title: 'No child selected',
              subtitle:
                  'Select a linked child from dashboard to view their timetable.',
            )
          : const AppScaffold(
              appBar: AppAppBar(title: 'Timetable', showBack: true),
              body: AppEmptyState(
                icon: Icons.schedule_outlined,
                title: 'No child selected',
                subtitle:
                    'Select a linked child from dashboard to view their timetable.',
              ),
            );
    }

    if (selectedChild.standardId == null) {
      return embedInHub
          ? const AppEmptyState(
              icon: Icons.schedule_outlined,
              title: 'Class not found',
              subtitle: 'Child class information is not available yet.',
            )
          : const AppScaffold(
              appBar: AppAppBar(title: 'Timetable', showBack: true),
              body: AppEmptyState(
                icon: Icons.schedule_outlined,
                title: 'Class not found',
                subtitle: 'Child class information is not available yet.',
              ),
            );
    }

    return _TimetableContent(
      standardId: selectedChild.standardId!,
      section: section ?? selectedChild.section,
      academicYearId: academicYearId,
      embedInHub: embedInHub,
    );
  }
}

// ── Core timetable content ────────────────────────────────────────────────────

class _TimetableContent extends ConsumerWidget {
  const _TimetableContent({
    required this.standardId,
    this.section,
    this.academicYearId,
    this.embedInHub = false,
  });

  final String standardId;
  final String? section;
  final String? academicYearId;
  final bool embedInHub;

  TimetableParams get _params => (
        standardId: standardId,
        academicYearId: academicYearId,
        section: section,
        examId: null,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final canUpload = currentUser != null &&
        (currentUser.role.isSchoolScopedAdmin ||
            currentUser.role == UserRole.teacher);
    final dataBody = _TimetableDataBody(
      standardId: standardId,
      section: section,
      academicYearId: academicYearId,
      canUpload: canUpload,
    );

    if (embedInHub) {
      return dataBody;
    }

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Timetable',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(timetableProvider(_params)),
          ),
          if (canUpload)
            IconButton(
              icon: const Icon(Icons.upload_file_outlined,
                  color: AppColors.white),
              tooltip: 'Upload new timetable',
              onPressed: () async {
                final uploaded = await context.push<bool>('/timetable/upload');
                if (uploaded == true) {
                  ref.invalidate(timetableProvider(_params));
                }
              },
            ),
        ],
      ),
      body: dataBody,
    );
  }
}

/// Scrollable content with at least the viewport height so empty/error UIs
/// do not cause bottom overflow inside hub [Expanded] + bottom navigation.
class _ScrollableMinHeight extends StatelessWidget {
  const _ScrollableMinHeight({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class _TimetableDataBody extends ConsumerWidget {
  const _TimetableDataBody({
    required this.standardId,
    required this.academicYearId,
    required this.canUpload,
    this.section,
  });

  final String standardId;
  final String? section;
  final String? academicYearId;
  final bool canUpload;

  TimetableParams get _params => (
        standardId: standardId,
        academicYearId: academicYearId,
        section: section,
        examId: null,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableProvider(_params));
    return timetableAsync.when(
      loading: () => AppLoading.fullPage(),
      error: (e, _) {
        final msg = e.toString();
        if (msg.contains('404') ||
            msg.toLowerCase().contains('timetable') ||
            msg.contains('Not Found')) {
          return _ScrollableMinHeight(
            child: TimetablePlaceholder(
              canUpload: canUpload,
            ),
          );
        }
        return _ScrollableMinHeight(
          child: AppErrorState(
            message: msg,
            onRetry: () => ref.invalidate(timetableProvider(_params)),
          ),
        );
      },
      data: (timetable) {
        if (timetable.fileUrl == null) {
          return _ScrollableMinHeight(
            child: TimetablePlaceholder(
              canUpload: canUpload,
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.pageHorizontal,
          ),
          child: Column(
            children: [
              _TimetableMetaBar(timetable: timetable),
              Expanded(
                child: TimetableViewer(timetable: timetable),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClassFilterField extends StatelessWidget {
  const _ClassFilterField({
    required this.standards,
    required this.value,
    required this.onChanged,
  });

  final List<StandardModel> standards;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(
            'Select class',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey400),
          onChanged: onChanged,
          items: standards
              .map(
                (s) => DropdownMenuItem<String>(
                  value: s.id,
                  child: Text(
                    s.name,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.grey800),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _SectionFilterField extends StatelessWidget {
  const _SectionFilterField({
    required this.sections,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> sections;
  final String? value;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface50 : AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          isExpanded: true,
          hint: Text(
            enabled ? 'All sections' : 'Select class first',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey400),
          onChanged: enabled ? onChanged : null,
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                'All sections',
                style:
                    AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
              ),
            ),
            ...sections.map(
              (section) => DropdownMenuItem<String?>(
                value: section,
                child: Text(
                  section,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.grey800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterError extends StatelessWidget {
  const _FilterError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.errorRed),
      ),
      child: Text(
        message,
        style: AppTypography.bodySmall.copyWith(color: AppColors.errorDark),
      ),
    );
  }
}

// ── Meta info strip ───────────────────────────────────────────────────────────

class _TimetableMetaBar extends StatelessWidget {
  const _TimetableMetaBar({required this.timetable});
  final TimetableModel timetable;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          // File type icon badge
          Container(
            padding: const EdgeInsets.all(AppDimensions.space8),
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              timetable.isPdf
                  ? Icons.picture_as_pdf_outlined
                  : Icons.image_outlined,
              size: 18,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          // File name + effective date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timetable.fileName,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timetable.effectiveFrom != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'From ${DateFormatter.formatDate(timetable.effectiveFrom!)}',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Text(
            DateFormatter.formatRelative(timetable.updatedAt),
            style: AppTypography.caption.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}
