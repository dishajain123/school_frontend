// lib/presentation/my_class/screens/classroom_monitor_screen.dart
// Principal/Trustee: view all classroom content posted by teachers.
// Filters: Academic Year → Class → Section → Subject
// Shows: chapters, topics, content items with teacher info.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import 'subject_list_screen.dart';

class _Opt {
  const _Opt({required this.id, required this.name});
  final String id;
  final String name;
}

class _SubjectInfo {
  const _SubjectInfo({
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.teacherName,
    required this.teacherId,
    required this.chapterCount,
    required this.topicCount,
    required this.contentCount,
  });
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final String teacherName;
  final String teacherId;
  final int chapterCount;
  final int topicCount;
  final int contentCount;

  factory _SubjectInfo.fromJson(Map<String, dynamic> json) {
    final teacher = json['teacher'] as Map<String, dynamic>? ?? {};
    return _SubjectInfo(
      subjectId: json['subject_id']?.toString() ?? '',
      subjectName: json['subject_name']?.toString() ?? '',
      subjectCode: json['subject_code']?.toString() ?? '',
      teacherName: teacher['name']?.toString() ?? 'Unassigned',
      teacherId: teacher['id']?.toString() ?? '',
      chapterCount: (json['chapter_count'] as num?)?.toInt() ?? 0,
      topicCount: (json['topic_count'] as num?)?.toInt() ?? 0,
      contentCount: (json['content_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ClassroomMonitorScreen extends ConsumerStatefulWidget {
  const ClassroomMonitorScreen({super.key});

  @override
  ConsumerState<ClassroomMonitorScreen> createState() =>
      _ClassroomMonitorScreenState();
}

class _ClassroomMonitorScreenState
    extends ConsumerState<ClassroomMonitorScreen> {
  bool _loading = true;
  String? _error;

  List<_Opt> _years = [];
  List<_Opt> _standards = [];
  List<_Opt> _sections = [];

  _Opt? _year;
  _Opt? _standard;
  _Opt? _section;

  List<_SubjectInfo> _subjects = [];
  bool _loadingSubjects = false;
  String? _subjectsError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioClientProvider);
      final yearsResp = await dio.get<Map<String, dynamic>>('/academic-years');
      final standardsResp =
          await dio.get<Map<String, dynamic>>('/masters/standards');

      final yearsRaw = yearsResp.data?['data'] ?? yearsResp.data;
      final yearsItems = (yearsRaw?['items'] as List?) ?? [];
      final standardsRaw = standardsResp.data?['data'] ?? standardsResp.data;
      final standardsItems = (standardsRaw?['items'] as List?) ?? [];

      final years = yearsItems
          .map((e) => _Opt(id: e['id'].toString(), name: e['name'].toString()))
          .toList();
      final standards = standardsItems
          .map((e) => _Opt(id: e['id'].toString(), name: e['name'].toString()))
          .toList();

      // Default to active year
      final activeYear = yearsItems.firstWhere(
        (y) => y['is_active'] == true,
        orElse: () => yearsItems.isNotEmpty ? yearsItems.first : null,
      );

      setState(() {
        _years = years;
        _standards = standards;
        _year = activeYear != null
            ? _Opt(
                id: activeYear['id'].toString(),
                name: activeYear['name'].toString())
            : (years.isNotEmpty ? years.first : null);
        _standard = standards.isNotEmpty ? standards.first : null;
        _loading = false;
      });
      await _loadSections();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadSections() async {
    if (_standard == null || _year == null) return;
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(
        '/masters/sections',
        queryParameters: {
          'standard_id': _standard!.id,
          'academic_year_id': _year!.id,
        },
      );
      final raw = resp.data?['data'] ?? resp.data;
      final items = (raw?['items'] as List?) ?? [];
      final sections = items
          .map((e) => _Opt(id: e['id'].toString(), name: e['name'].toString()))
          .toList();
      setState(() {
        _sections = sections;
        _section = sections.isNotEmpty ? sections.first : null;
      });
      if (_section != null) {
        await _loadSubjects();
      }
    } catch (_) {}
  }

  Future<void> _loadSubjects() async {
    if (_year == null || _standard == null || _section == null) return;
    setState(() {
      _loadingSubjects = true;
      _subjectsError = null;
      _subjects = [];
    });
    try {
      final dio = ref.read(dioClientProvider);
      final resp = await dio.get<Map<String, dynamic>>(
        '/my-class/subjects',
        queryParameters: {
          'standard_id': _standard!.id,
          'section_id': _section!.id,
          'academic_year_id': _year!.id,
        },
      );
      final raw = resp.data?['data'] ?? resp.data;
      final items = (raw?['subjects'] as List?) ??
          (raw?['items'] as List?) ??
          (raw as List?) ??
          [];
      final subjects = items
          .map(
              (e) => _SubjectInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      setState(() {
        _subjects = subjects;
        _loadingSubjects = false;
      });
    } catch (e) {
      setState(() {
        _subjectsError = e.toString();
        _loadingSubjects = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(
          title: 'Classroom Monitor',
          showBack: true,
          onBackPressed: () => context.go(RouteNames.dashboard),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(
          title: 'Classroom Monitor',
          showBack: true,
          onBackPressed: () => context.go(RouteNames.dashboard),
        ),
        body: AppErrorState(message: _error!, onRetry: _init),
      );
    }

    _Opt? findSelected(List<_Opt> options, _Opt? current) {
      if (current == null) return null;
      for (final option in options) {
        if (option.id == current.id) return option;
      }
      return null;
    }

    final yearValue = findSelected(_years, _year);
    final standardValue = findSelected(_standards, _standard);
    final sectionValue = findSelected(_sections, _section);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Classroom Monitor',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
      ),
      body: Column(
        children: [
          // ── Filters ──────────────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_Opt>(
                        value: yearValue,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        items: _years
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _year = v);
                          await _loadSections();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<_Opt>(
                        value: standardValue,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        items: _standards
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _standard = v);
                          await _loadSections();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<_Opt>(
                        value: sectionValue,
                        decoration: const InputDecoration(
                          labelText: 'Section',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        items: _sections
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)))
                            .toList(),
                        onChanged: (v) async {
                          setState(() => _section = v);
                          await _loadSubjects();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Subject list ──────────────────────────────────────────────
          Expanded(
            child: _buildSubjectList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList() {
    if (_loadingSubjects) return AppLoading.fullPage();

    if (_subjectsError != null) {
      return AppErrorState(
        message: _subjectsError!,
        onRetry: _loadSubjects,
      );
    }

    if (_year == null || _standard == null || _section == null) {
      return const AppEmptyState(
        icon: Icons.filter_list_outlined,
        title: 'Select filters',
        subtitle: 'Choose academic year, class, and section to view content.',
      );
    }

    if (_subjects.isEmpty) {
      return const AppEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No subjects found',
        subtitle: 'No subjects have been assigned for this class/section yet.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSubjects,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _subjects.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _SubjectCard(
          subject: _subjects[i],
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MyClassSubjectListScreen(
                  initialAcademicYearId: _year!.id,
                  initialStandardId: _standard!.id,
                  initialSectionId: _section!.id,
                  initialSectionName: _section!.name,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Subject Card ──────────────────────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});
  final _SubjectInfo subject;
  final VoidCallback onTap;

  static const _subjectColors = [
    Color(0xFF1565C0),
    Color(0xFF2E7D32),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF283593),
    Color(0xFF4E342E),
  ];

  Color _colorForSubject(String name) {
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _subjectColors.length;
    return _subjectColors[idx];
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForSubject(subject.subjectName);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Subject icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  subject.subjectCode.isNotEmpty
                      ? subject.subjectCode.substring(
                          0,
                          subject.subjectCode.length > 3
                              ? 3
                              : subject.subjectCode.length)
                      : subject.subjectName.substring(0, 1),
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.subjectName,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 13, color: AppColors.grey500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subject.teacherName,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _ContentStat(
                        icon: Icons.book_outlined,
                        value: '${subject.chapterCount}',
                        label: 'Chapters',
                        color: color,
                      ),
                      const SizedBox(width: 12),
                      _ContentStat(
                        icon: Icons.topic_outlined,
                        value: '${subject.topicCount}',
                        label: 'Topics',
                        color: color,
                      ),
                      const SizedBox(width: 12),
                      _ContentStat(
                        icon: Icons.attach_file_outlined,
                        value: '${subject.contentCount}',
                        label: 'Content',
                        color: color,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AppColors.grey400, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ContentStat extends StatelessWidget {
  const _ContentStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          '$value $label',
          style: AppTypography.caption.copyWith(
            color: AppColors.grey500,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
