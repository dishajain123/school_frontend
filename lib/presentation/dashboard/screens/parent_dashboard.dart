import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_section_header.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/child_selector.dart';
import '../widgets/greeting_header.dart';
import '../widgets/needs_attention_section.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
  static String _compactAmount(double amount) {
    if (amount >= 10000000) {
      return '${(amount / 10000000).toStringAsFixed(1)}Cr';
    }
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(childrenNotifierProvider.notifier).loadMyChildren();
    });
  }

  Future<void> _showAddChildSheet() async {
    final admissionController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> submit() async {
              final admission = admissionController.text.trim();
              final email = emailController.text.trim();
              final phone = phoneController.text.trim();
              final password = passwordController.text;

              if (admission.isEmpty) {
                SnackbarUtils.showError(
                    context, 'Enter student admission number.');
                return;
              }

              setModalState(() => isSubmitting = true);
              try {
                await ref.read(childrenNotifierProvider.notifier).linkChild(
                      admissionNumber: admission,
                      studentEmail: email.isEmpty ? null : email,
                      studentPhone: phone.isEmpty ? null : phone,
                      studentPassword: password.isEmpty ? null : password,
                    );
                if (!context.mounted) return;
                SnackbarUtils.showSuccess(
                    context, 'Child linked successfully.');
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                SnackbarUtils.showError(context, e.toString());
              } finally {
                if (mounted) setModalState(() => isSubmitting = false);
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 16),
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.surface200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.navyDeep.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_add_alt_1_rounded,
                              size: 20, color: AppColors.navyDeep),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add Child',
                                style: AppTypography.titleLarge
                                    .copyWith(fontWeight: FontWeight.w700)),
                            Text('Link a student to your account',
                                style: AppTypography.caption
                                    .copyWith(color: AppColors.grey500)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: admissionController,
                      label: 'Student Admission Number',
                      hint: 'e.g. ADM1023',
                      prefixIconData: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: emailController,
                      label: 'Student Email (optional)',
                      hint: 'student@email.com',
                      prefixIconData: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: phoneController,
                      label: 'Student Phone (optional)',
                      hint: '+91 9876543210',
                      prefixIconData: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: passwordController,
                      label: 'Student Password (optional)',
                      hint: 'Required only for relink',
                      obscureText: true,
                      prefixIconData: Icons.lock_outline,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.navyDeep,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.white),
                              )
                            : const Text('Link Child'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenNotifierProvider);
    final childrenState = childrenAsync.valueOrNull ?? const ChildrenState();
    final linkedChildrenCount = childrenState.children.length;
    final childrenLoading = childrenAsync.isLoading && childrenState.children.isEmpty;
    final selectedChild = ref.watch(selectedChildProvider);
    final statsAsync = ref.watch(parentDashboardStatsProvider);
    final stats = statsAsync.valueOrNull;
    final hasStats = stats != null;
    final statsLoading = statsAsync.isLoading;

    final openComplaints = hasStats ? stats.openComplaints : 0;
    final outstandingFees = hasStats ? stats.outstandingFeesAmount : 0.0;

    final attentionItems = [
      if (hasStats && outstandingFees > 0)
        AttentionItem(
          label: 'Fee Due: ₹${_compactAmount(outstandingFees)}',
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.warningAmber,
          onTap: () => context.go(RouteNames.feeDashboard),
        ),
      if (hasStats && openComplaints > 0)
        AttentionItem(
          label:
              '$openComplaints Open Complaint${openComplaints == 1 ? '' : 's'}',
          icon: Icons.feedback_outlined,
          color: AppColors.errorRed,
          count: openComplaints,
          onTap: () => context.go(RouteNames.complaints),
        ),
    ];

    final primaryActions = [
      QuickActionItem(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: AppColors.successGreen,
        onTap: () => context.go(RouteNames.attendance),
      ),
      QuickActionItem(
        icon: Icons.home_work_outlined,
        label: 'Homework',
        color: AppColors.subjectMath,
        onTap: () => context.go(RouteNames.homework),
      ),
      QuickActionItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Fees',
        color: AppColors.goldPrimary,
        onTap: () => context.go(RouteNames.feeDashboard),
      ),
      QuickActionItem(
        icon: Icons.assignment_outlined,
        label: 'Assignments',
        color: AppColors.infoBlue,
        onTap: () => context.go(RouteNames.assignments),
      ),
    ];

    final secondaryActions = [
      QuickActionItem(
        icon: Icons.quiz_outlined,
        label: 'Exams',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.examSchedules),
      ),
      QuickActionItem(
        icon: Icons.bar_chart_outlined,
        label: 'Results',
        color: AppColors.subjectScience,
        onTap: () => context.go(RouteNames.results),
      ),
      QuickActionItem(
        icon: Icons.description_outlined,
        label: 'Documents',
        color: AppColors.subjectChem,
        onTap: () => context.go(RouteNames.documents),
      ),
      QuickActionItem(
        icon: Icons.feedback_outlined,
        label: 'Complaints',
        color: AppColors.errorRed,
        onTap: () => context.go(RouteNames.complaints),
      ),
      QuickActionItem(
        icon: Icons.photo_library_outlined,
        label: 'Gallery',
        color: AppColors.subjectPhysics,
        onTap: () => context.go(RouteNames.galleryAlbums),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childrenNotifierProvider.notifier).refresh();
          ref.invalidate(classTeachersProvider);
          ref.invalidate(parentDashboardStatsProvider);
          await ref.read(parentDashboardStatsProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: "Stay connected with your child's progress.",
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.pageHorizontal,
                AppDimensions.space20,
                AppDimensions.pageHorizontal,
                100,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!hasStats && statsAsync.hasError)
                    _ParentStatsError(
                      onRetry: () => ref.invalidate(parentDashboardStatsProvider),
                    )
                  else
                    _ParentStatsGrid(
                      stats: stats,
                      isLoading: statsLoading,
                      linkedChildrenCount: linkedChildrenCount,
                      linkedChildrenLoading: childrenLoading,
                    ),
                  if (attentionItems.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.space12),
                    NeedsAttentionSection(items: attentionItems),
                  ],
                  const SizedBox(height: AppDimensions.space16),
                  ChildSelector(
                    childrenAsync: childrenAsync,
                    onSelectChild: (id) => ref
                        .read(childrenNotifierProvider.notifier)
                        .selectChild(id),
                    onAddChild: _showAddChildSheet,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _ParentClassTeachersCard(selectedChild: selectedChild),
                  const SizedBox(height: AppDimensions.space20),
                  const AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(
                    actions: [...primaryActions, ...secondaryActions],
                    primaryCount: 4,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentStatsGrid extends StatelessWidget {
  const _ParentStatsGrid({
    required this.stats,
    required this.isLoading,
    required this.linkedChildrenCount,
    required this.linkedChildrenLoading,
  });
  final dynamic stats;
  final bool isLoading;
  final int linkedChildrenCount;
  final bool linkedChildrenLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'My Children',
                value: linkedChildrenCount.toString(),
                icon: Icons.family_restroom_outlined,
                iconColor: AppColors.navyMedium,
                isLoading: linkedChildrenLoading,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Class Teachers',
                value: (stats?.classTeachers ?? 0).toString(),
                icon: Icons.co_present_outlined,
                iconColor: AppColors.infoBlue,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Outstanding Fees',
                value:
                    '₹${_ParentDashboardState._compactAmount(stats?.outstandingFeesAmount ?? 0)}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.warningAmber,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.feeDashboard),
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: StatCard(
                label: 'Complaints',
                value: (stats?.openComplaints ?? 0).toString(),
                icon: Icons.feedback_outlined,
                iconColor: AppColors.errorRed,
                isLoading: isLoading,
                onTap: () => context.go(RouteNames.complaints),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParentStatsError extends StatelessWidget {
  const _ParentStatsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load stats from backend',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.errorRed,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap retry to fetch latest parent dashboard counts.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey500),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _ParentClassTeachersCard extends ConsumerWidget {
  const _ParentClassTeachersCard({required this.selectedChild});
  final ChildSummaryModel? selectedChild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = selectedChild;
    if (child == null) {
      return _ClassTeachersShell(
        child: Text('Select a child to view class teachers.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
      );
    }

    final standardId = child.standardId;
    final section = child.section?.trim();
    final yearId = child.academicYearId;
    final sectionLabel = section != null && section.isNotEmpty
        ? 'Section $section'
        : 'Section not set';

    if (standardId == null ||
        standardId.isEmpty ||
        section == null ||
        section.isEmpty) {
      return _ClassTeachersShell(
        sectionLabel: sectionLabel,
        child: Text('Class/section is not available for selected child.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
      );
    }

    final teachersAsync = ref.watch(classTeachersProvider((
      standardId: standardId,
      section: section,
      academicYearId: yearId,
    )));

    return _ClassTeachersShell(
      sectionLabel: sectionLabel,
      child: teachersAsync.when(
        loading: () => Text('Loading teachers...',
            style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
        error: (e, _) => Text('Could not load teachers.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed)),
        data: (rows) => _TeachersList(rows: rows),
      ),
    );
  }
}

class _ClassTeachersShell extends StatelessWidget {
  const _ClassTeachersShell({required this.child, this.sectionLabel});
  final String? sectionLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: AppColors.surface100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.co_present_outlined,
                    size: 16, color: AppColors.navyDeep),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Class Teachers',
                      style: AppTypography.titleSmall.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700)),
                  if (sectionLabel != null)
                    Text(sectionLabel!,
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TeachersList extends StatelessWidget {
  const _TeachersList({required this.rows});
  final List<TeacherClassSubjectModel> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Text('No teacher assignments found.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.grey500));
    }

    final byTeacher = <String, List<TeacherClassSubjectModel>>{};
    for (final r in rows) {
      final code = r.teacherEmployeeCode ?? 'Teacher';
      final key = '${r.teacherId}|$code';
      byTeacher.putIfAbsent(key, () => []).add(r);
    }

    return Column(
      children: byTeacher.entries.map((entry) {
        final teacherRows = entry.value;
        final first = teacherRows.first;
        final teacherCode =
            (first.teacherEmployeeCode?.trim().isNotEmpty ?? false)
                ? first.teacherEmployeeCode!
                : 'Teacher';
        final subjects = teacherRows.map((r) => r.subjectLabel).toSet().toList()
          ..sort();

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.surface100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline,
                    size: 14, color: AppColors.navyMedium),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(teacherCode,
                        style: AppTypography.labelMedium.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600)),
                    Text(subjects.join(', '),
                        style: AppTypography.caption
                            .copyWith(color: AppColors.grey500)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
