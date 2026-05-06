import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/standard_model.dart';
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

class StandardsScreen extends ConsumerStatefulWidget {
  const StandardsScreen({super.key});

  @override
  ConsumerState<StandardsScreen> createState() => _StandardsScreenState();
}

class _StandardsScreenState extends ConsumerState<StandardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(standardsNotifierProvider.notifier).refresh();
    });
  }

  bool get _canManage {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  void _showCreateSheet({StandardModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StandardFormSheet(
        existing: existing,
        onSubmit: (payload) async {
          try {
            if (existing != null) {
              await ref
                  .read(standardsNotifierProvider.notifier)
                  .updateStandard(existing.id, payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Class updated.');
            } else {
              await ref.read(standardsNotifierProvider.notifier).create(payload);
              if (mounted) SnackbarUtils.showSuccess(context, 'Class created.');
            }
          } catch (e) {
            if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(StandardModel standard) async {
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Delete Class',
      message: 'Delete "${standard.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(standardsNotifierProvider.notifier).delete(standard.id);
        if (mounted) SnackbarUtils.showSuccess(context, 'Class deleted.');
      } catch (e) {
        if (mounted) SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final standardsAsync = ref.watch(standardsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Class Setup'),
      floatingActionButton: _canManage
          ? FloatingActionButton(
              onPressed: () => _showCreateSheet(),
              tooltip: 'Add Class',
              child: const Icon(Icons.add),
            )
          : null,
      body: standardsAsync.when(
        loading: () => AppLoading.listView(withAvatar: false),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.read(standardsNotifierProvider.notifier).refresh(),
        ),
        data: (standards) {
          if (standards.isEmpty) {
            return const AppEmptyState(
              title: 'No classes yet',
              subtitle: 'Create your first class to get started.',
              icon: Icons.class_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(standardsNotifierProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              itemCount: standards.length,
              itemBuilder: (context, index) {
                final standard = standards[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
                  ),
                  child: MasterListTile(
                    title: standard.name,
                    subtitle: 'Level ${standard.level}',
                    badge: 'L${standard.level}',
                    isLast: true,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                      ),
                      child: Center(
                        child: Text(
                          '${standard.level}',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    onEdit: _canManage ? () => _showCreateSheet(existing: standard) : null,
                    onDelete: _canManage ? () => _confirmDelete(standard) : null,
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

class _StandardFormSheet extends ConsumerStatefulWidget {
  const _StandardFormSheet({this.existing, required this.onSubmit});

  final StandardModel? existing;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  @override
  ConsumerState<_StandardFormSheet> createState() => _StandardFormSheetState();
}

class _StandardFormSheetState extends ConsumerState<_StandardFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _levelController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _nameController.text = widget.existing!.name;
      _levelController.text = widget.existing!.level.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'level': int.parse(_levelController.text.trim()),
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
              widget.existing != null ? 'Edit Class' : 'New Class',
              style: AppTypography.headlineSmall,
            ),
            const SizedBox(height: AppDimensions.space24),
            AppTextField(
              controller: _nameController,
              label: 'Name',
              hint: 'e.g. Class 10',
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _levelController,
              label: 'Level',
              hint: '1 – 12',
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Level is required';
                final n = int.tryParse(v.trim());
                if (n == null || n < 1 || n > 12) return 'Level must be 1–12';
                return null;
              },
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
