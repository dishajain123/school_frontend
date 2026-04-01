import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
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

class SubjectsScreen extends ConsumerStatefulWidget {
  const SubjectsScreen({super.key});

  @override
  ConsumerState<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends ConsumerState<SubjectsScreen> {
  StandardModel? _selectedStandard;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standardsNotifierProvider.notifier).refresh();
      ref.read(subjectsNotifierProvider.notifier).refresh();
    });
  }

  bool get _canManage {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  void _onStandardChanged(StandardModel? standard) {
    setState(() => _selectedStandard = standard);
    ref.read(subjectsNotifierProvider.notifier).refresh(
          standardId: standard?.id,
        );
  }

  void _showCreateSheet({SubjectModel? existing}) {
    final standards = ref.read(standardsNotifierProvider).valueOrNull ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectFormSheet(
        existing: existing,
        standards: standards,
        preselectedStandard: _selectedStandard,
        onSubmit: (payload) async {
          try {
            if (existing != null) {
              await ref
                  .read(subjectsNotifierProvider.notifier)
                  .updateSubject(existing.id, payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Subject updated.');
            } else {
              await ref.read(subjectsNotifierProvider.notifier).create(payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Subject created.');
            }
          } catch (e) {
            if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(SubjectModel subject) async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Delete Subject',
      message: 'Delete "${subject.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(subjectsNotifierProvider.notifier).delete(subject.id);
        if (mounted) SnackbarUtils.showSuccess(context, 'Subject deleted.');
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final subjectsAsync = ref.watch(subjectsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(title: 'Subjects'),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(),
              tooltip: 'Add Subject',
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          // Standard filter
          standardsAsync.when(
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox.shrink(),
            data: (standards) => Container(
              height: 52,
              color: AppColors.white,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space8,
                ),
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedStandard == null,
                    onTap: () => _onStandardChanged(null),
                  ),
                  ...standards.map((s) => Padding(
                        padding: const EdgeInsets.only(left: AppDimensions.space8),
                        child: _FilterChip(
                          label: s.name,
                          isSelected: _selectedStandard?.id == s.id,
                          onTap: () => _onStandardChanged(s),
                        ),
                      )),
                ],
              ),
            ),
          ),
          Expanded(
            child: subjectsAsync.when(
              loading: () => AppLoading.listView(withAvatar: false),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref
                    .read(subjectsNotifierProvider.notifier)
                    .refresh(standardId: _selectedStandard?.id),
              ),
              data: (subjects) {
                if (subjects.isEmpty) {
                  return const AppEmptyState(
                    title: 'No subjects yet',
                    subtitle: 'Add subjects for each standard.',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(subjectsNotifierProvider.notifier)
                      .refresh(standardId: _selectedStandard?.id),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppDimensions.space8),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
                        ),
                        child: MasterListTile(
                          title: subject.name,
                          subtitle: 'Code: ${subject.code}',
                          badge: subject.code,
                          isLast: true,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.infoBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                            ),
                            child: const Icon(
                              Icons.menu_book_outlined,
                              size: AppDimensions.iconSM,
                              color: AppColors.infoBlue,
                            ),
                          ),
                          onEdit: _canManage ? () => _showCreateSheet(existing: subject) : null,
                          onDelete: _canManage ? () => _confirmDelete(subject) : null,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDeep : AppColors.surface100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.grey800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SubjectFormSheet extends ConsumerStatefulWidget {
  const _SubjectFormSheet({
    this.existing,
    required this.standards,
    this.preselectedStandard,
    required this.onSubmit,
  });

  final SubjectModel? existing;
  final List<StandardModel> standards;
  final StandardModel? preselectedStandard;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  ConsumerState<_SubjectFormSheet> createState() => _SubjectFormSheetState();
}

class _SubjectFormSheetState extends ConsumerState<_SubjectFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  StandardModel? _selectedStandard;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStandard = widget.preselectedStandard ??
        (widget.standards.isNotEmpty ? widget.standards.first : null);
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _codeController.text = widget.existing!.code;
      try {
        _selectedStandard = widget.standards
            .firstWhere((s) => s.id == widget.existing!.standardId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStandard == null) {
      SnackbarUtils.showError(context, 'Please select a standard');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim().toUpperCase(),
        'standard_id': _selectedStandard!.id,
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
              widget.existing != null ? 'Edit Subject' : 'New Subject',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppDimensions.space24),
            // Standard selector
            Text('Standard', style: AppTypography.labelMedium.copyWith(color: AppColors.grey600)),
            const SizedBox(height: AppDimensions.space8),
            DropdownButtonFormField<StandardModel>(
              value: _selectedStandard,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.surface200, width: AppDimensions.borderMedium),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(color: AppColors.surface200, width: AppDimensions.borderMedium),
                ),
                filled: true,
                fillColor: AppColors.surface50,
              ),
              items: widget.standards
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName)))
                  .toList(),
              onChanged: widget.existing != null ? null : (s) => setState(() => _selectedStandard = s),
              validator: (v) => v == null ? 'Please select a standard' : null,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _nameController,
              label: 'Subject Name',
              hint: 'e.g. Mathematics',
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _codeController,
              label: 'Subject Code',
              hint: 'e.g. MATH01',
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
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
