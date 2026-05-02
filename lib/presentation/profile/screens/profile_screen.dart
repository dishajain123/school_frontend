import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/academic_year/academic_year_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_avatar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/profile_info_row.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isReenrollmentOpen(List<AcademicYearModel> years) {
    final now = DateTime.now();
    try {
      final activeYear = years.firstWhere((y) => y.isActive);
      return !now.isBefore(activeYear.endDate);
    } catch (_) {
      return false;
    }
  }

  String _reenrollmentOpenDateLabel(List<AcademicYearModel> years) {
    try {
      final activeYear = years.firstWhere((y) => y.isActive);
      return activeYear.endDate.toLocal().toIso8601String().split('T').first;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(userNotifierProvider.notifier).load());
    Future.microtask(() => ref.read(academicYearNotifierProvider.notifier).refresh());
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    try {
      await ref
          .read(userNotifierProvider.notifier)
          .uploadPhoto(File(picked.path));
      if (mounted) SnackbarUtils.showSuccess(context, 'Photo updated!');
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to upload photo.');
    }
  }

  Future<void> _logout() async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out?',
      confirmLabel: 'Sign Out',
    );
    if (confirmed == true && mounted) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  Future<void> _showAnnualReenrollmentDialog(CurrentUser user) async {
    await ref.read(academicYearNotifierProvider.notifier).refresh();
    if (!mounted) return;
    final years = ref.read(academicYearNotifierProvider).valueOrNull ?? [];
    final now = DateTime.now();
    final preferredYears = years
        .where((y) => !y.isActive && y.endDate.isAfter(now))
        .toList(growable: false)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final selectableYears = preferredYears.isNotEmpty
        ? preferredYears
        : years.where((y) => !y.isActive).toList(growable: false);
    final fallbackYears = selectableYears.isNotEmpty ? selectableYears : years;
    if (fallbackYears.isEmpty) {
      SnackbarUtils.showError(
        context,
        'No academic year available. Contact admin.',
      );
      return;
    }

    String selectedYearId = fallbackYears.first.id;
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Re-enroll for Academic Year'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select the next academic year to refresh your role data for the new cycle.',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedYearId,
                  decoration: const InputDecoration(
                    labelText: 'Academic Year',
                    border: OutlineInputBorder(),
                  ),
                  items: fallbackYears
                      .map(
                        (y) => DropdownMenuItem<String>(
                          value: y.id,
                          child: Text(
                            '${y.name}${y.isActive ? ' (Active)' : ''}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (value) {
                          if (value == null) return;
                          setLocal(() => selectedYearId = value);
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setLocal(() => submitting = true);
                      try {
                        await ref
                            .read(enrollmentNotifierProvider.notifier)
                            .annualReenrollUser(
                              userId: user.id,
                              academicYearId: selectedYearId,
                            );
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        await ref
                            .read(authNotifierProvider.notifier)
                            .initialize();
                        ref.invalidate(userNotifierProvider);
                        ref.invalidate(parentDashboardStatsProvider);
                        ref.invalidate(childrenNotifierProvider);
                        ref.invalidate(myTeacherAssignmentsProvider(null));
                        ref.invalidate(myStudentProfileProvider);
                        SnackbarUtils.showSuccess(
                          context,
                          'Re-enrollment completed for selected year.',
                        );
                      } catch (e) {
                        if (!mounted) return;
                        SnackbarUtils.showError(context, e.toString());
                      } finally {
                        if (ctx.mounted) {
                          setLocal(() => submitting = false);
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Re-enroll'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(currentUserProvider);
    final userAsync = ref.watch(userNotifierProvider);
    final years = ref.watch(academicYearNotifierProvider).valueOrNull ?? const [];
    final reenrollmentOpen = _isReenrollmentOpen(years);
    final reenrollmentOpenDate = _reenrollmentOpenDateLabel(years);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Profile', showBack: true),
      body: userAsync.when(
        loading: () => AppLoading.listView(count: 5),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: AppColors.errorRed),
              const SizedBox(height: 16),
              Text(e.toString(), style: AppTypography.bodyMedium),
              const SizedBox(height: 16),
              AppButton.secondary(
                label: 'Retry',
                onTap: () => ref.read(userNotifierProvider.notifier).load(),
                fullWidth: false,
              ),
            ],
          ),
        ),
        data: (user) {
          final displayUser = user;
          final resolvedName = authUser?.fullName?.trim();
          final name = (resolvedName != null && resolvedName.isNotEmpty)
              ? resolvedName
              : 'User';
          final isTeacher = authUser?.role == UserRole.teacher;
          final isStudent = authUser?.role == UserRole.student;
          final isParent = authUser?.role == UserRole.parent;
          final myAssignmentsAsync = isTeacher
              ? ref.watch(myTeacherAssignmentsProvider(null))
              : const AsyncData<List<TeacherClassSubjectModel>>([]);
          final AsyncValue<StudentModel?> myStudentProfileAsync = isStudent
              ? ref.watch(myStudentProfileProvider)
              : const AsyncData<StudentModel?>(null);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            child: Column(
              children: [
                const SizedBox(height: AppDimensions.space24),

                // Avatar
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AppAvatar.xl(
                      imageUrl: displayUser?.profilePhotoUrl,
                      name: name,
                    ),
                    GestureDetector(
                      onTap: _pickAndUploadPhoto,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.navyDeep,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 16, color: AppColors.white),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppDimensions.space16),

                Text(
                  name.isNotEmpty
                      ? name[0].toUpperCase() + name.substring(1)
                      : 'User',
                  style: AppTypography.headlineMedium,
                ),
                const SizedBox(height: AppDimensions.space4),

                if (authUser != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space4),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      _roleLabel(authUser.role.backendValue),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.navyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: AppDimensions.space32),

                // Info rows
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space16),
                  child: Column(
                    children: [
                      ProfileInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: displayUser?.email ?? authUser?.email ?? '—',
                      ),
                      const Divider(height: 1, color: AppColors.surface100),
                      ProfileInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: displayUser?.phone ?? authUser?.phone ?? '—',
                      ),
                      const Divider(height: 1, color: AppColors.surface100),
                      ProfileInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Academic Year',
                        value: (authUser?.academicYearName != null &&
                                authUser!.academicYearName!.trim().isNotEmpty)
                            ? authUser.academicYearName!
                            : (authUser?.academicYearId ?? '—'),
                      ),
                    ],
                  ),
                ),

                if (isTeacher) ...[
                  const SizedBox(height: AppDimensions.space16),
                  _TeacherAssignmentsCard(assignmentsAsync: myAssignmentsAsync),
                ],
                if (isStudent) ...[
                  const SizedBox(height: AppDimensions.space16),
                  _StudentClassAllocationCard(
                    studentProfileAsync: myStudentProfileAsync,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _LinkedParentCard(studentProfileAsync: myStudentProfileAsync),
                ],

                const SizedBox(height: AppDimensions.space16),

                // Actions
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  child: Column(
                    children: [
                      if (isStudent || isParent)
                        ListTile(
                          leading: const Icon(Icons.folder_shared_outlined,
                              color: AppColors.grey600),
                          title: Text(
                            isStudent ? 'My documents' : 'Student documents',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800),
                          ),
                          subtitle: Text(
                            isStudent
                                ? 'Upload PDFs required by your school'
                                : 'Upload or track documents for your child',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.grey500),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.grey400),
                          onTap: () => context.push(RouteNames.documents),
                        ),
                      if (isStudent || isParent)
                        const Divider(height: 1, color: AppColors.surface100),
                      ListTile(
                        leading: const Icon(Icons.lock_outlined,
                            color: AppColors.grey600),
                        title: Text('Change Password',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded,
                            size: 14, color: AppColors.grey400),
                        onTap: () => context.push(RouteNames.changePassword),
                      ),
                      if (authUser != null)
                        const Divider(height: 1, color: AppColors.surface100),
                      if (authUser != null)
                        ListTile(
                          leading: const Icon(Icons.autorenew_outlined,
                              color: AppColors.grey600),
                          title: Text(
                            'Re-enroll for Next Academic Year',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800),
                          ),
                          subtitle: Text(
                            reenrollmentOpen
                                ? 'Update your account context for the next academic year'
                                : (reenrollmentOpenDate.isEmpty
                                    ? 'Available after active academic year ends'
                                    : 'Available after $reenrollmentOpenDate'),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.grey500),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.grey400),
                          onTap: reenrollmentOpen
                              ? () => _showAnnualReenrollmentDialog(authUser)
                              : null,
                        ),
                      if (authUser != null &&
                          (authUser.role == UserRole.principal ||
                              authUser.role == UserRole.superadmin))
                        const Divider(height: 1, color: AppColors.surface100),
                      if (authUser != null &&
                          (authUser.role == UserRole.principal ||
                              authUser.role == UserRole.superadmin))
                        ListTile(
                          leading: const Icon(Icons.history_outlined,
                              color: AppColors.grey600),
                          title: Text(
                            'Audit Logs',
                            style: AppTypography.bodyMedium
                                .copyWith(color: AppColors.grey800),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.grey400),
                          onTap: () => context.push(RouteNames.auditLogs),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space32),

                AppButton.destructive(
                  label: 'Sign Out',
                  onTap: _logout,
                  icon: Icons.logout_rounded,
                ),

                const SizedBox(height: AppDimensions.space40),
              ],
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'SUPERADMIN':
        return 'Super Admin';
      case 'PRINCIPAL':
        return 'Principal';
      case 'TRUSTEE':
        return 'Trustee';
      case 'TEACHER':
        return 'Teacher';
      case 'STUDENT':
        return 'Student';
      case 'PARENT':
        return 'Parent';
      default:
        return role;
    }
  }
}

class _TeacherAssignmentsCard extends StatelessWidget {
  const _TeacherAssignmentsCard({required this.assignmentsAsync});

  final AsyncValue<List<TeacherClassSubjectModel>> assignmentsAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: assignmentsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teaching Assignments',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Unable to load assigned classes and subjects.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
        data: (assignments) {
          final subjectSet = <String>{};
          final classSectionSet = <String>{};
          for (final a in assignments) {
            final subjectLabel = a.subjectName ?? a.subjectId;
            if (subjectLabel.isNotEmpty) subjectSet.add(subjectLabel);

            final classLabel = a.standardName ?? a.standardId;
            final section = a.section.trim();
            final combined =
                section.isEmpty ? classLabel : '$classLabel - $section';
            if (combined.isNotEmpty) classSectionSet.add(combined);
          }

          final subjects = subjectSet.toList()..sort();
          final classSections = classSectionSet.toList()..sort();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Teaching Assignments',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              _AssignmentChipGroup(
                label: 'Subjects',
                values: subjects,
                emptyLabel: 'No subjects assigned',
              ),
              const SizedBox(height: AppDimensions.space12),
              _AssignmentChipGroup(
                label: 'Class Setup',
                values: classSections,
                emptyLabel: 'No classes assigned',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AssignmentChipGroup extends StatelessWidget {
  const _AssignmentChipGroup({
    required this.label,
    required this.values,
    required this.emptyLabel,
  });

  final String label;
  final List<String> values;
  final String emptyLabel;

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
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        if (values.isEmpty)
          Text(
            emptyLabel,
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey400),
          )
        else
          Wrap(
            spacing: AppDimensions.space8,
            runSpacing: AppDimensions.space8,
            children: values
                .map(
                  (value) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                      border: Border.all(
                        color: AppColors.navyLight.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      value,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

class _LinkedParentCard extends StatelessWidget {
  const _LinkedParentCard({required this.studentProfileAsync});

  final AsyncValue<StudentModel?> studentProfileAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: studentProfileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent Details',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Unable to load linked parent details.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
        data: (student) {
          final parent = student?.parent;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parent Details',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              if (parent == null) ...[
                Text(
                  'No linked parent details found.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),
              ] else ...[
                _ParentInfoLine(label: 'Name', value: parent.fullName),
                _ParentInfoLine(label: 'Relation', value: parent.relation),
                _ParentInfoLine(label: 'Phone', value: parent.phone),
                _ParentInfoLine(label: 'Email', value: parent.email),
                _ParentInfoLine(label: 'Occupation', value: parent.occupation),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _StudentClassAllocationCard extends ConsumerWidget {
  const _StudentClassAllocationCard({required this.studentProfileAsync});

  final AsyncValue<StudentModel?> studentProfileAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: studentProfileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Class Allocation',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Unable to load class and subject allocation.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
        data: (student) {
          final standardId = student?.standardId?.toString();
          final section = student?.section?.toString().trim();
          final academicYearId = student?.academicYearId?.toString();
          final standardsAsync = ref.watch(standardsProvider(academicYearId));
          final studentStandardName = student?.standardName?.toString().trim();
          String? resolvedClassLevel;
          final standards = standardsAsync.valueOrNull ?? const [];
          for (final standard in standards) {
            if (standard.id == standardId) {
              resolvedClassLevel = standard.level.toString();
              break;
            }
          }
          final standardLabel = (resolvedClassLevel != null)
              ? resolvedClassLevel
              : ((studentStandardName != null && studentStandardName.isNotEmpty)
                  ? studentStandardName
                  : (standardId ?? '—'));
          final sectionLabel =
              (section != null && section.isNotEmpty) ? section : '—';

          if (standardId == null || standardId.isEmpty || sectionLabel == '—') {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Class Allocation',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.grey800,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Class/section not assigned yet.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.grey600),
                ),
              ],
            );
          }

          final subjectsAsync = ref.watch(classTeachersProvider((
            standardId: standardId,
            section: sectionLabel,
            academicYearId: academicYearId,
          )));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Allocation',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Row(
                children: [
                  Expanded(
                    child:
                        _ParentInfoLine(label: 'Class', value: standardLabel),
                  ),
                  Expanded(
                    child:
                        _ParentInfoLine(label: 'Section', value: sectionLabel),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                'Subjects',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.space8),
              subjectsAsync.when(
                loading: () => Text(
                  'Loading subjects...',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.grey500),
                ),
                error: (_, __) => Text(
                  'Unable to load subjects.',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.errorRed),
                ),
                data: (rows) {
                  final subjectSet = <String>{};
                  for (final row in rows) {
                    final subject = row.subjectName?.trim().isNotEmpty == true
                        ? row.subjectName!.trim()
                        : row.subjectLabel;
                    if (subject.isNotEmpty) subjectSet.add(subject);
                  }
                  final subjects = subjectSet.toList()..sort();
                  if (subjects.isEmpty) {
                    return Text(
                      'No subjects assigned yet.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500),
                    );
                  }
                  return Wrap(
                    spacing: AppDimensions.space8,
                    runSpacing: AppDimensions.space8,
                    children: subjects
                        .map(
                          (value) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.space12,
                              vertical: AppDimensions.space6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.navyLight.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusFull),
                              border: Border.all(
                                color:
                                    AppColors.navyLight.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              value,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.navyDeep,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ParentInfoLine extends StatelessWidget {
  const _ParentInfoLine({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              (value == null || value!.trim().isEmpty) ? '—' : value!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
