import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/academic_year/academic_year_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/year_tile.dart';

class AcademicYearListScreen extends ConsumerStatefulWidget {
  const AcademicYearListScreen({super.key});

  @override
  ConsumerState<AcademicYearListScreen> createState() =>
      _AcademicYearListScreenState();
}

class _AcademicYearListScreenState
    extends ConsumerState<AcademicYearListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(academicYearNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _canManage {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('academic_year:manage') ?? false;
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => _AcademicYearFormSheet(
        onSubmit: (payload) async {
          try {
            await ref
                .read(academicYearNotifierProvider.notifier)
                .create(payload);
            if (mounted) {
              SnackbarUtils.showSuccess(context, 'Academic year created.');
            }
          } catch (e) {
            if (mounted) {
              SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
            }
          }
        },
      ),
    );
  }

  void _showEditSheet(AcademicYearModel year) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => _AcademicYearFormSheet(
        existing: year,
        onSubmit: (payload) async {
          try {
            await ref
                .read(academicYearNotifierProvider.notifier)
                .updateAcademicYear(year.id, payload);
            if (mounted) {
              SnackbarUtils.showSuccess(context, 'Academic year updated.');
            }
          } catch (e) {
            if (mounted) {
              SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
            }
          }
        },
      ),
    );
  }

  Future<void> _confirmActivate(AcademicYearModel year) async {
    if (year.isActive) return;
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Activate Academic Year',
      message:
          'Set "${year.name}" as the active academic year? This will deactivate the current one.',
      confirmLabel: 'Activate',
      icon: Icons.check_circle_outline,
    );
    if (confirmed == true && mounted) {
      try {
        await ref
            .read(academicYearNotifierProvider.notifier)
            .activate(year.id);
        if (mounted) {
          SnackbarUtils.showSuccess(context, '"${year.name}" is now active.');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Academic Years',
        showBack: true,
        actions: [
          if (_canManage) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.white, size: 18),
                ),
                tooltip: 'Rollover',
                onPressed: () => context.push(RouteNames.rollover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.white, size: 20),
                ),
                tooltip: 'Add Academic Year',
                onPressed: _showCreateSheet,
              ),
            ),
          ],
        ],
      ),
      body: yearsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(academicYearNotifierProvider.notifier).refresh(),
        ),
        data: (years) {
          if (years.isEmpty) {
            return AppEmptyState(
              title: 'No academic years',
              subtitle: 'Create your first academic year to get started.',
              icon: Icons.calendar_today_outlined,
              actionLabel: _canManage ? 'Create Year' : null,
              onAction: _canManage ? _showCreateSheet : null,
            );
          }

          final sorted = [...years]..sort((a, b) {
              if (a.isActive && !b.isActive) return -1;
              if (!a.isActive && b.isActive) return 1;
              return b.startDate.compareTo(a.startDate);
            });

          final activeYear = sorted.firstWhere(
            (y) => y.isActive,
            orElse: () => sorted.first,
          );

          return FadeTransition(
            opacity: _fade,
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(academicYearNotifierProvider.notifier).refresh(),
              color: AppColors.navyDeep,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  _ActiveYearBanner(year: activeYear),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppColors.navyDeep,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'All Years (${sorted.length})',
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navyDeep,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...sorted.map(
                    (year) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: YearTile(
                        year: year,
                        canManage: _canManage,
                        onActivate: () => _confirmActivate(year),
                        onEdit: () => _showEditSheet(year),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 72),
      ),
    );
  }
}

class _ActiveYearBanner extends StatelessWidget {
  const _ActiveYearBanner({required this.year});
  final AcademicYearModel year;

  @override
  Widget build(BuildContext context) {
    if (!year.isActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.goldPrimary.withValues(alpha: 0.35)),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: AppColors.goldPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'Current Year',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.goldPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  year.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${DateFormatter.formatDate(year.startDate)} – ${DateFormatter.formatDate(year.endDate)}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 11,
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

class _AcademicYearFormSheet extends ConsumerStatefulWidget {
  const _AcademicYearFormSheet({
    this.existing,
    required this.onSubmit,
  });

  final AcademicYearModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  ConsumerState<_AcademicYearFormSheet> createState() =>
      _AcademicYearFormSheetState();
}

class _AcademicYearFormSheetState
    extends ConsumerState<_AcademicYearFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _startDate = widget.existing!.startDate;
      _endDate = widget.existing!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ??
          (_startDate?.add(const Duration(days: 365)) ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      SnackbarUtils.showError(context, 'Please select a start date');
      return;
    }
    if (_endDate == null) {
      SnackbarUtils.showError(context, 'Please select an end date');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      SnackbarUtils.showError(context, 'End date must be after start date');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'name': _nameController.text.trim(),
        'start_date': DateFormatter.formatDateForApi(_startDate!),
        'end_date': DateFormatter.formatDateForApi(_endDate!),
      };
      await widget.onSubmit(payload);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    final isEditing = widget.existing != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded,
                      size: 18, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit Academic Year' : 'New Academic Year',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _nameController,
              label: 'Year Name',
              hint: 'e.g. 2024-25',
              prefixIconData: Icons.label_outline_rounded,
              textInputAction: TextInputAction.done,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Name is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Start Date',
                    value: _startDate,
                    onTap: _pickStartDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'End Date',
                    value: _endDate,
                    onTap: _pickEndDate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: isEditing ? 'Update Year' : 'Create Year',
              onTap: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: isEditing ? Icons.save_outlined : Icons.add_circle_outline,
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.grey500,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? AppColors.navyMedium.withValues(alpha: 0.5)
                    : AppColors.surface200,
                width: value != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: value != null ? AppColors.navyMedium : AppColors.grey400,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value != null
                        ? DateFormatter.formatDate(value!)
                        : 'Select date',
                    style: AppTypography.bodySmall.copyWith(
                      color: value != null ? AppColors.grey800 : AppColors.grey400,
                      fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}