import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';

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
  ParentModel? _parent;
  List<ChildSummaryModel> _siblings = const <ChildSummaryModel>[];
  bool _isLoading = true;
  bool _isParentLoading = false;
  bool _isPromotionLoading = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standardsNotifierProvider.notifier).refresh();
    });
    if (widget.initialStudent != null) {
      _student = widget.initialStudent;
      _isLoading = false;
      _animCtrl.forward();
    }
    _loadStudent(showLoader: widget.initialStudent == null);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudent({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);
    final s = await ref
        .read(studentNotifierProvider.notifier)
        .getById(widget.studentId);
    if (mounted) {
      setState(() {
        _student = s;
        _isLoading = false;
      });
      _animCtrl.forward();
    }
    if (s != null) {
      await _loadParentContext(parentId: s.parentId, currentStudentId: s.id);
    }
  }

  Future<void> _loadParentContext({
    required String parentId,
    required String currentStudentId,
  }) async {
    if (mounted) setState(() => _isParentLoading = true);
    final repo = ref.read(parentRepositoryProvider);
    ParentModel? loadedParent = _parent;
    List<ChildSummaryModel> loadedSiblings = const <ChildSummaryModel>[];

    try {
      loadedParent = await repo.getById(parentId);
    } catch (_) {
      try {
        final firstPage = await repo.list(page: 1, pageSize: 100);
        final allPages = <ParentModel>[...firstPage.items];
        final maxPagesToScan =
            firstPage.totalPages > 5 ? 5 : firstPage.totalPages;
        for (var page = 2; page <= maxPagesToScan; page++) {
          final nextPage = await repo.list(page: page, pageSize: 100);
          allPages.addAll(nextPage.items);
        }
        for (final candidate in allPages) {
          if (candidate.id == parentId) {
            loadedParent = candidate;
            break;
          }
        }
      } catch (_) {
        // Keep fallback state; UI will still render sibling context.
      }
    }

    try {
      final children = await repo.getChildren(parentId);
      loadedSiblings = children.where((c) => c.id != currentStudentId).toList();
    } catch (_) {
      loadedSiblings = const <ChildSummaryModel>[];
    }

    if (!mounted) return;
    setState(() {
      _parent = loadedParent;
      _siblings = loadedSiblings;
      _isParentLoading = false;
    });
  }

  bool get _canEdit {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  bool get _canPromote {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('student:promote') ?? false;
  }

  bool get _canViewBehaviour {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('behaviour_log:read') ?? false;
  }

  bool get _canViewAttendanceHistory {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('attendance:read') ?? false;
  }

  bool get _canViewAttendanceAnalytics {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('attendance:analytics') ?? false;
  }

  bool get _canViewDocuments {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('document:generate') == true ||
        user?.hasPermission('document:manage') == true;
  }

  bool get _canVerifyDocuments {
    final user = ref.read(currentUserProvider);
    return (user?.role == UserRole.principal ||
            user?.role == UserRole.superadmin) &&
        (user?.hasPermission('document:manage') ?? false);
  }

  Future<void> _updatePromotionStatus(String status, String label) async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirm $label',
      message: 'Mark this student as $label? This action will be recorded.',
      confirmLabel: label,
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isPromotionLoading = true);
    try {
      await ref
          .read(studentNotifierProvider.notifier)
          .updatePromotionStatus(widget.studentId, status);
      if (!mounted) return;
      await _loadStudent(showLoader: false);
      await ref.read(studentNotifierProvider.notifier).load(refresh: true);
      if (!mounted) return;
      setState(() => _isPromotionLoading = false);
      SnackbarUtils.showSuccess(context, 'Student marked as $label.');
    } catch (e) {
      if (mounted) {
        setState(() => _isPromotionLoading = false);
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  String? _ageText(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    final hasHadBirthday = (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthday) age -= 1;
    if (age < 0) return null;
    return '$age years';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Student', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_student == null) {
      return const Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Student', showBack: true),
        body: Center(child: Text('Student not found.')),
      );
    }

    final student = _student!;
    final standards = ref.watch(standardsNotifierProvider).valueOrNull ?? [];
    final standardName = student.standardId != null
        ? standards
            .where((s) => s.id == student.standardId)
            .map((s) => s.name)
            .firstOrNull
        : null;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            _StudentSliverAppBar(
              student: student,
              standardName: standardName,
              canEdit: _canEdit,
              onBack: () => context.pop(),
              onEdit: () async {
                final result = await context.push(
                  '${RouteNames.studentDetailPath(student.id)}/edit',
                  extra: student,
                );
                if (result == true && mounted) _loadStudent();
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuickActionsRow(
                      studentId: student.id,
                      canViewBehaviour: _canViewBehaviour,
                      canViewAttendanceHistory: _canViewAttendanceHistory,
                      canViewAttendanceAnalytics: _canViewAttendanceAnalytics,
                      canViewDocuments: _canViewDocuments,
                      canVerifyDocuments: _canVerifyDocuments,
                    ),
                    const SizedBox(height: 20),
                    _InfoCard(
                      title: 'Academic Details',
                      icon: Icons.school_outlined,
                      rows: [
                        if (standardName != null)
                          _InfoRowData(
                              icon: Icons.class_outlined,
                              label: 'Standard',
                              value: standardName),
                        if (student.section != null)
                          _InfoRowData(
                              icon: Icons.grid_view_outlined,
                              label: 'Section',
                              value: student.section!),
                        if (student.rollNumber != null)
                          _InfoRowData(
                              icon: Icons.numbers_outlined,
                              label: 'Roll Number',
                              value: student.rollNumber!),
                        _InfoRowData(
                            icon: Icons.badge_outlined,
                            label: 'Admission Number',
                            value: student.admissionNumber),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Personal Details',
                      icon: Icons.person_outline_rounded,
                      rows: [
                        if (student.studentName != null &&
                            student.studentName!.trim().isNotEmpty)
                          _InfoRowData(
                              icon: Icons.person_outline_rounded,
                              label: 'Student Name',
                              value: student.studentName!.trim()),
                        if (_ageText(student.dateOfBirth) != null)
                          _InfoRowData(
                              icon: Icons.cake_rounded,
                              label: 'Age',
                              value: _ageText(student.dateOfBirth)!),
                        if (student.dateOfBirth != null)
                          _InfoRowData(
                              icon: Icons.cake_outlined,
                              label: 'Date of Birth',
                              value: DateFormatter.formatDate(
                                  student.dateOfBirth!)),
                        if (student.admissionDate != null)
                          _InfoRowData(
                              icon: Icons.calendar_today_outlined,
                              label: 'Admission Date',
                              value: DateFormatter.formatDate(
                                  student.admissionDate!)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InfoCard(
                      title: 'Parent Details',
                      icon: Icons.family_restroom_outlined,
                      rows: _isParentLoading
                          ? const [
                              _InfoRowData(
                                icon: Icons.hourglass_top_rounded,
                                label: 'Parent',
                                value: 'Loading parent details...',
                              ),
                            ]
                          : [
                              _InfoRowData(
                                icon: Icons.person_outline_rounded,
                                label: 'Parent Name',
                                value: _parent?.displayName ?? 'Not available',
                              ),
                              _InfoRowData(
                                icon: Icons.badge_outlined,
                                label: 'Relation',
                                value:
                                    _parent?.relation.label ?? 'Not available',
                              ),
                              _InfoRowData(
                                icon: Icons.work_outline_rounded,
                                label: 'Occupation',
                                value: (_parent?.occupation != null &&
                                        _parent!.occupation!.trim().isNotEmpty)
                                    ? _parent!.occupation!.trim()
                                    : 'Not provided',
                              ),
                              _InfoRowData(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: (_parent?.email != null &&
                                        _parent!.email!.trim().isNotEmpty)
                                    ? _parent!.email!
                                    : 'Not provided',
                              ),
                              _InfoRowData(
                                icon: Icons.phone_outlined,
                                label: 'Phone',
                                value: (_parent?.phone != null &&
                                        _parent!.phone!.trim().isNotEmpty)
                                    ? _parent!.phone!
                                    : 'Not provided',
                              ),
                              _InfoRowData(
                                icon: Icons.group_outlined,
                                label: 'Siblings',
                                value: _siblings.isEmpty
                                    ? 'No siblings linked with this parent'
                                    : '${_siblings.length} sibling${_siblings.length == 1 ? '' : 's'}: '
                                        '${_siblings.map((s) => s.admissionNumber).join(', ')}',
                              ),
                            ],
                    ),
                    if (_canPromote) ...[
                      const SizedBox(height: 16),
                      _PromotionCard(
                        student: student,
                        isLoading: _isPromotionLoading,
                        onPromote: () =>
                            _updatePromotionStatus('PROMOTED', 'Promoted'),
                        onHeldBack: () =>
                            _updatePromotionStatus('HELD_BACK', 'Held Back'),
                      ),
                    ],
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

class _StudentSliverAppBar extends StatelessWidget {
  const _StudentSliverAppBar({
    required this.student,
    required this.standardName,
    required this.canEdit,
    required this.onBack,
    required this.onEdit,
  });

  final StudentModel student;
  final String? standardName;
  final bool canEdit;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarBackground(student.admissionNumber);

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
                      student.initials,
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
                  student.admissionNumber,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                if (standardName != null)
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
                      '$standardName${student.section != null ? ' · Sec ${student.section}' : ''}',
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
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.studentId,
    required this.canViewBehaviour,
    required this.canViewAttendanceHistory,
    required this.canViewAttendanceAnalytics,
    required this.canViewDocuments,
    required this.canVerifyDocuments,
  });

  final String studentId;
  final bool canViewBehaviour;
  final bool canViewAttendanceHistory;
  final bool canViewAttendanceAnalytics;
  final bool canViewDocuments;
  final bool canVerifyDocuments;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickAction>[];
    if (canViewBehaviour) {
      actions.add(_QuickAction(
        label: 'Behaviour',
        icon: Icons.fact_check_outlined,
        color: AppColors.subjectHistory,
        onTap: () =>
            context.push(RouteNames.behaviourLogsPath(studentId: studentId)),
      ));
    }
    if (canViewAttendanceHistory) {
      actions.add(_QuickAction(
        label: 'Attendance',
        icon: Icons.history_edu_outlined,
        color: AppColors.successGreen,
        onTap: () =>
            context.push('${RouteNames.attendance}?student_id=$studentId'),
      ));
    }
    if (canViewAttendanceAnalytics) {
      actions.add(_QuickAction(
        label: 'Analytics',
        icon: Icons.insights_outlined,
        color: AppColors.infoBlue,
        onTap: () =>
            context.push(RouteNames.attendanceAnalyticsPath(studentId)),
      ));
    }
    if (canViewDocuments) {
      actions.add(_QuickAction(
        label: canVerifyDocuments ? 'Verify Docs' : 'Documents',
        icon: canVerifyDocuments
            ? Icons.verified_user_outlined
            : Icons.description_outlined,
        color:
            canVerifyDocuments ? AppColors.warningAmber : AppColors.subjectMath,
        onTap: () =>
            context.push('${RouteNames.documents}?student_id=$studentId'),
      ));
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(
      children: actions
          .map((a) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: a == actions.last ? 0 : 8),
                  child: GestureDetector(
                    onTap: a.onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: a.color.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(a.icon, size: 20, color: a.color),
                          const SizedBox(height: 4),
                          Text(
                            a.label,
                            style: AppTypography.labelSmall.copyWith(
                              color: a.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
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
                      Icon(row.icon, size: 18, color: AppColors.grey400),
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
                                color: AppColors.grey800,
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

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({
    required this.student,
    required this.isLoading,
    required this.onPromote,
    required this.onHeldBack,
  });

  final StudentModel student;
  final bool isLoading;
  final VoidCallback onPromote;
  final VoidCallback onHeldBack;

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
                  child: const Icon(Icons.trending_up_rounded,
                      size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  'Promotion Status',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: student.isPromoted
                        ? AppColors.successLight
                        : AppColors.surface100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    student.isPromoted ? 'Promoted' : 'Not Promoted',
                    style: AppTypography.labelSmall.copyWith(
                      color: student.isPromoted
                          ? AppColors.successGreen
                          : AppColors.grey500,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppButton.primary(
                    label: 'Mark Promoted',
                    onTap: isLoading ? null : onPromote,
                    isLoading: isLoading,
                    icon: Icons.trending_up_rounded,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton.secondary(
                    label: 'Held Back',
                    onTap: isLoading ? null : onHeldBack,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
