// lib/presentation/teacher_schedule/screens/teacher_schedule_screen.dart  [Mobile App]
// Phase 4 / 14 — Teacher Class Schedule / My Assignments.
// Shows a teacher their current academic year class-subject-section assignments.
// This directly reflects whatever the admin has assigned via the admin console.
// When admin changes a teacher's assignment, the teacher sees the updated data
// immediately on next load (no caching). Mobile app is READ-ONLY here.
//
// APIs used:
//   GET /teacher-assignments/mine?academic_year_id={id}
//   GET /academic-years
//
// Navigation: context.push('/my-schedule');

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

// ── Models ────────────────────────────────────────────────────────────────────

class _ClassAssignment {
  const _ClassAssignment({
    required this.id,
    required this.standardName,
    required this.standardLevel,
    required this.section,
    required this.subjectName,
    required this.subjectCode,
    required this.academicYearName,
    required this.academicYearId,
    required this.updatedAt,
  });

  final String id;
  final String standardName;
  final int standardLevel;
  final String section;
  final String subjectName;
  final String subjectCode;
  final String academicYearName;
  final String academicYearId;
  final String updatedAt;

  factory _ClassAssignment.fromJson(Map<String, dynamic> j) => _ClassAssignment(
        id: j['id']?.toString() ?? '',
        standardName: j['standard']?['name']?.toString() ?? '',
        standardLevel: (j['standard']?['level'] as num?)?.toInt() ?? 0,
        section: j['section']?.toString() ?? '',
        subjectName: j['subject']?['name']?.toString() ?? '',
        subjectCode: j['subject']?['code']?.toString() ?? '',
        academicYearName: j['academic_year']?['name']?.toString() ?? '',
        academicYearId: j['academic_year']?['id']?.toString() ?? '',
        updatedAt: j['updated_at']?.toString() ?? '',
      );
}

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

// ── Repository ────────────────────────────────────────────────────────────────

class _ScheduleRepository {
  _ScheduleRepository(this._dio);
  final Dio _dio;

  Future<List<_ClassAssignment>> fetchMine(String? academicYearId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      ApiConstants.teacherAssignmentsMine,
      queryParameters: {
        if (academicYearId != null) 'academic_year_id': academicYearId,
      },
    );
    final items = (resp.data?['items'] as List?) ?? [];
    return items
        .map((e) =>
            _ClassAssignment.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<_AcademicYear>> fetchYears() async {
    final resp =
        await _dio.get<Map<String, dynamic>>(ApiConstants.academicYears);
    final items = (resp.data?['items'] as List?) ?? [];
    return items.map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _AcademicYear(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        isActive: m['is_active'] == true,
      );
    }).toList();
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class TeacherScheduleScreen extends ConsumerStatefulWidget {
  const TeacherScheduleScreen({super.key});

  @override
  ConsumerState<TeacherScheduleScreen> createState() =>
      _TeacherScheduleScreenState();
}

class _TeacherScheduleScreenState extends ConsumerState<TeacherScheduleScreen> {
  late final _ScheduleRepository _repo;

  List<_ClassAssignment> _assignments = [];
  List<_AcademicYear> _years = [];
  String? _selectedYearId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repo = _ScheduleRepository(ref.read(dioClientProvider));
    _init();
  }

  Future<void> _init() async {
    try {
      final years = await _repo.fetchYears();
      final active = years.firstWhere(
        (y) => y.isActive,
        orElse: () => years.isNotEmpty
            ? years.first
            : const _AcademicYear(id: '', name: '', isActive: false),
      );
      if (mounted) {
        setState(() {
          _years = years;
          _selectedYearId = active.id.isNotEmpty ? active.id : null;
        });
      }
      await _loadAssignments();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetchMine(_selectedYearId);
      if (mounted) setState(() => _assignments = items);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Group assignments by class level for display
  Map<String, List<_ClassAssignment>> get _grouped {
    final map = <String, List<_ClassAssignment>>{};
    for (final a in _assignments) {
      final key = '${a.standardName} — Section ${a.section}';
      map.putIfAbsent(key, () => []).add(a);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAssignments,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Year filter ──────────────────────────────────────────────────
          if (_years.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedYearId,
                decoration: const InputDecoration(
                  labelText: 'Academic Year',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                items: _years
                    .map(
                      (y) => DropdownMenuItem<String>(
                        value: y.id,
                        child:
                            Text('${y.name}${y.isActive ? ' (Active)' : ''}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedYearId = v);
                  _loadAssignments();
                },
              ),
            ),

          // ── Info banner: read-only, admin controls ───────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Assignments are managed by your admin. '
                      'Contact your principal for changes.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red.shade300, size: 48),
                            const SizedBox(height: 8),
                            Text(_error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _loadAssignments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _assignments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.assignment_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'No assignments found for this year.',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.all(16),
                            children: _grouped.entries.map((entry) {
                              return _ClassCard(
                                classLabel: entry.key,
                                subjects: entry.value,
                              );
                            }).toList(),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Class card widget ─────────────────────────────────────────────────────────

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.classLabel,
    required this.subjects,
  });

  final String classLabel;
  final List<_ClassAssignment> subjects;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.class_,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    classLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${subjects.length} subject${subjects.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.indigo,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...subjects.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.book_outlined,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.subjectName,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      s.subjectCode,
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                'Year: ${subjects.first.academicYearName}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
