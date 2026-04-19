import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class _RolloverScreenState extends ConsumerState<RolloverScreen>
    with SingleTickerProviderStateMixin {
  AcademicYearModel? _sourceYear;
  AcademicYearModel? _targetYear;
  bool _isLoading = false;
  Map<String, int>? _result;

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
      appBar: const AppAppBar(
        title: 'Student Rollover',
        showBack: true,
      ),
      body: yearsAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(message: e.toString()),
        data: (years) {
          final sortedYears = [...years]
            ..sort((a, b) => b.startDate.compareTo(a.startDate));

          return FadeTransition(
            opacity: _fade,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _WarningBanner(),
                const SizedBox(height: 20),
                _SectionCard(
                  title: 'Year Selection',
                  icon: Icons.swap_horiz_rounded,
                  children: [
                    _DropdownLabel('Source Year'),
                    const SizedBox(height: 8),
                    _YearDropdownField(
                      hint: 'Select source year',
                      years: sortedYears,
                      selected: _sourceYear,
                      excluded: _targetYear,
                      onChanged: (y) => setState(() => _sourceYear = y),
                    ),
                    const SizedBox(height: 16),
                    _DropdownLabel('Target Year (optional)'),
                    const SizedBox(height: 4),
                    Text(
                      'Leave blank to use the currently active year.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey400,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _YearDropdownField(
                      hint: 'Use active year (default)',
                      years: sortedYears,
                      selected: _targetYear,
                      excluded: _sourceYear,
                      onChanged: (y) => setState(() => _targetYear = y),
                      nullable: true,
                    ),
                  ],
                ),
                if (_sourceYear != null) ...[
                  const SizedBox(height: 16),
                  _PreviewCard(
                    sourceYear: _sourceYear!,
                    targetYear: _targetYear,
                  ),
                ],
                if (_result != null) ...[
                  const SizedBox(height: 16),
                  _ResultCard(result: _result!),
                ],
                const SizedBox(height: 20),
                AppButton.primary(
                  label: 'Start Rollover',
                  onTap: _isLoading || _sourceYear == null ? null : _confirm,
                  isLoading: _isLoading,
                  icon: Icons.swap_horiz_rounded,
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.warningAmber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.warningAmber, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Irreversible Action',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.warningDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This promotes eligible students, copies fee structures, and creates academic history records. Students marked "Held Back" will be skipped.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.warningDark,
                    height: 1.5,
                    fontSize: 12,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _YearDropdownField extends StatelessWidget {
  const _YearDropdownField({
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null
              ? AppColors.navyMedium.withValues(alpha: 0.5)
              : AppColors.surface200,
          width: selected != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AcademicYearModel?>(
          value: selected,
          hint: Text(hint,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.grey400, fontSize: 13)),
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
                      .copyWith(color: AppColors.grey600, fontSize: 13),
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
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (y.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.goldDark,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
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

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.sourceYear, this.targetYear});
  final AcademicYearModel sourceYear;
  final AcademicYearModel? targetYear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          _YearPill(label: sourceYear.name, color: AppColors.navyMedium),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 14, color: AppColors.infoBlue),
            ),
          ),
          _YearPill(
            label: targetYear?.name ?? 'Active Year',
            color: AppColors.successGreen,
          ),
        ],
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final Map<String, int> result;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.successGreen.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.successGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Rollover Complete',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.successDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.successGreen.withValues(alpha: 0.15)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Promoted',
                    value: '${result['processed'] ?? 0}',
                    color: AppColors.successGreen,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.surface200,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Skipped',
                    value: '${result['skipped'] ?? 0}',
                    color: AppColors.warningAmber,
                    icon: Icons.skip_next_rounded,
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

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.grey500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}