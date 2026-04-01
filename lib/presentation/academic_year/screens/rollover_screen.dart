import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/academic_year/academic_year_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';

class RolloverScreen extends ConsumerStatefulWidget {
  const RolloverScreen({super.key});

  @override
  ConsumerState<RolloverScreen> createState() => _RolloverScreenState();
}

class _RolloverScreenState extends ConsumerState<RolloverScreen> {
  AcademicYearModel? _sourceYear;
  AcademicYearModel? _targetYear;
  bool _isLoading = false;
  Map<String, int>? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(academicYearNotifierProvider.notifier).refresh();
    });
  }

  Future<void> _confirm() async {
    if (_sourceYear == null) {
      SnackbarUtils.showError(context, 'Please select a source year');
      return;
    }

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Confirm Rollover',
      message:
          'This will promote all eligible students from "${_sourceYear!.name}"${_targetYear != null ? ' to "${_targetYear!.name}"' : ' to the active year'}. This action cannot be undone.',
      confirmLabel: 'Proceed',
      icon: Icons.swap_horiz_rounded,
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        final result = await ref
            .read(academicYearNotifierProvider.notifier)
            .rollover(
              _sourceYear!.id,
              newYearId: _targetYear?.id,
            );
        setState(() => _result = result);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Rollover completed!');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.showError(context, 'Rollover failed: ${e.toString()}');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Student Rollover',
        showBack: true,
      ),
      body: yearsAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (years) {
          final sortedYears = [...years]
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppDimensions.space16),

                // Warning Banner
                Container(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(
                      color: AppColors.warningAmber.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warningAmber,
                        size: AppDimensions.iconMD,
                      ),
                      const SizedBox(width: AppDimensions.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Irreversible Action',
                              style: AppTypography.titleSmall.copyWith(
                                color: AppColors.warningDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space4),
                            Text(
                              'This will promote eligible students, copy fee structures, and create academic history records. Students marked as "Held Back" will be skipped.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.warningDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space24),

                Text('Source Year', style: AppTypography.labelMedium),
                const SizedBox(height: AppDimensions.space8),
                _YearDropdown(
                  hint: 'Select source year',
                  years: sortedYears,
                  selected: _sourceYear,
                  excluded: _targetYear,
                  onChanged: (y) => setState(() => _sourceYear = y),
                ),

                const SizedBox(height: AppDimensions.space16),

                Text('Target Year (optional)',
                    style: AppTypography.labelMedium),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  'Leave blank to use the current active year.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppDimensions.space8),
                _YearDropdown(
                  hint: 'Use active year (default)',
                  years: sortedYears,
                  selected: _targetYear,
                  excluded: _sourceYear,
                  onChanged: (y) => setState(() => _targetYear = y),
                  nullable: true,
                ),

                const SizedBox(height: AppDimensions.space32),

                // Result Card
                if (_result != null) ...[
                  _RolloverResultCard(result: _result!),
                  const SizedBox(height: AppDimensions.space24),
                ],

                AppButton.primary(
                  label: 'Start Rollover',
                  onTap: _isLoading || _sourceYear == null ? null : _confirm,
                  isLoading: _isLoading,
                  icon: Icons.swap_horiz_rounded,
                ),

                const SizedBox(height: AppDimensions.space40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _YearDropdown extends StatelessWidget {
  const _YearDropdown({
    required this.hint,
    required this.years,
    required this.selected,
    required this.excluded,
    required this.onChanged,
    this.nullable = false,
  });

  final String hint;
  final List<AcademicYearModel> years;
  final AcademicYearModel? selected;
  final AcademicYearModel? excluded;
  final ValueChanged<AcademicYearModel?> onChanged;
  final bool nullable;

  @override
  Widget build(BuildContext context) {
    final available =
        years.where((y) => excluded == null || y.id != excluded!.id).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.surface200,
          width: AppDimensions.borderMedium,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AcademicYearModel?>(
          value: selected,
          hint: Text(hint,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.grey400)),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400),
          items: [
            if (nullable)
              DropdownMenuItem<AcademicYearModel?>(
                value: null,
                child: Text(
                  'Use active year (default)',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.grey600),
                ),
              ),
            ...available.map(
              (y) => DropdownMenuItem<AcademicYearModel?>(
                value: y,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        y.name,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey800,
                        ),
                      ),
                    ),
                    if (y.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(
                              AppDimensions.radiusFull),
                        ),
                        child: Text(
                          'Active',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.goldDark,
                            fontSize: 9,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _RolloverResultCard extends StatelessWidget {
  const _RolloverResultCard({required this.result});
  final Map<String, int> result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: AppDimensions.iconMD),
              const SizedBox(width: AppDimensions.space8),
              Text(
                'Rollover Complete',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.successDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space12),
          _ResultRow(
            label: 'Students Promoted',
            value: result['processed'].toString(),
            color: AppColors.successDark,
          ),
          const SizedBox(height: AppDimensions.space4),
          _ResultRow(
            label: 'Students Skipped',
            value: result['skipped'].toString(),
            color: AppColors.warningDark,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}