// lib/presentation/students/screens/student_detail_screen.dart  [Mobile App]
// Phase 14/15: Added Academic History tile to student detail.
// All other existing content preserved exactly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  const StudentDetailScreen({
    super.key,
    required this.studentId,
    this.initialStudent,
  });

  final String studentId;
  final StudentModel? initialStudent;

  @override
  ConsumerState<StudentDetailScreen> createState() =>
      _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen>
    with SingleTickerProviderStateMixin {
  StudentModel? _student;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _student = widget.initialStudent;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final student = await ref
          .read(studentNotifierProvider.notifier)
          .getById(widget.studentId);
      if (mounted) setState(() => _student = student);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: _student?.user?.fullName ??
            _student?.displayName ??
            'Student Profile',
        showBack: true,
        actions: [
          if (currentUser?.hasPermission('user:manage') == true)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                context.push(
                  '${RouteNames.students}/${widget.studentId}/edit',
                  extra: _student,
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _student == null
                  ? const Center(child: Text('Student not found.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // ── Avatar + name ──────────────────────────────
                          _ProfileHeader(student: _student!),
                          const SizedBox(height: 16),

                          // ── Academic History tile (Phase 14/15) ─────────
                          _SectionCard(
                            title: 'Academic History',
                            icon: Icons.history_edu_outlined,
                            iconColor: Colors.indigo,
                            onTap: () {
                              context.push(
                                '/academic-history/${widget.studentId}',
                              );
                            },
                            child: const Text(
                              'View full year-by-year academic record, transfers, '
                              'promotions, and enrollment history.',
                              style: TextStyle(
                                  fontSize: 13, color: Colors.black54),
                            ),
                          ),
                          if (currentUser?.hasPermission('enrollment:create') ==
                                  true ||
                              currentUser?.hasPermission('student:promote') ==
                                  true) ...[
                            const SizedBox(height: 12),
                            _SectionCard(
                              title: 'Re-enroll Student',
                              icon: Icons.how_to_reg_outlined,
                              iconColor: Colors.deepPurple,
                              onTap: () async {
                                final result = await context.push(
                                  RouteNames.reenrollmentPath(widget.studentId),
                                  extra: {
                                    'studentName':
                                        _student?.user?.fullName ??
                                            _student?.displayName ??
                                            'Student',
                                    'admissionNumber':
                                        _student?.admissionNumber ?? '—',
                                  },
                                );
                                if (result != null && mounted) {
                                  await _load();
                                }
                              },
                              child: const Text(
                                'Create a new academic-year enrollment for this student '
                                'without recreating profile, admission number, or parent link.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),

                          // ── Basic Info ────────────────────────────────
                          _InfoCard(
                            title: 'Basic Information',
                            rows: [
                              _InfoRow(
                                label: 'Admission No',
                                value: _student!.admissionNumber,
                              ),
                              _InfoRow(
                                label: 'Date of Birth',
                                value: _student!.dateOfBirth != null
                                    ? DateFormatter.formatDate(
                                        _student!.dateOfBirth!)
                                    : '—',
                              ),
                              _InfoRow(
                                label: 'Admission Date',
                                value: _student!.admissionDate != null
                                    ? DateFormatter.formatDate(
                                        _student!.admissionDate!)
                                    : '—',
                              ),
                              _InfoRow(
                                label: 'Email',
                                value: _student!.email ??
                                    _student!.user?.email ??
                                    '—',
                              ),
                              _InfoRow(
                                label: 'Phone',
                                value: _student!.phone ??
                                    _student!.user?.phone ??
                                    '—',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // ── Current Enrollment ────────────────────────
                          _InfoCard(
                            title: 'Current Enrollment',
                            rows: [
                              _InfoRow(
                                label: 'Class',
                                value: _student!.standardName ?? '—',
                              ),
                              _InfoRow(
                                label: 'Section',
                                value: _student!.section ?? '—',
                              ),
                              _InfoRow(
                                label: 'Roll Number',
                                value: _student!.rollNumber ?? '—',
                              ),
                              _InfoRow(
                                label: 'Academic Year',
                                value: _student!.academicYearName ?? '—',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            title: 'Behaviour Overview',
                            rows: [
                              _InfoRow(
                                label: 'Latest Behaviour',
                                value: _formatIncident(
                                      _student!
                                          .behaviourSummary?.latestIncidentType,
                                    ) ??
                                    'No logs yet',
                              ),
                              _InfoRow(
                                label: 'Latest Comment',
                                value: _student!
                                        .behaviourSummary?.latestDescription ??
                                    '—',
                              ),
                              _InfoRow(
                                label: 'Positive',
                                value: (_student!
                                            .behaviourSummary?.positiveCount ??
                                        0)
                                    .toString(),
                              ),
                              _InfoRow(
                                label: 'Negative',
                                value: (_student!
                                            .behaviourSummary?.negativeCount ??
                                        0)
                                    .toString(),
                              ),
                              _InfoRow(
                                label: 'Neutral',
                                value:
                                    (_student!.behaviourSummary?.neutralCount ??
                                            0)
                                        .toString(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            title: 'Parent Details',
                            rows: [
                              _InfoRow(
                                label: 'Name',
                                value: _student!.parent?.fullName ?? '—',
                              ),
                              _InfoRow(
                                label: 'Relation',
                                value: _student!.parent?.relation ?? '—',
                              ),
                              _InfoRow(
                                label: 'Phone',
                                value: _student!.parent?.phone ?? '—',
                              ),
                              _InfoRow(
                                label: 'Email',
                                value: _student!.parent?.email ?? '—',
                              ),
                              _InfoRow(
                                label: 'Occupation',
                                value: _student!.parent?.occupation ?? '—',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
    );
  }

  String? _formatIncident(String? incident) {
    if (incident == null || incident.trim().isEmpty) return null;
    final value = incident.trim().toUpperCase();
    if (value == 'POSITIVE') return 'Positive';
    if (value == 'NEGATIVE') return 'Negative';
    return 'Neutral';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});
  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    final name = student.user?.fullName ?? student.displayName;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.navyLight,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  if (student.admissionNumber.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Adm: ${student.admissionNumber}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.chevron_right,
                        color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});
  final String title;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
