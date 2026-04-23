import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/academic_year/academic_year_model.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../data/models/leave/leave_balance_model.dart';
import '../../../data/models/leave/leave_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../data/repositories/leave_repository.dart';
import '../../../data/repositories/masters_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/leave_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_bottom_sheet.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';

class TeacherDetailScreen extends ConsumerStatefulWidget {
  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
    this.initialTeacher,
  });

  final String teacherId;
  final TeacherModel? initialTeacher;

  @override
  ConsumerState<TeacherDetailScreen> createState() =>
      _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen>
    with SingleTickerProviderStateMixin {
  TeacherModel? _teacher;
  bool _isLoading = true;
  bool _isDeletingAssignment = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    if (widget.initialTeacher != null) {
      _teacher = widget.initialTeacher;
      _isLoading = false;
      _animCtrl.forward();
    }
    _loadTeacher(showLoader: widget.initialTeacher == null);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeacher({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    final t = await ref
        .read(teacherNotifierProvider.notifier)
        .getById(widget.teacherId);
    if (mounted) {
      setState(() {
        _teacher = t;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
  }

  bool get _canEdit {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  bool get _canManageAssignments {
    final user = ref.read(currentUserProvider);
    if (user == null) return false;
    return user.hasPermission('teacher_assignment:manage') ||
        user.role == UserRole.principal ||
        user.role == UserRole.superadmin;
  }

  Future<void> _openAssignSheet(TeacherModel teacher) async {
    final created = await AppBottomSheet.show<bool>(
      context,
      title: 'Assign Class & Subject',
      subtitle: 'Map this teacher to a class section and subject.',
      child: _AssignTeacherBottomSheet(teacher: teacher),
      showDragHandle: true,
    );
    if (created == true && mounted) {
      ref.invalidate(teacherAssignmentsByTeacherProvider(teacher.id));
      SnackbarUtils.showSuccess(context, 'Assignment created');
    }
  }

  Future<void> _openEditAssignmentSheet({
    required TeacherModel teacher,
    required TeacherClassSubjectModel assignment,
  }) async {
    final updated = await AppBottomSheet.show<bool>(
      context,
      title: 'Update Assignment',
      subtitle: 'Update class, section, subject, or academic year.',
      child: _AssignTeacherBottomSheet(
        teacher: teacher,
        initialAssignment: assignment,
      ),
      showDragHandle: true,
    );
    if (updated == true && mounted) {
      ref.invalidate(teacherAssignmentsByTeacherProvider(teacher.id));
      SnackbarUtils.showSuccess(context, 'Assignment updated');
    }
  }

  Future<void> _deleteAssignment({
    required String teacherId,
    required TeacherClassSubjectModel assignment,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Assignment'),
        content: Text(
          'Remove ${assignment.subjectName ?? "subject"} from '
          '${assignment.standardName ?? "class"} ${assignment.section}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeletingAssignment = true);
    try {
      await ref.read(teacherNotifierProvider.notifier).deleteTeacherAssignment(
            assignmentId: assignment.id,
            teacherId: teacherId,
          );
      if (mounted) SnackbarUtils.showSuccess(context, 'Assignment removed');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isDeletingAssignment = false);
    }
  }

  Future<void> _openLeaveAllocationSheet({
    required TeacherModel teacher,
    required String? academicYearId,
    required List<LeaveBalanceModel> balances,
  }) async {
    final updated = await AppBottomSheet.show<bool>(
      context,
      title: 'Set Leave Allocation',
      subtitle: 'Define yearly allocation for this teacher.',
      child: _LeaveAllocationBottomSheet(
        teacherId: teacher.id,
        academicYearId: academicYearId,
        balances: balances,
      ),
      showDragHandle: true,
    );

    if (updated == true && mounted) {
      ref.invalidate(
        teacherLeaveBalanceProvider(
          (teacherId: teacher.id, academicYearId: academicYearId),
        ),
      );
      SnackbarUtils.showSuccess(context, 'Leave allocation updated');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Teacher', showBack: true),
        body: AppLoading.listView(count: 5),
      );
    }

    if (_teacher == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Teacher', showBack: true),
        body: Center(child: Text('Teacher not found.')),
      );
    }

    final teacher = _teacher!;
    final assignmentsAsync =
        ref.watch(teacherAssignmentsByTeacherProvider(teacher.id));
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final teacherBalanceAsync = ref.watch(
      teacherLeaveBalanceProvider(
        (teacherId: teacher.id, academicYearId: activeYearId),
      ),
    );
    final academicYears = ref.watch(academicYearNotifierProvider).valueOrNull ??
        const <AcademicYearModel>[];
    final academicYearName = teacher.academicYearId != null
        ? academicYears
            .where((y) => y.id == teacher.academicYearId)
            .map((y) => y.name)
            .firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            _TeacherSliverAppBar(
              teacher: teacher,
              canEdit: _canEdit,
              onBack: () => context.pop(),
              onEdit: () async {
                final result = await context.push(
                  '${RouteNames.teacherDetailPath(teacher.id)}/edit',
                  extra: teacher,
                );
                if (result == true && mounted) _loadTeacher(showLoader: false);
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoCard(
                      title: 'Contact Information',
                      icon: Icons.contact_mail_outlined,
                      rows: [
                        _InfoRowData(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: teacher.email ?? '—',
                        ),
                        _InfoRowData(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: teacher.phone ?? '—',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Professional Details',
                      icon: Icons.work_outline_rounded,
                      rows: [
                        _InfoRowData(
                          icon: Icons.badge_outlined,
                          label: 'Employee Code',
                          value: teacher.employeeCode,
                        ),
                        if (teacher.specialization != null)
                          _InfoRowData(
                            icon: Icons.school_outlined,
                            label: 'Specialization',
                            value: teacher.specialization!,
                          ),
                        if (teacher.joinDate != null)
                          _InfoRowData(
                            icon: Icons.calendar_today_outlined,
                            label: 'Join Date',
                            value: DateFormatter.formatDate(teacher.joinDate!),
                          ),
                        _InfoRowData(
                          icon: Icons.event_note_outlined,
                          label: 'Academic Year',
                          value: academicYearName ??
                              teacher.academicYearId ??
                              'Not assigned',
                        ),
                        _InfoRowData(
                          icon: Icons.circle,
                          label: 'Account Status',
                          value: teacher.isActive ? 'Active' : 'Inactive',
                          valueColor: teacher.isActive
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          iconColor: teacher.isActive
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _TeacherLeaveBalanceCard(
                      balancesAsync: teacherBalanceAsync,
                      canManage: _canEdit,
                      onManage: (balances) => _openLeaveAllocationSheet(
                        teacher: teacher,
                        academicYearId: activeYearId,
                        balances: balances,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _AssignmentsCard(
                      assignmentsAsync: assignmentsAsync,
                      canManage: _canManageAssignments,
                      isDeleting: _isDeletingAssignment,
                      onAdd: () => _openAssignSheet(teacher),
                      onEdit: (a) => _openEditAssignmentSheet(
                          teacher: teacher, assignment: a),
                      onDelete: (a) => _deleteAssignment(
                          teacherId: teacher.id, assignment: a),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Joined ${DateFormatter.formatDate(teacher.createdAt)}',
                        style: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sliver App Bar ─────────────────────────────────────────────────────────────

class _TeacherSliverAppBar extends StatelessWidget {
  const _TeacherSliverAppBar({
    required this.teacher,
    required this.canEdit,
    required this.onBack,
    required this.onEdit,
  });

  final TeacherModel teacher;
  final bool canEdit;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarBackground(teacher.displayName);

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: AppColors.navyDeep,
      foregroundColor: AppColors.white,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: onBack,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 16),
          ),
        ),
      ),
      actions: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onEdit,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.white, size: 16),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.2) ?? color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials(teacher.displayName),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  teacher.displayName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.goldPrimary.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    teacher.employeeCode,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Info Card ──────────────────────────────────────────────────────────────────

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(row.icon,
                          size: 18, color: row.iconColor ?? AppColors.grey400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(row.label,
                                style: AppTypography.caption.copyWith(
                                    color: AppColors.grey400, fontSize: 11)),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: AppTypography.bodyMedium.copyWith(
                                color: row.valueColor ?? AppColors.grey800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 1,
                    color: AppColors.surface100,
                    margin: const EdgeInsets.only(left: 46),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TeacherLeaveBalanceCard extends StatelessWidget {
  const _TeacherLeaveBalanceCard({
    required this.balancesAsync,
    required this.canManage,
    required this.onManage,
  });

  final AsyncValue<List<LeaveBalanceModel>> balancesAsync;
  final bool canManage;
  final ValueChanged<List<LeaveBalanceModel>> onManage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: AppColors.navyDeep,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Leave Allocation',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDeep,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (canManage)
                  balancesAsync.when(
                    loading: () => const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (_, __) => GestureDetector(
                      onTap: () => onManage(const <LeaveBalanceModel>[]),
                      child: _pillButtonLabel('Set'),
                    ),
                    data: (balances) => GestureDetector(
                      onTap: () => onManage(balances),
                      child: _pillButtonLabel('Manage'),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: balancesAsync.when(
              loading: () => const LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.navyMedium,
              ),
              error: (e, _) => Text(
                e.toString(),
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
              ),
              data: (balances) {
                if (balances.isEmpty) {
                  return Text(
                    'No leave allocation found for this teacher yet.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey500,
                    ),
                  );
                }

                return Column(
                  children: balances
                      .map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  b.leaveType.shortLabel,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.navyDeep,
                                  ),
                                ),
                              ),
                              Text(
                                'A ${b.totalDays.toStringAsFixed(0)}  U ${b.usedDays.toStringAsFixed(0)}  R ${b.remainingDays.toStringAsFixed(0)}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.grey600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillButtonLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _LeaveAllocationBottomSheet extends ConsumerStatefulWidget {
  const _LeaveAllocationBottomSheet({
    required this.teacherId,
    required this.academicYearId,
    required this.balances,
  });

  final String teacherId;
  final String? academicYearId;
  final List<LeaveBalanceModel> balances;

  @override
  ConsumerState<_LeaveAllocationBottomSheet> createState() =>
      _LeaveAllocationBottomSheetState();
}

class _LeaveAllocationBottomSheetState
    extends ConsumerState<_LeaveAllocationBottomSheet> {
  late final TextEditingController _casualCtrl;
  late final TextEditingController _sickCtrl;
  late final TextEditingController _earnedCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _casualCtrl = TextEditingController(
      text: _findTotal(LeaveType.casual).toStringAsFixed(0),
    );
    _sickCtrl = TextEditingController(
      text: _findTotal(LeaveType.sick).toStringAsFixed(0),
    );
    _earnedCtrl = TextEditingController(
      text: _findTotal(LeaveType.earned).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _casualCtrl.dispose();
    _sickCtrl.dispose();
    _earnedCtrl.dispose();
    super.dispose();
  }

  double _findTotal(LeaveType type) {
    for (final b in widget.balances) {
      if (b.leaveType == type) return b.totalDays;
    }
    return 0;
  }

  double? _parseDays(TextEditingController ctrl) {
    final value = double.tryParse(ctrl.text.trim());
    if (value == null || value < 0) return null;
    return value;
  }

  Future<void> _save() async {
    final casual = _parseDays(_casualCtrl);
    final sick = _parseDays(_sickCtrl);
    final earned = _parseDays(_earnedCtrl);
    if (casual == null || sick == null || earned == null) {
      SnackbarUtils.showError(context, 'Enter valid non-negative leave days.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(leaveRepositoryProvider);
      await repo.setTeacherBalance(
        teacherId: widget.teacherId,
        academicYearId: widget.academicYearId,
        allocations: [
          LeaveBalanceAllocationInput(
            leaveType: LeaveType.casual,
            totalDays: casual,
          ),
          LeaveBalanceAllocationInput(
            leaveType: LeaveType.sick,
            totalDays: sick,
          ),
          LeaveBalanceAllocationInput(
            leaveType: LeaveType.earned,
            totalDays: earned,
          ),
        ],
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _numericField(
          label: 'Casual Leave (Days)',
          controller: _casualCtrl,
          icon: Icons.beach_access_outlined,
        ),
        const SizedBox(height: 12),
        _numericField(
          label: 'Sick Leave (Days)',
          controller: _sickCtrl,
          icon: Icons.local_hospital_outlined,
        ),
        const SizedBox(height: 12),
        _numericField(
          label: 'Earned Leave (Days)',
          controller: _earnedCtrl,
          icon: Icons.star_outline_rounded,
        ),
        const SizedBox(height: 16),
        AppButton.primary(
          label: _isSaving ? 'Saving...' : 'Save Allocation',
          onTap: _isSaving ? null : _save,
          isLoading: _isSaving,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _numericField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18),
            hintText: '0',
            filled: true,
            fillColor: AppColors.surface50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.surface200),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Assignments Card ───────────────────────────────────────────────────────────

class _AssignmentsCard extends StatelessWidget {
  const _AssignmentsCard({
    required this.assignmentsAsync,
    required this.canManage,
    required this.isDeleting,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;
  final bool canManage;
  final bool isDeleting;
  final VoidCallback onAdd;
  final ValueChanged<TeacherClassSubjectModel> onEdit;
  final ValueChanged<TeacherClassSubjectModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Teaching Assignments',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyDeep,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (canManage)
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 13, color: AppColors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Assign',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: assignmentsAsync.when(
              loading: () => const LinearProgressIndicator(
                  minHeight: 2, color: AppColors.navyMedium),
              error: (_, __) => Text(
                'Could not load assignments',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
              ),
              data: (assignments) {
                if (assignments.isEmpty) {
                  return Text(
                    'No assignments added yet.',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.grey400),
                  );
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: assignments.map((a) {
                    final label =
                        '${a.standardName ?? "Class"} ${a.section} · ${a.subjectName ?? "Subject"}';
                    return Container(
                      padding: const EdgeInsets.only(
                          left: 10, right: 6, top: 6, bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surface200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.navyDeep,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (canManage) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: isDeleting ? null : () => onEdit(a),
                              child: Icon(Icons.edit_outlined,
                                  size: 14,
                                  color: isDeleting
                                      ? AppColors.grey400
                                      : AppColors.navyMedium),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: isDeleting ? null : () => onDelete(a),
                              child: Icon(Icons.close_rounded,
                                  size: 14,
                                  color: isDeleting
                                      ? AppColors.grey400
                                      : AppColors.errorRed),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Assign Bottom Sheet ────────────────────────────────────────────────────────

class _AssignTeacherBottomSheet extends ConsumerStatefulWidget {
  const _AssignTeacherBottomSheet({
    required this.teacher,
    this.initialAssignment,
  });

  final TeacherModel teacher;
  final TeacherClassSubjectModel? initialAssignment;

  @override
  ConsumerState<_AssignTeacherBottomSheet> createState() =>
      _AssignTeacherBottomSheetState();
}

class _AssignTeacherBottomSheetState
    extends ConsumerState<_AssignTeacherBottomSheet> {
  StandardModel? _selectedStandard;
  String? _selectedSection;
  SubjectModel? _selectedSubject;
  AcademicYearModel? _selectedAcademicYear;
  final _sectionController = TextEditingController();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  bool _submitting = false;
  bool _addingSection = false;
  bool _addingSubject = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAssignment;
    if (initial == null) return;

    final years =
        ref.read(academicYearNotifierProvider).valueOrNull ?? const [];
    final standards =
        ref.read(standardsProvider(initial.academicYearId)).valueOrNull ??
            const [];
    final subjects =
        ref.read(subjectsProvider(initial.standardId)).valueOrNull ?? const [];

    _selectedAcademicYear = years
        .cast<AcademicYearModel?>()
        .firstWhere((y) => y?.id == initial.academicYearId, orElse: () => null);
    _selectedStandard = standards
        .cast<StandardModel?>()
        .firstWhere((s) => s?.id == initial.standardId, orElse: () => null);
    _selectedSubject = subjects
        .cast<SubjectModel?>()
        .firstWhere((s) => s?.id == initial.subjectId, orElse: () => null);
    _selectedSection = initial.section;
  }

  @override
  void dispose() {
    _sectionController.dispose();
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final yearOptions = ref.watch(academicYearNotifierProvider).valueOrNull ??
        const <AcademicYearModel>[];
    final selectedYearId = _selectedAcademicYear?.id ?? activeYear?.id;
    final standardsAsync = ref.watch(standardsProvider(selectedYearId));
    final sectionsAsync = ref.watch(sectionsByStandardProvider((
      standardId: _selectedStandard?.id,
      academicYearId: selectedYearId,
    )));
    final subjectsAsync = ref.watch(subjectsProvider(_selectedStandard?.id));

    final standards = standardsAsync.valueOrNull ?? const <StandardModel>[];
    final subjects = subjectsAsync.valueOrNull ?? const <SubjectModel>[];
    final sections = sectionsAsync.valueOrNull ?? const <String>[];

    final yearValue =
        yearOptions.any((y) => y.id == selectedYearId) ? selectedYearId : null;
    final standardValue = standards.any((s) => s.id == _selectedStandard?.id)
        ? _selectedStandard?.id
        : null;
    final sectionValue =
        sections.contains(_selectedSection) ? _selectedSection : null;
    final subjectValue = subjects.any((s) => s.id == _selectedSubject?.id)
        ? _selectedSubject?.id
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.avatarBackground(widget.teacher.displayName)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _initials(widget.teacher.displayName),
                  style: AppTypography.labelMedium.copyWith(
                    color:
                        AppColors.avatarBackground(widget.teacher.displayName),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacher.displayName,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.teacher.employeeCode,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _SheetDropdown(
          label: 'Academic Year',
          value: yearValue,
          enabled: !_submitting,
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('Select academic year')),
            ...yearOptions.map((year) => DropdownMenuItem<String?>(
                value: year.id, child: Text(year.name))),
          ],
          onChanged: (yearId) {
            final selected = yearOptions
                .cast<AcademicYearModel?>()
                .firstWhere((y) => y?.id == yearId, orElse: () => null);
            setState(() {
              _selectedAcademicYear = selected;
              _selectedStandard = null;
              _selectedSection = null;
              _selectedSubject = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _SheetDropdown(
          label: 'Class',
          value: standardValue,
          enabled: !_submitting,
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('Select class')),
            ...standards.map((s) =>
                DropdownMenuItem<String?>(value: s.id, child: Text(s.name))),
          ],
          onChanged: (standardId) {
            final selected = standards
                .cast<StandardModel?>()
                .firstWhere((s) => s?.id == standardId, orElse: () => null);
            setState(() {
              _selectedStandard = selected;
              _selectedSubject = null;
              _selectedSection = null;
            });
          },
        ),
        const SizedBox(height: 12),
        _SheetDropdown(
          label: 'Section',
          value: sectionValue,
          enabled: !_submitting && _selectedStandard != null,
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('Select section')),
            ...sections.map(
                (s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
          ],
          onChanged: (s) => setState(() => _selectedSection = s),
        ),
        const SizedBox(height: 8),
        _buildAddSectionRow(
          selectedYearId: selectedYearId,
          sections: sections,
        ),
        const SizedBox(height: 8),
        _buildAddSubjectRow(subjects: subjects),
        const SizedBox(height: 12),
        _SheetDropdown(
          label: 'Subject',
          value: subjectValue,
          enabled: !_submitting && _selectedStandard != null,
          items: [
            const DropdownMenuItem<String?>(
                value: null, child: Text('Select subject')),
            ...subjects.map((s) => DropdownMenuItem<String?>(
                value: s.id, child: Text('${s.name} (${s.code})'))),
          ],
          onChanged: (subjectId) {
            final selected = subjects
                .cast<SubjectModel?>()
                .firstWhere((s) => s?.id == subjectId, orElse: () => null);
            setState(() => _selectedSubject = selected);
          },
        ),
        if (_selectedStandard != null &&
            sections.isEmpty &&
            !sectionsAsync.isLoading) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppColors.warningAmber.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warningAmber),
                const SizedBox(width: 8),
                Text(
                  'No sections found for this class yet.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.warningDark, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        AppButton.primary(
          label: widget.initialAssignment == null
              ? 'Assign Now'
              : 'Update Assignment',
          icon: Icons.check_circle_outline,
          isLoading: _submitting,
          onTap: (_submitting || _addingSection || _addingSubject)
              ? null
              : _submit,
        ),
      ],
    );
  }

  Widget _buildAddSectionRow({
    required String? selectedYearId,
    required List<String> sections,
  }) {
    final canAdd = !_submitting && !_addingSection && _selectedStandard != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _sectionController,
            enabled: canAdd,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'New Section',
              hintText: 'Type section (e.g. C)',
            ),
            onSubmitted: canAdd
                ? (_) => _createSection(
                      selectedYearId: selectedYearId,
                      sections: sections,
                    )
                : null,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 46,
          child: AppButton.secondary(
            label: _addingSection ? 'Adding...' : 'Add',
            icon: Icons.add_rounded,
            fullWidth: false,
            width: 96,
            onTap: canAdd
                ? () => _createSection(
                      selectedYearId: selectedYearId,
                      sections: sections,
                    )
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAddSubjectRow({
    required List<SubjectModel> subjects,
  }) {
    final canAdd = !_submitting && !_addingSubject && _selectedStandard != null;
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _subjectNameController,
                enabled: canAdd,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'New Subject (Class-wise)',
                  hintText: 'Type subject name',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _subjectCodeController,
                enabled: canAdd,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'Auto',
                ),
                onSubmitted:
                    canAdd ? (_) => _createSubject(subjects: subjects) : null,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 46,
              child: AppButton.secondary(
                label: _addingSubject ? 'Adding...' : 'Add',
                icon: Icons.library_add_outlined,
                fullWidth: false,
                width: 96,
                onTap: canAdd ? () => _createSubject(subjects: subjects) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Create class-specific subject and select it immediately.',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey500,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  String _suggestSubjectCode(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'SUBJ';
    if (words.length == 1) {
      final word =
          words.first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (word.isEmpty) return 'SUBJ';
      return word.length <= 6 ? word : word.substring(0, 6);
    }
    final code = words
        .map((w) => w[0])
        .join('')
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    return code.isEmpty ? 'SUBJ' : code;
  }

  Future<void> _createSubject({
    required List<SubjectModel> subjects,
  }) async {
    if (_selectedStandard == null) {
      SnackbarUtils.showError(context, 'Select class first.');
      return;
    }

    final name = _subjectNameController.text.trim();
    if (name.isEmpty) {
      SnackbarUtils.showError(context, 'Enter a subject name.');
      return;
    }

    final codeInput = _subjectCodeController.text.trim().toUpperCase();
    final code = codeInput.isEmpty ? _suggestSubjectCode(name) : codeInput;

    final sameName = subjects.where(
      (s) => s.name.trim().toLowerCase() == name.toLowerCase(),
    );
    if (sameName.isNotEmpty) {
      final existing = sameName.first;
      setState(() => _selectedSubject = existing);
      _subjectNameController.clear();
      _subjectCodeController.clear();
      SnackbarUtils.showSuccess(
          context, 'Subject already exists and selected.');
      return;
    }

    final codeConflict = subjects.any(
      (s) => s.code.trim().toUpperCase() == code,
    );
    if (codeConflict) {
      SnackbarUtils.showError(
          context, 'Subject code already exists for this class.');
      return;
    }

    setState(() => _addingSubject = true);
    try {
      final created = await ref.read(mastersRepositoryProvider).createSubject({
        'standard_id': _selectedStandard!.id,
        'name': name,
        'code': code,
      });

      if (!mounted) return;

      ref.invalidate(subjectsProvider(_selectedStandard?.id));
      ref.invalidate(subjectsNotifierProvider);

      setState(() {
        _selectedSubject = created;
      });
      _subjectNameController.clear();
      _subjectCodeController.clear();
      SnackbarUtils.showSuccess(
        context,
        'Subject ${created.name} (${created.code}) added and selected.',
      );
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _addingSubject = false);
    }
  }

  Future<void> _createSection({
    required String? selectedYearId,
    required List<String> sections,
  }) async {
    if (_selectedStandard == null) {
      SnackbarUtils.showError(context, 'Select class first.');
      return;
    }

    final sectionName = _sectionController.text.trim().toUpperCase();
    if (sectionName.isEmpty) {
      SnackbarUtils.showError(context, 'Enter a section name.');
      return;
    }

    if (sections.any((existing) => existing.toUpperCase() == sectionName)) {
      setState(() => _selectedSection = sections
          .firstWhere((existing) => existing.toUpperCase() == sectionName));
      _sectionController.clear();
      SnackbarUtils.showSuccess(
          context, 'Section already exists and selected.');
      return;
    }

    setState(() => _addingSection = true);
    try {
      final created = await ref.read(studentRepositoryProvider).createSection(
            standardId: _selectedStandard!.id,
            sectionName: sectionName,
            academicYearId: selectedYearId,
          );

      if (!mounted) return;

      final params = (
        standardId: _selectedStandard?.id,
        academicYearId: selectedYearId,
      );
      ref.invalidate(sectionsByStandardProvider(params));
      ref.invalidate(studentSectionsProvider(_selectedStandard?.id));
      final selectedStandardId = _selectedStandard?.id;
      if (selectedStandardId != null && selectedStandardId.isNotEmpty) {
        ref.invalidate(
          timetableSectionsProvider(
            (
              standardId: selectedStandardId,
              academicYearId: selectedYearId,
            ),
          ),
        );
      }

      setState(() {
        _selectedSection = created;
      });
      _sectionController.clear();
      SnackbarUtils.showSuccess(
          context, 'Section $created added successfully.');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _addingSection = false);
    }
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _submit() async {
    final selectedYearId =
        _selectedAcademicYear?.id ?? ref.read(activeYearProvider)?.id;
    if (_selectedStandard == null ||
        _selectedSection == null ||
        _selectedSubject == null ||
        selectedYearId == null) {
      SnackbarUtils.showError(
          context, 'Please select class, section, subject and academic year.');
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.initialAssignment == null) {
        await ref
            .read(teacherNotifierProvider.notifier)
            .createTeacherAssignment(
              teacherId: widget.teacher.id,
              standardId: _selectedStandard!.id,
              section: _selectedSection!,
              subjectId: _selectedSubject!.id,
              academicYearId: selectedYearId,
            );
      } else {
        await ref
            .read(teacherNotifierProvider.notifier)
            .updateTeacherAssignment(
              assignmentId: widget.initialAssignment!.id,
              teacherId: widget.teacher.id,
              standardId: _selectedStandard!.id,
              section: _selectedSection!,
              subjectId: _selectedSubject!.id,
              academicYearId: selectedYearId,
            );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

class _SheetDropdown extends StatelessWidget {
  const _SheetDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final List<DropdownMenuItem<String?>> items;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: enabled ? AppColors.white : AppColors.surface50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface200, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.grey400),
              onChanged: enabled ? onChanged : null,
              items: items,
            ),
          ),
        ),
      ],
    );
  }
}
