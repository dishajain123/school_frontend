import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'subject_list_screen.dart';

class _Opt {
  const _Opt({required this.id, required this.name});
  final String id;
  final String name;
}

class ClassroomMonitorScreen extends ConsumerStatefulWidget {
  const ClassroomMonitorScreen({super.key});

  @override
  ConsumerState<ClassroomMonitorScreen> createState() => _ClassroomMonitorScreenState();
}

class _ClassroomMonitorScreenState extends ConsumerState<ClassroomMonitorScreen> {
  bool _loading = true;
  List<_Opt> _years = [];
  List<_Opt> _standards = [];
  List<_Opt> _sections = [];
  _Opt? _year;
  _Opt? _standard;
  _Opt? _section;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final dio = ref.read(dioClientProvider);
    final yearsResp = await dio.get<Map<String, dynamic>>('/academic-years');
    final standardsResp = await dio.get<Map<String, dynamic>>('/standards');
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

    setState(() {
      _years = years;
      _standards = standards;
      _year = years.isNotEmpty ? years.first : null;
      _standard = standards.isNotEmpty ? standards.first : null;
      _loading = false;
    });
    await _loadSections();
  }

  Future<void> _loadSections() async {
    if (_standard == null || _year == null) return;
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
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        title: Text('Classroom Monitor', style: AppTypography.titleMedium),
        backgroundColor: AppColors.surface50,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<_Opt>(
              value: _year,
              decoration: const InputDecoration(labelText: 'Academic Year'),
              items: _years.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) async {
                setState(() => _year = v);
                await _loadSections();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_Opt>(
              value: _standard,
              decoration: const InputDecoration(labelText: 'Class'),
              items: _standards.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) async {
                setState(() => _standard = v);
                await _loadSections();
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<_Opt>(
              value: _section,
              decoration: const InputDecoration(labelText: 'Section'),
              items: _sections.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
              onChanged: (v) => setState(() => _section = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_year == null || _standard == null || _section == null)
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MyClassSubjectListScreen(
                              initialAcademicYearId: _year!.id,
                              initialStandardId: _standard!.id,
                              initialSectionId: _section!.id,
                            ),
                          ),
                        );
                      },
                child: const Text('View Classroom Content'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
