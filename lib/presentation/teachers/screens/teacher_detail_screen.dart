import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_avatar.dart';
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

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen> {
  TeacherModel? _teacher;
  bool _isLoading = true;
  bool _isDeletingAssignment = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeacher != null) {
      _teacher = widget.initialTeacher;
      _isLoading = false;
    } else {
      _loadTeacher();
    }
  }

  Future<void> _loadTeacher() async {
    setState(() => _isLoading = true);
    final t = await ref
        .read(teacherNotifierProvider.notifier)
        .getById(widget.teacherId);
    if (mounted) {
      setState(() {
        _teacher = t;
        _isLoading = false;
      });
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
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.errorRed),
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
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Assignment removed');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isDeletingAssignment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Teacher', showBack: true),
        body: AppLoading.listView(count: 5),
      );
    }

    if (_teacher == null) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Teacher', showBack: true),
        body: const Center(
          child: Text('Teacher not found.'),
        ),
      );
    }

    final teacher = _teacher!;
    final assignmentsAsync =
        ref.watch(teacherAssignmentsByTeacherProvider(teacher.id));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
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
                      RouteNames.teacherDetailPath(teacher.id) + '/edit',
                      extra: teacher,
                    );
                    if (result == true && mounted) {
                      _loadTeacher();
                    }
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
                      const SizedBox(height: AppDimensions.space48),
                      AppAvatar.xl(
                        imageUrl: teacher.profilePhotoUrl,
                        name: teacher.displayName,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        teacher.displayName,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
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
                          teacher.employeeCode,
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
                    title: 'Contact Information',
                    children: [
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: teacher.email ?? '—',
                      ),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: teacher.phone ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Professional Details',
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Employee Code',
                        value: teacher.employeeCode,
                      ),
                      if (teacher.specialization != null)
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'Specialization',
                          value: teacher.specialization!,
                        ),
                      if (teacher.joinDate != null)
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Join Date',
                          value: DateFormatter.formatDate(teacher.joinDate!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _TeacherAssignmentsSection(
                    assignmentsAsync: assignmentsAsync,
                    canManage: _canManageAssignments,
                    isDeleting: _isDeletingAssignment,
                    onAdd: () => _openAssignSheet(teacher),
                    onDelete: (a) => _deleteAssignment(
                      teacherId: teacher.id,
                      assignment: a,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Status',
                    children: [
                      _InfoRow(
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
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    'Joined ${DateFormatter.formatDate(teacher.createdAt)}',
                    style: AppTypography.caption,
                  ),
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

class _TeacherAssignmentsSection extends StatelessWidget {
  const _TeacherAssignmentsSection({
    required this.assignmentsAsync,
    required this.canManage,
    required this.isDeleting,
    required this.onAdd,
    required this.onDelete,
  });

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;
  final bool canManage;
  final bool isDeleting;
  final VoidCallback onAdd;
  final ValueChanged<TeacherClassSubjectModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return _InfoSection(
      title: 'Teaching Assignments',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space16,
            AppDimensions.space12,
            AppDimensions.space16,
            AppDimensions.space8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Class, section and subject allocations',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ),
              if (canManage)
                AppButton.small(
                  label: 'Assign',
                  icon: Icons.add,
                  onTap: onAdd,
                  fullWidth: false,
                ),
            ],
          ),
        ),
        assignmentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppDimensions.space16),
            child: LinearProgressIndicator(minHeight: 2),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Text(
              'Could not load assignments',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
              ),
            ),
          ),
          data: (assignments) {
            if (assignments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  0,
                  AppDimensions.space16,
                  AppDimensions.space12,
                ),
                child: Text(
                  'No assignments added yet.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                0,
                AppDimensions.space16,
                AppDimensions.space12,
              ),
              child: Wrap(
                spacing: AppDimensions.space8,
                runSpacing: AppDimensions.space8,
                children: assignments.map((a) {
                  final label =
                      '${a.standardName ?? "Class"} ${a.section} • ${a.subjectName ?? "Subject"}';
                  return Container(
                    constraints: const BoxConstraints(minHeight: 34),
                    padding: const EdgeInsets.only(
                      left: AppDimensions.space12,
                      right: AppDimensions.space8,
                      top: AppDimensions.space6,
                      bottom: AppDimensions.space6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface100,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusLarge),
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
                            ),
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: AppDimensions.space6),
                          GestureDetector(
                            onTap: isDeleting ? null : () => onDelete(a),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: isDeleting
                                  ? AppColors.grey400
                                  : AppColors.errorRed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AssignTeacherBottomSheet extends ConsumerStatefulWidget {
  const _AssignTeacherBottomSheet({required this.teacher});

  final TeacherModel teacher;

  @override
  ConsumerState<_AssignTeacherBottomSheet> createState() =>
      _AssignTeacherBottomSheetState();
}

class _AssignTeacherBottomSheetState
    extends ConsumerState<_AssignTeacherBottomSheet> {
  StandardModel? _selectedStandard;
  String? _selectedSection;
  SubjectModel? _selectedSubject;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final standardsAsync = ref.watch(standardsProvider(activeYear?.id));
    final sectionsAsync =
        ref.watch(sectionsByStandardProvider(_selectedStandard?.id));
    final subjectsAsync = ref.watch(subjectsProvider(_selectedStandard?.id));

    final standards = standardsAsync.valueOrNull ?? const <StandardModel>[];
    final subjects = subjectsAsync.valueOrNull ?? const <SubjectModel>[];
    final sections = sectionsAsync.valueOrNull ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.teacher.displayName,
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.navyDeep,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.space4),
        Text(
          widget.teacher.employeeCode,
          style: AppTypography.caption.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: AppDimensions.space16),
        DropdownButtonFormField<String?>(
          initialValue: _selectedStandard?.id,
          isExpanded: true,
          decoration: _fieldDecoration('Class'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Select class'),
            ),
            ...standards.map(
              (standard) => DropdownMenuItem<String?>(
                value: standard.id,
                child: Text(standard.name),
              ),
            ),
          ],
          onChanged: _submitting
              ? null
              : (standardId) {
                  final selected = standards.cast<StandardModel?>().firstWhere(
                        (s) => s?.id == standardId,
                        orElse: () => null,
                      );
                  setState(() {
                    _selectedStandard = selected;
                    _selectedSubject = null;
                    _selectedSection = null;
                  });
                },
        ),
        const SizedBox(height: AppDimensions.space12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedSection,
          isExpanded: true,
          decoration: _fieldDecoration('Section'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Select section'),
            ),
            ...sections.map(
              (section) => DropdownMenuItem<String?>(
                value: section,
                child: Text(section),
              ),
            ),
          ],
          onChanged: (_submitting || _selectedStandard == null)
              ? null
              : (section) => setState(() => _selectedSection = section),
        ),
        const SizedBox(height: AppDimensions.space12),
        DropdownButtonFormField<String?>(
          initialValue: _selectedSubject?.id,
          isExpanded: true,
          decoration: _fieldDecoration('Subject'),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Select subject'),
            ),
            ...subjects.map(
              (subject) => DropdownMenuItem<String?>(
                value: subject.id,
                child: Text('${subject.name} (${subject.code})'),
              ),
            ),
          ],
          onChanged: (_submitting || _selectedStandard == null)
              ? null
              : (subjectId) {
                  final selected = subjects.cast<SubjectModel?>().firstWhere(
                        (s) => s?.id == subjectId,
                        orElse: () => null,
                      );
                  setState(() => _selectedSubject = selected);
                },
        ),
        const SizedBox(height: AppDimensions.space12),
        if (activeYear != null)
          Text(
            'Academic Year: ${activeYear.name}',
            style: AppTypography.caption.copyWith(color: AppColors.grey600),
          ),
        if (_selectedStandard != null &&
            sections.isEmpty &&
            !sectionsAsync.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space8),
            child: Text(
              'No sections found for this class yet.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.warningAmber,
              ),
            ),
          ),
        const SizedBox(height: AppDimensions.space20),
        AppButton.primary(
          label: 'Assign Now',
          icon: Icons.check_circle_outline,
          isLoading: _submitting,
          onTap: _submitting ? null : () => _submit(activeYear?.id),
        ),
      ],
    );
  }

  Future<void> _submit(String? activeYearId) async {
    if (_selectedStandard == null ||
        _selectedSection == null ||
        _selectedSubject == null ||
        activeYearId == null) {
      SnackbarUtils.showError(
        context,
        'Please select class, section, subject and active academic year.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref.read(teacherNotifierProvider.notifier).createTeacherAssignment(
            teacherId: widget.teacher.id,
            standardId: _selectedStandard!.id,
            section: _selectedSection!,
            subjectId: _selectedSubject!.id,
            academicYearId: activeYearId,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.surface50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        borderSide: const BorderSide(color: AppColors.surface200),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
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
          Icon(
            icon,
            size: AppDimensions.iconSM,
            color: iconColor ?? AppColors.grey400,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption,
                ),
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
