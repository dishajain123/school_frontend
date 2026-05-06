import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

class TeacherAnalyticsScreen extends ConsumerStatefulWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  ConsumerState<TeacherAnalyticsScreen> createState() =>
      _TeacherAnalyticsScreenState();
}

class _TeacherAnalyticsScreenState extends ConsumerState<TeacherAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStandardId;
  String? _selectedSection;
  String? _selectedSubjectId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final params = (
      academicYearId: activeYearId,
      standardId: _selectedStandardId,
      section: _selectedSection,
      subjectId: _selectedSubjectId,
    );
    final analyticsAsync = ref.watch(teacherAnalyticsProvider(params));

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Analytics',
        showBack: true,
        onBackPressed: () => context.go(RouteNames.dashboard),
      ),
      body: RefreshIndicator(
        color: AppColors.navyDeep,
        onRefresh: () async {
          ref.invalidate(teacherAnalyticsProvider(params));
          await ref.read(teacherAnalyticsProvider(params).future);
        },
        child: analyticsAsync.when(
          loading: () => _buildSkeletonLoader(),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            children: [
              AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(teacherAnalyticsProvider(params)),
              ),
            ],
          ),
          data: (analytics) {
            if (analytics.assignments.isEmpty &&
                analytics.assignmentSubmission.totalAssignments == 0 &&
                analytics.attendance.totalRecords == 0 &&
                analytics.marks.totalEntries == 0) {
              return ListView(
                padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                children: const [
                  AppEmptyState(
                    title: 'No analytics data yet',
                    subtitle:
                        'Analytics will appear after assignments, attendance, and results are recorded.',
                    icon: Icons.insights_outlined,
                  ),
                ],
              );
            }

            final classOptions = <_Option>[
              for (final item in analytics.assignments)
                _Option(id: item.standardId, label: item.standardName),
            ]
                .fold<Map<String, _Option>>({}, (map, item) {
                  map[item.id] = item;
                  return map;
                })
                .values
                .toList();

            final sectionOptions = <String>{
              for (final item in analytics.assignments)
                if (_selectedStandardId == null ||
                    item.standardId == _selectedStandardId)
                  item.section,
            }.toList()
              ..sort();

            final subjectOptions = <_Option>[
              for (final item in analytics.assignments)
                if ((_selectedStandardId == null ||
                        item.standardId == _selectedStandardId) &&
                    (_selectedSection == null ||
                        item.section == _selectedSection))
                  _Option(id: item.subjectId, label: item.subjectName),
            ]
                .fold<Map<String, _Option>>({}, (map, item) {
                  map[item.id] = item;
                  return map;
                })
                .values
                .toList();

            return FadeTransition(
              opacity: _fadeAnim,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // ── Hero summary banner ──────────────────────────────
                  SliverToBoxAdapter(
                    child: _HeroBanner(analytics: analytics),
                  ),

                  // ── Filter chips row ─────────────────────────────────
                  SliverToBoxAdapter(
                    child: _FilterChipsRow(
                      classOptions: classOptions,
                      sectionOptions: sectionOptions
                          .map((s) => _Option(id: s, label: s))
                          .toList(),
                      subjectOptions: subjectOptions,
                      selectedStandardId: _selectedStandardId,
                      selectedSection: _selectedSection,
                      selectedSubjectId: _selectedSubjectId,
                      onClassChanged: (v) => setState(() {
                        _selectedStandardId = v;
                        _selectedSection = null;
                        _selectedSubjectId = null;
                      }),
                      onSectionChanged: (v) => setState(() {
                        _selectedSection = v;
                        _selectedSubjectId = null;
                      }),
                      onSubjectChanged: (v) =>
                          setState(() => _selectedSubjectId = v),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // ── Cards ────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.pageHorizontal),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _AssignmentCard(data: analytics),
                        const SizedBox(height: 14),
                        _AttendanceCard(data: analytics),
                        const SizedBox(height: 14),
                        _MarksCard(data: analytics),
                        const SizedBox(height: 90),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        AppLoading.card(height: 110),
        const SizedBox(height: 12),
        AppLoading.card(height: 52),
        const SizedBox(height: 12),
        AppLoading.card(height: 160),
        const SizedBox(height: 12),
        AppLoading.card(height: 160),
        const SizedBox(height: 12),
        AppLoading.card(height: 160),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner — 3 quick-glance KPI chips
// ─────────────────────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.analytics});
  final TeacherAnalyticsData analytics;

  @override
  Widget build(BuildContext context) {
    final a = analytics.assignmentSubmission;
    final att = analytics.attendance;
    final m = analytics.marks;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyDeep,
            AppColors.navyDeep.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _KpiChip(
            icon: Icons.assignment_outlined,
            label: 'Assignments',
            value: '${a.totalAssignments}',
            color: const Color(0xFF7DD3FC),
          ),
          _KpiDivider(),
          _KpiChip(
            icon: Icons.how_to_reg_outlined,
            label: 'Attendance',
            value: '${att.attendancePercentage.toStringAsFixed(0)}%',
            color: const Color(0xFF86EFAC),
          ),
          _KpiDivider(),
          _KpiChip(
            icon: Icons.bar_chart_rounded,
            label: 'Avg Marks',
            value: '${m.averagePercentage.toStringAsFixed(0)}%',
            color: const Color(0xFFFCA5A5),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _KpiDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 50,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter chips — horizontally scrollable, pill-style
// ─────────────────────────────────────────────────────────────────────────────
class _FilterChipsRow extends StatelessWidget {
  const _FilterChipsRow({
    required this.classOptions,
    required this.sectionOptions,
    required this.subjectOptions,
    required this.selectedStandardId,
    required this.selectedSection,
    required this.selectedSubjectId,
    required this.onClassChanged,
    required this.onSectionChanged,
    required this.onSubjectChanged,
  });

  final List<_Option> classOptions;
  final List<_Option> sectionOptions;
  final List<_Option> subjectOptions;
  final String? selectedStandardId;
  final String? selectedSection;
  final String? selectedSubjectId;
  final ValueChanged<String?> onClassChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onSubjectChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _FilterPill(
            icon: Icons.class_outlined,
            label: classOptions
                    .where((o) => o.id == selectedStandardId)
                    .map((o) => o.label)
                    .firstOrNull ??
                'Class',
            isActive: selectedStandardId != null,
            options: classOptions,
            allLabel: 'All Classes',
            onChanged: onClassChanged,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            icon: Icons.group_outlined,
            label: selectedSection ?? 'Section',
            isActive: selectedSection != null,
            options: sectionOptions,
            allLabel: 'All Sections',
            onChanged: onSectionChanged,
          ),
          const SizedBox(width: 8),
          _FilterPill(
            icon: Icons.book_outlined,
            label: subjectOptions
                    .where((o) => o.id == selectedSubjectId)
                    .map((o) => o.label)
                    .firstOrNull ??
                'Subject',
            isActive: selectedSubjectId != null,
            options: subjectOptions,
            allLabel: 'All Subjects',
            onChanged: onSubjectChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.options,
    required this.allLabel,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final List<_Option> options;
  final String allLabel;
  final ValueChanged<String?> onChanged;

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OptionSheet(
        allLabel: allLabel,
        options: options,
        onSelected: (v) {
          onChanged(v);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSheet(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.navyDeep : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppColors.navyDeep
                : AppColors.grey800.withValues(alpha: 0.18),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.grey700,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isActive ? Colors.white : AppColors.grey800,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isActive ? Colors.white70 : AppColors.grey600,
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionSheet extends StatelessWidget {
  const _OptionSheet({
    required this.allLabel,
    required this.options,
    required this.onSelected,
  });
  final String allLabel;
  final List<_Option> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(
              allLabel,
              style: AppTypography.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600),
            ),
            leading: const Icon(Icons.all_inclusive_rounded),
            onTap: () => onSelected(null),
          ),
          const Divider(height: 1),
          ...options.map(
            (opt) => ListTile(
              title: Text(
                opt.label,
                style: AppTypography.bodyMedium,
              ),
              onTap: () => onSelected(opt.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assignment Card
// ─────────────────────────────────────────────────────────────────────────────
class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final a = data.assignmentSubmission;
    final submissionRate = a.totalAssignments > 0
        ? (a.totalSubmissions / (a.totalAssignments * 1.0)).clamp(0.0, 1.0)
        : 0.0;
    final onTimeRate = a.totalSubmissions > 0
        ? (a.onTimeSubmissions / a.totalSubmissions).clamp(0.0, 1.0)
        : 0.0;

    return _SectionCard(
      title: 'Assignments',
      icon: Icons.assignment_outlined,
      accentColor: const Color(0xFF3B82F6),
      child: Column(
        children: [
          Row(
            children: [
              _StatTile(
                label: 'Total',
                value: '${a.totalAssignments}',
                icon: Icons.list_alt_rounded,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Overdue',
                value: '${a.overdueAssignments}',
                icon: Icons.warning_amber_rounded,
                color: a.overdueAssignments > 0
                    ? const Color(0xFFEF4444)
                    : AppColors.grey600,
              ),
              const SizedBox(width: 10),
              _StatTile(
                label: 'Pending Review',
                value: '${a.pendingReviewSubmissions}',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ProgressMetric(
            label: 'Submission Rate',
            value: submissionRate,
            valueText:
                '${a.totalSubmissions} of ${a.totalAssignments * 1} submitted',
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 10),
          _ProgressMetric(
            label: 'On-time Rate',
            value: onTimeRate,
            valueText:
                '${a.onTimeSubmissions} on-time · ${a.lateSubmissions} late',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Attendance Card
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final a = data.attendance;
    final pct = (a.attendancePercentage / 100).clamp(0.0, 1.0);
    final Color progressColor = a.attendancePercentage >= 75
        ? const Color(0xFF10B981)
        : a.attendancePercentage >= 50
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return _SectionCard(
      title: 'Attendance',
      subtitle: 'Your subject records',
      icon: Icons.how_to_reg_outlined,
      accentColor: const Color(0xFF10B981),
      child: Column(
        children: [
          Row(
            children: [
              // Circular gauge
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 7,
                      backgroundColor: progressColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    ),
                    Text(
                      '${a.attendancePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDeep,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InlineMetric(
                      label: 'Present',
                      value: '${a.presentCount}',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: 'Absent',
                      value: '${a.absentCount}',
                      color: const Color(0xFFEF4444),
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: 'Late',
                      value: '${a.lateCount}',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: 'Total Records',
                      value: '${a.totalRecords}',
                      color: AppColors.grey600,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (a.bySubject.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...a.bySubject.map(
              (item) => _SubjectProgressRow(
                label: item.subjectName,
                percentage: item.attendancePercentage,
                detail: '${item.present}/${item.total}',
                color: item.attendancePercentage >= 75
                    ? const Color(0xFF10B981)
                    : item.attendancePercentage >= 50
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Marks Card
// ─────────────────────────────────────────────────────────────────────────────
class _MarksCard extends StatelessWidget {
  const _MarksCard({required this.data});
  final TeacherAnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final m = data.marks;
    final total = m.aboveAverageCount + m.moderateCount + m.belowAverageCount;
    final Color avgColor = m.averagePercentage >= 75
        ? const Color(0xFF10B981)
        : m.averagePercentage >= 40
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return _SectionCard(
      title: 'Marks',
      subtitle: 'Entries by you',
      icon: Icons.bar_chart_rounded,
      accentColor: const Color(0xFF8B5CF6),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (m.averagePercentage / 100).clamp(0.0, 1.0),
                      strokeWidth: 7,
                      backgroundColor: avgColor.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(avgColor),
                    ),
                    Text(
                      '${m.averagePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDeep,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InlineMetric(
                      label: 'Total Entries',
                      value: '${m.totalEntries}',
                      color: AppColors.grey600,
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: 'Above 75%',
                      value: '${m.aboveAverageCount}',
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: '40 – 74%',
                      value: '${m.moderateCount}',
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 6),
                    _InlineMetric(
                      label: 'Below 40%',
                      value: '${m.belowAverageCount}',
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 14),
            _StackedBar(
              above: m.aboveAverageCount,
              moderate: m.moderateCount,
              below: m.belowAverageCount,
            ),
          ],
          if (m.bySubject.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),
            ...m.bySubject.map(
              (item) => _SubjectProgressRow(
                label: item.subjectName,
                percentage: item.averagePercentage,
                detail: '${item.entries} entries',
                color: item.averagePercentage >= 75
                    ? const Color(0xFF10B981)
                    : item.averagePercentage >= 40
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navyDeep,
                        fontSize: 15,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.label,
    required this.value,
    required this.valueText,
    required this.color,
  });
  final String label;
  final double value;
  final String valueText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valueText,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.grey600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _InlineMetric extends StatelessWidget {
  const _InlineMetric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.grey600,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.navyDeep,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  const _SubjectProgressRow({
    required this.label,
    required this.percentage,
    required this.detail,
    required this.color,
  });
  final String label;
  final double percentage;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%  ($detail)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (percentage / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedBar extends StatelessWidget {
  const _StackedBar({
    required this.above,
    required this.moderate,
    required this.below,
  });
  final int above;
  final int moderate;
  final int below;

  @override
  Widget build(BuildContext context) {
    final total = above + moderate + below;
    if (total == 0) return const SizedBox.shrink();
    final aboveFlex = (above / total * 100).round();
    final moderateFlex = (moderate / total * 100).round();
    final belowFlex = (below / total * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Score Distribution',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.grey700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(
            children: [
              if (aboveFlex > 0)
                Expanded(
                  flex: aboveFlex,
                  child: Container(height: 10, color: const Color(0xFF10B981)),
                ),
              if (moderateFlex > 0)
                Expanded(
                  flex: moderateFlex,
                  child: Container(height: 10, color: const Color(0xFFF59E0B)),
                ),
              if (belowFlex > 0)
                Expanded(
                  flex: belowFlex,
                  child: Container(height: 10, color: const Color(0xFFEF4444)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Row(
          children: [
            _BarLegend(color: Color(0xFF10B981), label: '≥75%'),
            SizedBox(width: 12),
            _BarLegend(color: Color(0xFFF59E0B), label: '40–74%'),
            SizedBox(width: 12),
            _BarLegend(color: Color(0xFFEF4444), label: '<40%'),
          ],
        ),
      ],
    );
  }
}

class _BarLegend extends StatelessWidget {
  const _BarLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.grey600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unchanged helpers
// ─────────────────────────────────────────────────────────────────────────────
class _Option {
  const _Option({required this.id, required this.label});
  final String id;
  final String label;
}
