import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_section_header.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/fee_due_banner.dart';
import '../widgets/greeting_header.dart';
import '../widgets/quick_action_grid.dart';
import '../widgets/stat_card.dart';

class ParentDashboard extends ConsumerStatefulWidget {
  const ParentDashboard({super.key});

  @override
  ConsumerState<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends ConsumerState<ParentDashboard> {
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
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLarge),
        ),
      ),
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
                if (mounted) {
                  setModalState(() => isSubmitting = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: AppDimensions.pageHorizontal,
                right: AppDimensions.pageHorizontal,
                top: AppDimensions.space16,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppDimensions.space16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Add Child', style: AppTypography.titleLarge),
                    const SizedBox(height: AppDimensions.space6),
                    Text(
                      'Enter admission number. If student is linked elsewhere, provide student credentials to relink.',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey600),
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    AppTextField(
                      controller: admissionController,
                      label: 'Student Admission Number',
                      hint: 'e.g. ADM1023',
                      prefixIconData: Icons.badge_outlined,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    AppTextField(
                      controller: emailController,
                      label: 'Student Email (optional)',
                      hint: 'student@email.com',
                      prefixIconData: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    AppTextField(
                      controller: phoneController,
                      label: 'Student Phone (optional)',
                      hint: '+91 9876543210',
                      prefixIconData: Icons.phone_outlined,
                    ),
                    const SizedBox(height: AppDimensions.space12),
                    AppTextField(
                      controller: passwordController,
                      label: 'Student Password (optional)',
                      hint: 'Required only for relink',
                      obscureText: true,
                      prefixIconData: Icons.lock_outline,
                    ),
                    const SizedBox(height: AppDimensions.space16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isSubmitting ? null : submit,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
    final quickActions = [
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
    ];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(childrenNotifierProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: GreetingHeader(
                subtitle: "Stay connected with your child's progress.",
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: AppDimensions.space8),
                  _ChildSwitcherCard(
                    childrenAsync: childrenAsync,
                    onSelectChild: (id) => ref
                        .read(childrenNotifierProvider.notifier)
                        .selectChild(id),
                    onAddChild: _showAddChildSheet,
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  FeeDueBanner(
                    amountDue: 0,
                    onTap: () => context.go(RouteNames.feeDashboard),
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppDimensions.space12),
                  QuickActionGrid(actions: quickActions),
                  const SizedBox(height: AppDimensions.space24),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Attendance',
                          value: '--%',
                          icon: Icons.fact_check_outlined,
                          iconColor: AppColors.successGreen,
                          onTap: () => context.go(RouteNames.attendance),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: StatCard(
                          label: 'Fee Due',
                          value: '₹--',
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: AppColors.warningAmber,
                          onTap: () => context.go(RouteNames.feeDashboard),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space40),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildSwitcherCard extends StatelessWidget {
  const _ChildSwitcherCard({
    required this.childrenAsync,
    required this.onSelectChild,
    required this.onAddChild,
  });

  final AsyncValue<ChildrenState> childrenAsync;
  final void Function(String childId) onSelectChild;
  final VoidCallback onAddChild;

  @override
  Widget build(BuildContext context) {
    final state = childrenAsync.valueOrNull ?? const ChildrenState();
    final children = state.children;
    final selected = state.selectedChildId;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Child Profile',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.navyDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddChild,
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add Child'),
              ),
            ],
          ),
          if (childrenAsync.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.space8),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (children.isEmpty)
            Text(
              'No child linked yet. Use Add Child.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.grey600),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: selected ?? children.first.id,
              items: children
                  .map(
                    (child) => DropdownMenuItem<String>(
                      value: child.id,
                      child: Text(
                        child.admissionNumber,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onSelectChild(value);
              },
              decoration: const InputDecoration(
                labelText: 'Select Child',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
        ],
      ),
    );
  }
}
