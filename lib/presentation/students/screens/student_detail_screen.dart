import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_loading.dart';

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

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  StudentModel? _student;
  bool _isLoading = true;
  bool _isPromotionLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialStudent != null) {
      _student = widget.initialStudent;
      _isLoading = false;
    } else {
      _loadStudent();
    }
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);
    final s = await ref
        .read(studentNotifierProvider.notifier)
        .getById(widget.studentId);
    if (mounted) {
      setState(() {
        _student = s;
        _isLoading = false;
      });
    }
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
      final updated = await ref
          .read(studentNotifierProvider.notifier)
          .updatePromotionStatus(widget.studentId, status);
      if (mounted) {
        setState(() {
          _student = updated;
          _isPromotionLoading = false;
        });
        SnackbarUtils.showSuccess(context, 'Student marked as $label.');
      }
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
    final hasHadBirthdayThisYear = (now.month > dob.month) ||
        (now.month == dob.month && now.day >= dob.day);
    if (!hasHadBirthdayThisYear) age -= 1;
    if (age < 0) return null;
    return '$age years';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Student', showBack: true),
        body: AppLoading.listView(count: 5),
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.navyDeep,
            foregroundColor: AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await context.push(
                      '${RouteNames.studentDetailPath(student.id)}/edit',
                      extra: student,
                    );
                    if (result == true && mounted) _loadStudent();
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navyDeep, AppColors.navyMedium],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppDimensions.space32),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.avatarBackground(
                              student.admissionNumber),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            student.initials,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        student.admissionNumber,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      if (standardName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space12,
                            vertical: AppDimensions.space4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusFull),
                          ),
                          child: Text(
                            '$standardName${student.section != null ? ' · Sec ${student.section}' : ''}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.goldPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Academic Details',
                    children: [
                      if (standardName != null)
                        _InfoRow(
                          icon: Icons.class_outlined,
                          label: 'Standard',
                          value: standardName,
                        ),
                      if (student.section != null)
                        _InfoRow(
                          icon: Icons.grid_view_outlined,
                          label: 'Section',
                          value: student.section!,
                        ),
                      if (student.rollNumber != null)
                        _InfoRow(
                          icon: Icons.numbers_outlined,
                          label: 'Roll Number',
                          value: student.rollNumber!,
                        ),
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Admission Number',
                        value: student.admissionNumber,
                      ),
                    ],
                  ),
                  if (_canViewBehaviour) ...[
                    const SizedBox(height: AppDimensions.space16),
                    AppButton.secondary(
                      label: 'View Behaviour Log',
                      onTap: () => context.push(
                        RouteNames.behaviourLogsPath(studentId: student.id),
                      ),
                      icon: Icons.fact_check_outlined,
                    ),
                  ],
                  if (_canViewAttendanceHistory) ...[
                    const SizedBox(height: AppDimensions.space12),
                    AppButton.secondary(
                      label: 'View Attendance History',
                      onTap: () => context.push(
                          '${RouteNames.attendance}?student_id=${student.id}'),
                      icon: Icons.history_edu_outlined,
                    ),
                  ],
                  if (_canViewAttendanceAnalytics) ...[
                    const SizedBox(height: AppDimensions.space8),
                    AppButton.secondary(
                      label: 'View Attendance Analytics',
                      onTap: () => context.push(
                        RouteNames.attendanceAnalyticsPath(student.id),
                      ),
                      icon: Icons.insights_outlined,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Personal Details',
                    children: [
                      if (_ageText(student.dateOfBirth) != null)
                        _InfoRow(
                          icon: Icons.cake_rounded,
                          label: 'Age',
                          value: _ageText(student.dateOfBirth)!,
                        ),
                      if (student.dateOfBirth != null)
                        _InfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Date of Birth',
                          value: DateFormatter.formatDate(student.dateOfBirth!),
                        ),
                      if (student.admissionDate != null)
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Admission Date',
                          value:
                              DateFormatter.formatDate(student.admissionDate!),
                        ),
                    ],
                  ),
                  if (_canPromote) ...[
                    const SizedBox(height: AppDimensions.space16),
                    _InfoSection(
                      title: 'Promotion Status',
                      children: [
                        _InfoRow(
                          icon: Icons.trending_up_rounded,
                          label: 'Status',
                          value:
                              student.isPromoted ? 'Promoted' : 'Not Promoted',
                          valueColor: student.isPromoted
                              ? AppColors.successGreen
                              : AppColors.grey600,
                          iconColor: student.isPromoted
                              ? AppColors.successGreen
                              : AppColors.grey400,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    AppButton.primary(
                      label: 'Mark as Promoted',
                      onTap: _isPromotionLoading
                          ? null
                          : () =>
                              _updatePromotionStatus('PROMOTED', 'Promoted'),
                      isLoading: _isPromotionLoading,
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    AppButton.secondary(
                      label: 'Mark as Held Back',
                      onTap: _isPromotionLoading
                          ? null
                          : () =>
                              _updatePromotionStatus('HELD_BACK', 'Held Back'),
                      isLoading: _isPromotionLoading,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.space40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.grey400,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.surface200,
              width: AppDimensions.borderThin,
            ),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < children.length - 1)
                          const Divider(
                            height: 1,
                            color: AppColors.surface100,
                            indent: AppDimensions.space16,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          Icon(icon,
              size: AppDimensions.iconSM,
              color: iconColor ?? AppColors.grey400),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.grey800,
                    fontWeight: FontWeight.w500,
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
