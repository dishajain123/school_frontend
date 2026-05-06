import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/leave/leave_balance_model.dart';
import '../../../../data/models/leave/leave_model.dart';
import '../../../../providers/academic_year_provider.dart';
import '../../../../providers/leave_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/balance_tile.dart';

class ApplyLeaveScreen extends ConsumerStatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  ConsumerState<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends ConsumerState<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  LeaveType _selectedType = LeaveType.casual;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _daysRequested {
    if (_fromDate == null || _toDate == null) return 0;
    return _toDate!.difference(_fromDate!).inDays + 1;
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        // Reset to date if it's before the new from date
        if (_toDate != null && _toDate!.isBefore(picked)) {
          _toDate = picked;
        }
      });
    }
  }

  Future<void> _pickToDate() async {
    if (_fromDate == null) {
      SnackbarUtils.showInfo(context, 'Please select a start date first.');
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate!,
      firstDate: _fromDate!,
      lastDate: _fromDate!.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _toDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_fromDate == null || _toDate == null) {
      SnackbarUtils.showError(context, 'Please select both start and end dates.');
      return;
    }

    final activeYear = ref.read(activeYearProvider);

    final leave = await ref.read(leaveNotifierProvider.notifier).apply(
          leaveType: _selectedType,
          fromDate: _fromDate!,
          toDate: _toDate!,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
          academicYearId: activeYear?.id,
        );

    if (!mounted) return;

    if (leave != null) {
      SnackbarUtils.showSuccess(context, 'Leave request submitted successfully.');
      context.pop();
    } else {
      final error =
          ref.read(leaveNotifierProvider).valueOrNull?.error ?? 'Failed to submit leave.';
      SnackbarUtils.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final balanceAsync =
        ref.watch(leaveBalanceProvider(activeYear?.id));
    final leaveState = ref.watch(leaveNotifierProvider);
    final isSubmitting = leaveState.valueOrNull?.isSubmitting ?? false;

    // Find balance for selected leave type
    LeaveBalanceModel? selectedBalance;
    balanceAsync.whenData((balances) {
      try {
        selectedBalance =
            balances.firstWhere((b) => b.leaveType == _selectedType);
      } catch (_) {
        selectedBalance = null;
      }
    });

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Apply Leave',
        showBack: true,
        showNotificationBell: false,
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space20,
                AppDimensions.space16,
                AppDimensions.space16,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Leave Type ─────────────────────────────────────────────
                  Text('Leave Type', style: AppTypography.labelMedium),
                  const SizedBox(height: AppDimensions.space8),
                  _LeaveTypeSelector(
                    selected: _selectedType,
                    onChanged: (type) => setState(() => _selectedType = type),
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  // ── Balance preview for selected type ──────────────────────
                  if (selectedBalance != null) ...[
                    BalanceTile(
                      leaveType: _selectedType.shortLabel,
                      balance: selectedBalance!.remainingDays,
                      total: selectedBalance!.totalDays,
                      used: selectedBalance!.usedDays,
                    ),
                    const SizedBox(height: AppDimensions.space20),
                  ] else ...[
                    balanceAsync.when(
                      loading: () => const SizedBox(
                        height: 40,
                        child: Center(
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (_) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppDimensions.space20),
                  ],

                  // ── Date range ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _DatePickerField(
                          label: 'From Date',
                          date: _fromDate,
                          hint: 'Select start date',
                          onTap: _pickFromDate,
                        ),
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: _DatePickerField(
                          label: 'To Date',
                          date: _toDate,
                          hint: 'Select end date',
                          onTap: _pickToDate,
                        ),
                      ),
                    ],
                  ),

                  // Days count preview
                  if (_daysRequested > 0) ...[
                    const SizedBox(height: AppDimensions.space12),
                    _DaysCountBanner(
                      days: _daysRequested,
                      hasEnoughBalance: selectedBalance == null ||
                          selectedBalance!.remainingDays >= _daysRequested,
                    ),
                  ],

                  const SizedBox(height: AppDimensions.space20),

                  // ── Reason ─────────────────────────────────────────────────
                  AppTextField(
                    label: 'Reason (Optional)',
                    hint: 'Briefly describe the reason for leave...',
                    controller: _reasonController,
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: AppDimensions.space32),

                  // ── Submit ─────────────────────────────────────────────────
                  AppButton.primary(
                    label: 'Submit Request',
                    onTap: isSubmitting ? null : _submit,
                    isLoading: isSubmitting,
                    icon: Icons.send_rounded,
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  AppButton.secondary(
                    label: 'Cancel',
                    onTap: isSubmitting ? null : () => context.pop(),
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

// ── Leave Type Selector ───────────────────────────────────────────────────────

class _LeaveTypeSelector extends StatelessWidget {
  const _LeaveTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final LeaveType selected;
  final ValueChanged<LeaveType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimensions.space8,
      runSpacing: AppDimensions.space8,
      children: LeaveType.values.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: () => onChanged(type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? type.color.withValues(alpha: 0.12)
                  : AppColors.surface50,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color: isSelected ? type.color : AppColors.surface200,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type.icon,
                  size: AppDimensions.iconXS,
                  color: isSelected ? type.color : AppColors.grey400,
                ),
                const SizedBox(width: AppDimensions.space6),
                Text(
                  type.shortLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? type.color : AppColors.grey600,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Date Picker Field ─────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.hint,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTypography.labelMedium),
          const SizedBox(height: AppDimensions.space8),
          Container(
            height: AppDimensions.inputHeight,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSmall),
              border: Border.all(
                color:
                    date != null ? AppColors.navyMedium : AppColors.surface200,
                width: date != null ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: AppDimensions.iconSM,
                  color:
                      date != null ? AppColors.navyMedium : AppColors.grey400,
                ),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date!)
                        : hint,
                    style: date != null
                        ? AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey800,
                          )
                        : AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey400,
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ── Days Count Banner ─────────────────────────────────────────────────────────

class _DaysCountBanner extends StatelessWidget {
  const _DaysCountBanner({
    required this.days,
    required this.hasEnoughBalance,
  });

  final int days;
  final bool hasEnoughBalance;

  @override
  Widget build(BuildContext context) {
    final color =
        hasEnoughBalance ? AppColors.infoBlue : AppColors.errorRed;
    final bg =
        hasEnoughBalance ? AppColors.infoLight : AppColors.errorLight;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            hasEnoughBalance
                ? Icons.info_outline_rounded
                : Icons.warning_amber_rounded,
            size: AppDimensions.iconSM,
            color: color,
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              hasEnoughBalance
                  ? '$days ${days == 1 ? 'day' : 'days'} requested'
                  : '$days ${days == 1 ? 'day' : 'days'} requested — insufficient balance',
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
