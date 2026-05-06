// 🆕 NEW FILE
// lib/presentation/my_class/screens/subject_list_screen.dart  [Mobile App]
// My Class — Subject List (entry point for STUDENT and PARENT).
//
// Shows all subjects with teacher assignments for the student's enrolled
// class/section/year.  Each subject card navigates to its chapter list.
//
// Academic Year dropdown defaults to current year.
// Past years: subjects shown read-only (no quiz attempt allowed — enforced downstream).
//
// APIs used:
//   GET /my-class/subjects?standard_id=&section_id=&academic_year_id=&child_id=
//   GET /academic-years

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/network/dio_client.dart';
import '../../../data/models/my_class/my_class_models.dart';
import '../../../providers/my_class_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import 'chapter_list_screen.dart';

// ── Academic year model ───────────────────────────────────────────────────────

class _AcademicYear {
  const _AcademicYear({
    required this.id,
    required this.name,
    required this.isActive,
  });
  final String id;
  final String name;
  final bool isActive;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class MyClassSubjectListScreen extends ConsumerStatefulWidget {
  const MyClassSubjectListScreen({
    super.key,
    // For PARENT: childId is the linked student's ID
    this.childId,
    // Pre-filled from student profile (student's own class/section/year)
    this.initialStandardId,
    this.initialSectionId,
    this.initialSectionName,
    this.initialAcademicYearId,
  });

  final String? childId;
  final String? initialStandardId;
  final String? initialSectionId;
  final String? initialSectionName;
  final String? initialAcademicYearId;

  @override
  ConsumerState<MyClassSubjectListScreen> createState() =>
      _MyClassSubjectListScreenState();
}

class _MyClassSubjectListScreenState
    extends ConsumerState<MyClassSubjectListScreen> {
  List<_AcademicYear> _years = [];
  _AcademicYear? _selectedYear;
  bool _loadingYears = true;
  String? _resolvedStandardId;
  String? _resolvedAcademicYearId;
  String? _resolvedSectionName;
  String? _resolvedSectionId;

  @override
  void initState() {
    super.initState();
    _resolvedStandardId = widget.initialStandardId;
    _resolvedAcademicYearId = widget.initialAcademicYearId;
    _resolvedSectionName = widget.initialSectionName;
    _resolveStudentContextIfNeeded().whenComplete(_loadYears);
  }

  Future<void> _resolveStudentContextIfNeeded() async {
    if ((_resolvedStandardId ?? '').isNotEmpty &&
        (_resolvedAcademicYearId ?? '').isNotEmpty &&
        (_resolvedSectionName ?? '').isNotEmpty) {
      return;
    }
    if (widget.childId != null) return;
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(ApiConstants.studentsMe);
      final raw =
          (resp.data?['data'] as Map<String, dynamic>?) ?? resp.data ?? {};
      if (!mounted) return;
      setState(() {
        _resolvedStandardId =
            _resolvedStandardId ?? raw['standard_id']?.toString();
        _resolvedAcademicYearId =
            _resolvedAcademicYearId ?? raw['academic_year_id']?.toString();
        _resolvedSectionName =
            _resolvedSectionName ?? raw['section']?.toString();
      });
    } catch (_) {
      // Keep existing values; UI will show a clear message if still unresolved.
    }
  }

  Future<void> _loadYears() async {
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(ApiConstants.academicYears);
      final raw = resp.data?['data'] ?? resp.data;
      final items = (raw?['items'] as List?) ?? (raw as List?) ?? [];
      final years = items
          .map((e) => _AcademicYear(
                id: e['id']?.toString() ?? '',
                name: e['name']?.toString() ?? '',
                isActive: e['is_active'] as bool? ?? false,
              ))
          .toList();

      if (mounted) {
        setState(() {
          _years = years;
          // Default to current year or pre-filled
          final prefilledId = _resolvedAcademicYearId;
          _selectedYear = years.firstWhere(
            (y) => prefilledId != null ? y.id == prefilledId : y.isActive,
            orElse: () => years.isNotEmpty
                ? years.first
                : const _AcademicYear(id: '', name: '', isActive: false),
          );
          _loadingYears = false;
          _resolvedSectionId = widget.initialSectionId;
        });
        await _resolveSectionIdIfNeeded(_selectedYear?.id ?? '');
      }
    } catch (_) {
      if (mounted) setState(() => _loadingYears = false);
    }
  }

  Future<void> _resolveSectionIdIfNeeded(String yearId) async {
    if ((widget.initialSectionId ?? '').isNotEmpty) {
      _resolvedSectionId = widget.initialSectionId;
      return;
    }

    final standardId = _resolvedStandardId ?? '';
    final sectionName = (_resolvedSectionName ?? '').trim();
    if (standardId.isEmpty || sectionName.isEmpty || yearId.isEmpty) {
      return;
    }

    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(
        ApiConstants.mastersSections,
        queryParameters: {
          'standard_id': standardId,
          'academic_year_id': yearId,
          'name': sectionName,
        },
      );
      final raw = resp.data?['data'] ?? resp.data;
      final items = (raw?['items'] as List?) ?? (raw is List ? raw : []);
      for (final item in items) {
        final itemName = (item['name']?.toString() ?? '').trim().toUpperCase();
        if (itemName == sectionName.toUpperCase()) {
          _resolvedSectionId = item['id']?.toString();
          break;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {
      // keep unresolved; UI will show empty-state until context is available
    }
  }

  bool get _isCurrentYear => _selectedYear?.isActive == true;

  @override
  Widget build(BuildContext context) {
    final standardId = _resolvedStandardId ?? '';
    final sectionId = widget.initialSectionId ?? _resolvedSectionId ?? '';
    final yearId = _selectedYear?.id ?? '';

    final hasContext =
        standardId.isNotEmpty && sectionId.isNotEmpty && yearId.isNotEmpty;
    final subjectsAsync = hasContext
        ? ref.watch(myClassSubjectsProvider((
            standardId: standardId,
            sectionId: sectionId,
            academicYearId: yearId,
            childId: widget.childId,
          )))
        : const AsyncValue<List<SubjectSummary>>.data(<SubjectSummary>[]);

    final selectedYearValue =
        _years.any((y) => y.id == _selectedYear?.id) ? _selectedYear : null;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'My Class',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
        actions: [
          if (!_loadingYears && _years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 2, bottom: 2),
              child: Center(
                child: SizedBox(
                  height: 40,
                  child: DropdownButton<_AcademicYear>(
                    value: selectedYearValue,
                    isDense: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.white,
                    iconEnabledColor: AppColors.white,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _years
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(
                                y.name,
                                style: AppTypography.bodySmall.copyWith(
                                  color: y.isActive
                                      ? AppColors.navyMedium
                                      : AppColors.grey500,
                                ),
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: (context) => _years
                        .map(
                          (y) => Text(
                            y.name,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (y) async {
                      if (y != null) {
                        setState(() {
                          _selectedYear = y;
                          if ((widget.initialSectionId ?? '').isEmpty) {
                            _resolvedSectionId = null;
                          }
                        });
                        await _resolveSectionIdIfNeeded(y.id);
                      }
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (!_isCurrentYear)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.warningAmber.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline,
                      size: 14, color: AppColors.warningAmber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Past year — read-only. Quizzes cannot be attempted.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.warningAmber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: !hasContext
                ? Center(
                    child: Text(
                      'Classroom is not available yet.\nClass/section/year assignment is missing.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  )
                : subjectsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        e.toString(),
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.errorRed),
                      ),
                    ),
                    data: (subjects) {
                      if (subjects.isEmpty) {
                        return Center(
                          child: Text(
                            'No subjects found for this class and year.',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.grey500),
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(myClassSubjectsProvider);
                        },
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: subjects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => _SubjectCard(
                            subject: subjects[i],
                            isReadOnly: !_isCurrentYear,
                            childId: widget.childId,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({
    required this.subject,
    required this.isReadOnly,
    this.childId,
  });

  final SubjectSummary subject;
  final bool isReadOnly;
  final String? childId;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChapterListScreen(
                subject: subject,
                isReadOnly: isReadOnly,
                childId: childId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navyMedium.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined,
                    color: AppColors.navyMedium, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.subjectName,
                        style: AppTypography.labelLarge
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    if (subject.teacherName != null)
                      Text(subject.teacherName!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey500)),
                    Text(
                      '${subject.chapterCount} chapter${subject.chapterCount == 1 ? '' : 's'}',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.grey400),
            ],
          ),
        ),
      ),
    );
  }
}
