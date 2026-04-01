import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/grade_master_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/master_list_tile.dart';

class GradeMasterScreen extends ConsumerStatefulWidget {
  const GradeMasterScreen({super.key});

  @override
  ConsumerState<GradeMasterScreen> createState() => _GradeMasterScreenState();
}

class _GradeMasterScreenState extends ConsumerState<GradeMasterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradesNotifierProvider.notifier).refresh();
    });
  }

  bool get _canManage {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  void _showCreateSheet({GradeMasterModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeFormSheet(
        existing: existing,
        onSubmit: (payload) async {
          try {
            if (existing != null) {
              await ref
                  .read(gradesNotifierProvider.notifier)
                  .updateGrade(existing.id, payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Grade updated.');
            } else {
              await ref.read(gradesNotifierProvider.notifier).create(payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Grade created.');
            }
          } catch (e) {
            if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(GradeMasterModel grade) async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Delete Grade',
      message: 'Delete grade "${grade.gradeLetter}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(gradesNotifierProvider.notifier).delete(grade.id);
        if (mounted) SnackbarUtils.showSuccess(context, 'Grade deleted.');
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
      }
    }
  }

  Color _gradeColor(GradeMasterModel grade) {
    if (grade.minPercent >= 80) return AppColors.successGreen;
    if (grade.minPercent >= 60) return AppColors.infoBlue;
    if (grade.minPercent >= 40) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final gradesAsync = ref.watch(gradesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(title: 'Grade Master'),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(),
              tooltip: 'Add Grade',
              child: const Icon(Icons.add),
            )
          : null,
      body: gradesAsync.when(
        loading: () => AppLoading.listView(withAvatar: false),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(gradesNotifierProvider.notifier).refresh(),
        ),
        data: (grades) {
          if (grades.isEmpty) {
            return const AppEmptyState(
              title: 'No grades configured',
              subtitle: 'Set up your grade scale to enable result tracking.',
              icon: Icons.grade_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(gradesNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                final grade = grades[index];
                final color = _gradeColor(grade);
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
                  ),
                  child: MasterListTile(
                    title: '${grade.gradeLetter}  ·  ${grade.gradePoint} GPA',
                    subtitle: grade.range,
                    isLast: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Center(
                        child: Text(
                          grade.gradeLetter,
                          style: AppTypography.titleMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    onEdit: _canManage ? () => _showCreateSheet(existing: grade) : null,
                    onDelete: _canManage ? () => _confirmDelete(grade) : null,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _GradeFormSheet extends ConsumerStatefulWidget {
  const _GradeFormSheet({this.existing, required this.onSubmit});

  final GradeMasterModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  ConsumerState<_GradeFormSheet> createState() => _GradeFormSheetState();
}

class _GradeFormSheetState extends ConsumerState<_GradeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _letterController = TextEditingController();
  final _gradePointController = TextEditingController();
  final _minPercentController = TextEditingController();
  final _maxPercentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _letterController.text = widget.existing!.gradeLetter;
      _gradePointController.text = widget.existing!.gradePoint.toString();
      _minPercentController.text = widget.existing!.minPercent.toString();
      _maxPercentController.text = widget.existing!.maxPercent.toString();
    }
  }

  @override
  void dispose() {
    _letterController.dispose();
    _gradePointController.dispose();
    _minPercentController.dispose();
    _maxPercentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'grade_letter': _letterController.text.trim().toUpperCase(),
        'grade_point': double.parse(_gradePointController.text.trim()),
        'min_percent': double.parse(_minPercentController.text.trim()),
        'max_percent': double.parse(_maxPercentController.text.trim()),
      };
      await widget.onSubmit(payload);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePercent(String? v, {bool isMin = false}) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final n = double.tryParse(v.trim());
    if (n == null || n < 0 || n > 100) return 'Must be 0–100';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: AppDimensions.dragHandleWidth,
                height: AppDimensions.dragHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              widget.existing != null ? 'Edit Grade' : 'New Grade',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppDimensions.space24),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _letterController,
                    label: 'Grade Letter',
                    hint: 'A+',
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: AppTextField(
                    controller: _gradePointController,
                    label: 'Grade Point',
                    hint: '10.0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = double.tryParse(v.trim());
                      if (n == null || n < 0 || n > 10) return '0–10';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _minPercentController,
                    label: 'Min %',
                    hint: '90',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    validator: (v) => _validatePercent(v, isMin: true),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: AppTextField(
                    controller: _maxPercentController,
                    label: 'Max %',
                    hint: '100',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (v) => _validatePercent(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.space24),
            AppButton.primary(
              label: widget.existing != null ? 'Update' : 'Create',
              onTap: _isLoading ? null : _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
