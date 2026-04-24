import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/fee/fee_ledger_model.dart';
import '../../../data/models/fee/fee_structure_model.dart';
import '../../../data/repositories/fee_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/fee_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/fee_ledger_card.dart';
import '../widgets/fee_summary_bar.dart';

class FeeDashboardScreen extends ConsumerWidget {
  const FeeDashboardScreen({super.key, this.studentId});

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    switch (user.role) {
      case UserRole.parent:
        return _ParentFeeDashboard(explicitStudentId: studentId);
      case UserRole.student:
        return _StudentFeeDashboard(explicitStudentId: studentId);
      default:
        final isLeadership = user.role == UserRole.principal ||
            user.role == UserRole.trustee ||
            user.role == UserRole.superadmin;

        if (isLeadership && (studentId == null || studentId!.isEmpty)) {
          return const _PrincipalFeeAnalyticsDashboard();
        }

        final id = studentId ??
            GoRouterState.of(context).uri.queryParameters['student_id'];
        if (id == null || id.isEmpty) {
          return _buildSelectStudentState(context);
        }
        final activeYearId = ref.watch(activeYearProvider)?.id;
        return _FeeDashboardBody(
          studentId: id,
          user: user,
          academicYearId: activeYearId,
        );
    }
  }

  Widget _buildSelectStudentState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Fee Management', showBack: true),
      body: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Student Selected',
        subtitle: 'Access fee details from a student\'s profile page.',
        actionLabel: 'Go to Students',
        onAction: () => context.go(RouteNames.students),
      ),
    );
  }
}

// ── Parent wrapper ────────────────────────────────────────────────────────────

class _ParentFeeDashboard extends ConsumerWidget {
  const _ParentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final childId = explicitStudentId ?? ref.watch(selectedChildIdProvider);

    if (childId == null || childId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppEmptyState(
          icon: Icons.family_restroom_outlined,
          title: 'No Child Selected',
          subtitle: 'Select your child from the dashboard to view fees.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go(RouteNames.dashboard),
        ),
      );
    }

    final activeYearId = ref.watch(activeYearProvider)?.id;
    return _FeeDashboardBody(
      studentId: childId,
      user: user,
      academicYearId: activeYearId,
    );
  }
}

// ── Student wrapper ───────────────────────────────────────────────────────────

class _StudentFeeDashboard extends ConsumerWidget {
  const _StudentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;

    if (explicitStudentId != null) {
      final activeYearId = ref.watch(activeYearProvider)?.id;
      return _FeeDashboardBody(
        studentId: explicitStudentId!,
        user: user,
        academicYearId: activeYearId,
      );
    }

    final myIdAsync = ref.watch(myStudentIdProvider);

    return myIdAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppLoading.fullPage(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppErrorState(
          message: 'Could not load your student profile.',
          onRetry: () => ref.invalidate(myStudentIdProvider),
        ),
      ),
      data: (id) {
        if (id == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface50,
            appBar: AppAppBar(title: 'Fee Management', showBack: true),
            body: AppEmptyState(
              icon: Icons.school_outlined,
              title: 'Profile Not Found',
              subtitle:
                  'Your student profile could not be located. Please contact your administrator.',
            ),
          );
        }
        final activeYearId = ref.watch(activeYearProvider)?.id;
        return _FeeDashboardBody(
          studentId: id,
          user: user,
          academicYearId: activeYearId,
        );
      },
    );
  }
}

// ── Principal analytics dashboard ────────────────────────────────────────────

class _PrincipalFeeAnalyticsDashboard extends ConsumerStatefulWidget {
  const _PrincipalFeeAnalyticsDashboard();

  @override
  ConsumerState<_PrincipalFeeAnalyticsDashboard> createState() =>
      _PrincipalFeeAnalyticsDashboardState();
}

class _PrincipalFeeAnalyticsDashboardState
    extends ConsumerState<_PrincipalFeeAnalyticsDashboard> {
  static const String _allClassesOptionValue = '__ALL_CLASSES__';
  String? _standardId;
  String? _section;
  String? _studentId;

  String _currency(dynamic v) {
    final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return '₹${d.toStringAsFixed(2)}';
  }

  Future<void> _generateLedger(String? academicYearId) async {
    if (_standardId == null || _standardId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Select a class first to generate ledger.')),
      );
      return;
    }

    try {
      final repo = ref.read(feeRepositoryProvider);
      final result = await repo.generateLedger(
        standardId: _standardId!,
        academicYearId: academicYearId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ledger generated. Created: ${result.created}, Skipped: ${result.skipped}',
          ),
          backgroundColor: AppColors.successGreen,
        ),
      );
      ref.invalidate(feeAnalyticsProvider);
      ref.invalidate(feeStructuresProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate ledger: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _openEditStructureSheet(
    FeeStructureModel structure,
    String? academicYearId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final headCtrl = TextEditingController(text: structure.displayLabel);
    final amountCtrl =
        TextEditingController(text: structure.amount.toStringAsFixed(2));
    final descriptionCtrl =
        TextEditingController(text: structure.description ?? '');
    var dueDate = structure.dueDate;
    var applyToAllClasses = false;
    var isSubmitting = false;
    var isSheetOpen = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space16,
                  AppDimensions.space16,
                  AppDimensions.space16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Edit Fee Structure',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      TextField(
                        controller: headCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Fee Head',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      TextField(
                        controller: descriptionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: dueDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setModalState(() => dueDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('Select Date'),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        value: applyToAllClasses,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Apply to all classes'),
                        subtitle: const Text(
                          'Updates this fee head in every class for the same academic year.',
                        ),
                        onChanged: (value) =>
                            setModalState(() => applyToAllClasses = value),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final head = headCtrl.text.trim();
                                  final amount =
                                      double.tryParse(amountCtrl.text.trim());
                                  if (head.isEmpty) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Fee head is required.'),
                                      ),
                                    );
                                    return;
                                  }
                                  if (amount == null || amount <= 0) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Enter a valid amount.'),
                                      ),
                                    );
                                    return;
                                  }
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final repo =
                                        ref.read(feeRepositoryProvider);
                                    final result = await repo.updateStructure(
                                      structureId: structure.id,
                                      payload: {
                                        'custom_fee_head': head,
                                        'amount': amount,
                                        'due_date':
                                            '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                                        'description':
                                            descriptionCtrl.text.trim().isEmpty
                                                ? null
                                                : descriptionCtrl.text.trim(),
                                        'apply_to_all_classes':
                                            applyToAllClasses,
                                      },
                                    );
                                    if (!mounted || !ctx.mounted) return;
                                    isSheetOpen = false;
                                    Navigator.of(ctx).pop();
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Updated fee structure for ${result.total} class(es).',
                                          ),
                                          backgroundColor:
                                              AppColors.successGreen,
                                        ),
                                      );
                                      ref.invalidate(feeAnalyticsProvider);
                                      ref.invalidate(feeStructuresProvider);
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update: $e'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  } finally {
                                    if (isSheetOpen && ctx.mounted) {
                                      setModalState(() => isSubmitting = false);
                                    }
                                  }
                                },
                          child: Text(
                              isSubmitting ? 'Updating...' : 'Update Fee Head'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    headCtrl.dispose();
    amountCtrl.dispose();
    descriptionCtrl.dispose();
  }

  Future<void> _openCreateStructureSheet(String? academicYearId) async {
    List<dynamic> standards;
    try {
      standards = await ref.read(standardsProvider(academicYearId).future);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load classes: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (standards.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No classes found for the active year.')),
      );
      return;
    }

    if (!mounted) return;

    final descriptionCtrl = TextEditingController();
    var selectedStandardId = _standardId ?? _allClassesOptionValue;
    final feeHeadControllers = <TextEditingController>[TextEditingController()];
    final amountControllers = <TextEditingController>[TextEditingController()];
    var dueDate = DateTime.now().add(const Duration(days: 30));
    var isSubmitting = false;
    var isSheetOpen = true;
    final messenger = ScaffoldMessenger.of(context);

    void addFeeHeadRow() {
      feeHeadControllers.add(TextEditingController());
      amountControllers.add(TextEditingController());
    }

    void removeFeeHeadRow(int index) {
      if (feeHeadControllers.length <= 1) return;
      feeHeadControllers.removeAt(index).dispose();
      amountControllers.removeAt(index).dispose();
    }

    double selectedTotal() {
      var total = 0.0;
      for (final controller in amountControllers) {
        final amount = double.tryParse(controller.text.trim()) ?? 0.0;
        if (amount > 0) total += amount;
      }
      return total;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space16,
                  AppDimensions.space16,
                  AppDimensions.space16 + MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create Fee Structure',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      _FilterDropdown<String>(
                        hint: 'Class',
                        value: selectedStandardId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: _allClassesOptionValue,
                            child: Text('All Classes'),
                          ),
                          ...standards.map(
                            (s) => DropdownMenuItem<String>(
                              value: s.id as String,
                              child: Text(s.name as String),
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() => selectedStandardId = v);
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Add Fee Heads & Amount',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space6),
                      ...List.generate(feeHeadControllers.length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.space8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: feeHeadControllers[index],
                                  decoration: InputDecoration(
                                    isDense: true,
                                    labelText: 'Fee Head ${index + 1}',
                                    hintText: 'e.g. Computer Lab',
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space8),
                              SizedBox(
                                width: 130,
                                child: TextField(
                                  controller: amountControllers[index],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  onChanged: (_) => setModalState(() {}),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Amount',
                                    hintText: '0.00',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space4),
                              IconButton(
                                onPressed: feeHeadControllers.length == 1
                                    ? null
                                    : () => setModalState(
                                          () => removeFeeHeadRow(index),
                                        ),
                                icon: const Icon(Icons.remove_circle_outline),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setModalState(addFeeHeadRow),
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Fee Head'),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface50,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: AppColors.surface200),
                        ),
                        child: Text(
                          'Total: ${_currency(selectedTotal())}',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      TextField(
                        controller: descriptionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Due: ${dueDate.day}/${dueDate.month}/${dueDate.year}',
                              style: AppTypography.bodyMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: dueDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 3650)),
                              );
                              if (picked != null) {
                                setModalState(() => dueDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('Select Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final feeHeads = <Map<String, dynamic>>[];
                                  for (var i = 0;
                                      i < feeHeadControllers.length;
                                      i++) {
                                    final head =
                                        feeHeadControllers[i].text.trim();
                                    final amount = double.tryParse(
                                      amountControllers[i].text.trim(),
                                    );
                                    if (head.isEmpty &&
                                        (amount == null || amount <= 0)) {
                                      continue;
                                    }
                                    if (head.isEmpty) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Enter fee head name for row ${i + 1}.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (amount == null || amount <= 0) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Enter valid amount for "$head".',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    feeHeads.add({
                                      'name': head,
                                      'amount': amount,
                                    });
                                  }

                                  if (feeHeads.isEmpty) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Add at least one fee head with amount.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  final totalAmount = selectedTotal();
                                  final applyToAllClasses =
                                      selectedStandardId ==
                                          _allClassesOptionValue;
                                  setModalState(() => isSubmitting = true);
                                  try {
                                    final repo =
                                        ref.read(feeRepositoryProvider);
                                    final result =
                                        await repo.createStructuresBatch({
                                      if (!applyToAllClasses)
                                        'standard_id': selectedStandardId,
                                      if (applyToAllClasses)
                                        'apply_to_all_classes': true,
                                      if (applyToAllClasses)
                                        'standard_ids': standards
                                            .map((s) => s.id as String)
                                            .toList(),
                                      if (academicYearId != null)
                                        'academic_year_id': academicYearId,
                                      'due_date':
                                          '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                                      if (descriptionCtrl.text
                                          .trim()
                                          .isNotEmpty)
                                        'description':
                                            descriptionCtrl.text.trim(),
                                      'fee_heads': feeHeads,
                                    });
                                    if (!mounted) return;
                                    if (!ctx.mounted) return;
                                    isSheetOpen = false;
                                    Navigator.of(ctx).pop();
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!mounted) return;
                                      setState(() {
                                        _standardId = applyToAllClasses
                                            ? null
                                            : selectedStandardId;
                                        _section = null;
                                        _studentId = null;
                                      });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Saved ${result.items.length} fee heads for ${applyToAllClasses ? 'all classes' : 'selected class'} (Created: ${result.created}, Updated: ${result.updated}). Total ${_currency(totalAmount)}.',
                                          ),
                                          backgroundColor:
                                              AppColors.successGreen,
                                        ),
                                      );
                                      ref.invalidate(feeAnalyticsProvider);
                                      ref.invalidate(feeStructuresProvider);
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Failed to create structure: $e'),
                                        backgroundColor: AppColors.errorRed,
                                      ),
                                    );
                                  } finally {
                                    if (isSheetOpen && ctx.mounted) {
                                      setModalState(() => isSubmitting = false);
                                    }
                                  }
                                },
                          child: Text(
                            isSubmitting ? 'Saving...' : 'Create Structure',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    for (final controller in feeHeadControllers) {
      controller.dispose();
    }
    for (final controller in amountControllers) {
      controller.dispose();
    }
    descriptionCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final user = ref.watch(currentUserProvider);
    final canManageFees = user?.hasPermission('fee:create') ?? false;
    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    final sectionsAsync = ref.watch(studentSectionsProvider(_standardId));
    final studentsAsync = ref.watch(feeReportStudentsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
    )));
    final analyticsAsync = ref.watch(feeAnalyticsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
      studentId: _studentId,
    )));
    final structuresAsync = ref.watch(feeStructuresProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Management',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.invalidate(feeAnalyticsProvider);
              ref.invalidate(feeStructuresProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space16,
              AppDimensions.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    Expanded(
                      child: standardsAsync.when(
                        data: (standards) => _FilterDropdown<String?>(
                          hint: 'Class',
                          value: _standardId,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All Classes')),
                            ...standards.map(
                              (s) => DropdownMenuItem(
                                  value: s.id, child: Text(s.name)),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _standardId = v;
                            _section = null;
                            _studentId = null;
                          }),
                        ),
                        loading: () => AppLoading.listTile(),
                        error: (e, _) => AppErrorState(message: e.toString()),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Expanded(
                      child: sectionsAsync.when(
                        data: (sections) => _FilterDropdown<String?>(
                          hint: 'Section',
                          value: _section,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All')),
                            ...sections.map(
                              (s) => DropdownMenuItem(
                                  value: s, child: Text('Sec $s')),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _section = v;
                            _studentId = null;
                          }),
                        ),
                        loading: () => AppLoading.listTile(),
                        error: (e, _) => AppErrorState(message: e.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                studentsAsync.when(
                  data: (students) => _FilterDropdown<String?>(
                    hint: 'Student',
                    value: _studentId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Students')),
                      ...students.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                              '${s.admissionNumber} (${s.section ?? '-'})'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _studentId = v),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (e, _) => AppErrorState(message: e.toString()),
                ),
                if (canManageFees) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _openCreateStructureSheet(activeYearId),
                          icon: const Icon(Icons.add_card_rounded, size: 18),
                          label: const Text('Create Structure'),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _generateLedger(activeYearId),
                          icon: const Icon(Icons.sync_rounded, size: 18),
                          label: const Text('Generate Ledger'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Content
          Expanded(
            child: analyticsAsync.when(
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (data) {
                final summary =
                    Map<String, dynamic>.from(data['summary'] as Map? ?? {});
                final byCategory = List<Map<String, dynamic>>.from(
                    data['by_category'] as List? ?? []);
                final byStatus = List<Map<String, dynamic>>.from(
                    data['by_status'] as List? ?? []);
                final byPaymentMode = List<Map<String, dynamic>>.from(
                    data['by_payment_mode'] as List? ?? []);
                final byStudent = List<Map<String, dynamic>>.from(
                    data['by_student'] as List? ?? []);

                return ListView(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  children: [
                    if (canManageFees) ...[
                      const AppSectionHeader(title: 'Configured Fee Structure'),
                      const SizedBox(height: AppDimensions.space8),
                      if (_standardId == null)
                        const _AnalyticsEmptyState(
                          message:
                              'Select a class to view the configured fee heads.',
                        )
                      else
                        structuresAsync.when(
                          loading: () => AppLoading.listTile(),
                          error: (e, _) => AppErrorState(message: e.toString()),
                          data: (structures) {
                            if (structures.isEmpty) {
                              return const _AnalyticsEmptyState(
                                message:
                                    'No fee structure created for selected class/year.',
                              );
                            }
                            final total = structures.fold<double>(
                              0,
                              (sum, item) => sum + item.amount,
                            );
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusLarge,
                                ),
                                border: Border.all(color: AppColors.surface200),
                              ),
                              padding: const EdgeInsets.all(
                                AppDimensions.space12,
                              ),
                              child: Column(
                                children: [
                                  ...structures.map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppDimensions.space8,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.feeCategory.icon,
                                            size: 18,
                                            color: item.feeCategory.color,
                                          ),
                                          const SizedBox(
                                            width: AppDimensions.space8,
                                          ),
                                          Expanded(
                                            child: Text(
                                              item.displayLabel,
                                              style: AppTypography.bodyMedium
                                                  .copyWith(
                                                color: AppColors.navyDeep,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _currency(item.amount),
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                              color: AppColors.navyDeep,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          if (canManageFees) ...[
                                            const SizedBox(
                                              width: AppDimensions.space8,
                                            ),
                                            IconButton(
                                              onPressed: () =>
                                                  _openEditStructureSheet(
                                                item,
                                                activeYearId,
                                              ),
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                              ),
                                              tooltip: 'Edit Fee Head',
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Divider(height: AppDimensions.space16),
                                  Row(
                                    children: [
                                      Text(
                                        'Total',
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          color: AppColors.navyDeep,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _currency(total),
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          color: AppColors.successGreen,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: AppDimensions.space24),
                    ],
                    // KPI metric grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppDimensions.space12,
                      mainAxisSpacing: AppDimensions.space12,
                      childAspectRatio: 2.1,
                      children: [
                        _MetricCard(
                          title: 'Total Billed',
                          value: _currency(summary['total_billed_amount']),
                          icon: Icons.receipt_long_rounded,
                          accent: AppColors.navyMedium,
                        ),
                        _MetricCard(
                          title: 'Total Paid',
                          value: _currency(summary['total_paid_amount']),
                          icon: Icons.check_circle_outline_rounded,
                          accent: AppColors.successGreen,
                        ),
                        _MetricCard(
                          title: 'Outstanding',
                          value: _currency(summary['total_outstanding_amount']),
                          icon: Icons.pending_outlined,
                          accent: AppColors.warningAmber,
                        ),
                        _MetricCard(
                          title: 'Collection',
                          value:
                              '${(summary['collection_percentage'] ?? 0).toString()}%',
                          icon: Icons.pie_chart_outline_rounded,
                          accent: AppColors.infoBlue,
                        ),
                        _MetricCard(
                          title: 'Students',
                          value: '${summary['total_students'] ?? 0}',
                          icon: Icons.people_outline_rounded,
                          accent: AppColors.navyLight,
                        ),
                        _MetricCard(
                          title: 'Overdue',
                          value: '${summary['overdue_ledgers'] ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          accent: AppColors.errorRed,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space24),
                    const AppSectionHeader(title: 'Category Breakdown'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Category',
                        'Billed',
                        'Paid',
                        'Outstanding',
                        'Ledgers'
                      ],
                      rows: byCategory
                          .map((r) => [
                                (r['fee_category'] ?? '-').toString(),
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                                '${r['ledgers'] ?? 0}',
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    const AppSectionHeader(title: 'Status Breakdown'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Status',
                        'Ledgers',
                        'Billed',
                        'Paid',
                        'Outstanding'
                      ],
                      rows: byStatus
                          .map((r) => [
                                (r['status'] ?? '-').toString(),
                                '${r['ledgers'] ?? 0}',
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    const AppSectionHeader(title: 'Payment Mode'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const ['Mode', 'Amount', 'Transactions'],
                      rows: byPaymentMode
                          .map((r) => [
                                (r['payment_mode'] ?? '-').toString(),
                                _currency(r['amount']),
                                '${r['transactions'] ?? 0}',
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    AppSectionHeader(
                      title: 'Student Analysis (${byStudent.length})',
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Student',
                        'Class',
                        'Sec',
                        'Billed',
                        'Paid',
                        'Outstanding',
                        'Paid/Partial/Pending',
                        'Overdue',
                        'Latest Payment',
                      ],
                      rows: byStudent
                          .map((r) => [
                                (r['admission_number'] ?? '-').toString(),
                                (r['standard_id'] ?? '-').toString(),
                                (r['section'] ?? '-').toString(),
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                                '${r['paid_ledgers'] ?? 0}/${r['partial_ledgers'] ?? 0}/${r['pending_ledgers'] ?? 0}',
                                '${r['overdue_ledgers'] ?? 0}',
                                (r['latest_payment_date'] ?? '-').toString(),
                              ])
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.space40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        filled: true,
        fillColor: AppColors.surface50,
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 18, color: AppColors.grey400),
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Text(
        message,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
      ),
    );
  }
}

class _AnalyticsTable extends StatelessWidget {
  const _AnalyticsTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.table_chart_outlined,
        title: 'No data',
        subtitle: 'Try adjusting filters.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface50),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          headingRowHeight: 40,
          dividerThickness: 1,
          columnSpacing: AppDimensions.space16,
          columns: headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map((c) => DataCell(
                            Text(c, style: AppTypography.bodySmall),
                          ))
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
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

// ── Main dashboard body ───────────────────────────────────────────────────────

class _FeeDashboardBody extends ConsumerWidget {
  const _FeeDashboardBody({
    required this.studentId,
    required this.user,
    required this.academicYearId,
  });

  final String studentId;
  final CurrentUser user;
  final String? academicYearId;

  bool get _canRecord =>
      user.hasPermission('fee:create') &&
      (user.role == UserRole.principal ||
          user.role == UserRole.trustee ||
          user.role == UserRole.superadmin);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(
      feeDashboardProvider((
        studentId: studentId,
        academicYearId: academicYearId,
      )),
    );

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Management',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(
              feeDashboardProvider((
                studentId: studentId,
                academicYearId: academicYearId,
              )),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(
          feeDashboardProvider((
            studentId: studentId,
            academicYearId: academicYearId,
          )),
        ),
        child: dashAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(
              feeDashboardProvider((
                studentId: studentId,
                academicYearId: academicYearId,
              )),
            ),
          ),
          data: (result) => _buildContent(context, ref, result),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FeeDashboardResult result,
  ) {
    if (result.items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Fee Records',
        subtitle: 'No fee ledger entries have been generated yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        AppDimensions.space16,
        AppDimensions.pageHorizontal,
        AppDimensions.space40,
      ),
      children: [
        // Summary hero
        FeeSummaryBar(
          totalAmount: result.grandTotal,
          paidAmount: result.grandPaid,
          outstandingAmount: result.grandOutstanding,
        ),

        const SizedBox(height: AppDimensions.space24),

        // Section header
        Row(
          children: [
            Text(
              'Fee Entries',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: AppDimensions.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '${result.total}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.space12),

        ...result.items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
            child: FeeLedgerCard(
              ledger: entry.value,
              sequenceNumber: entry.key + 1,
              onViewHistory: () => context.push(
                RouteNames.paymentHistory,
                extra: {
                  'ledgerId': entry.value.id,
                  'totalAmount': entry.value.totalAmount,
                  'paidAmount': entry.value.paidAmount,
                  'outstandingAmount': entry.value.outstandingAmount,
                  'status': entry.value.status.label,
                },
              ),
              onPayNow: _canRecord && entry.value.hasOutstanding
                  ? () => context.push(
                        RouteNames.recordPayment,
                        extra: {
                          'studentId': studentId,
                          'ledgerId': entry.value.id,
                          'outstandingAmount': entry.value.outstandingAmount,
                          'totalAmount': entry.value.totalAmount,
                        },
                      )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        const SizedBox(height: AppDimensions.space16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
            child: AppLoading.card(),
          ),
        ),
      ],
    );
  }
}
