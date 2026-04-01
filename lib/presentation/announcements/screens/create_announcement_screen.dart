import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/announcement/announcement_model.dart';
import '../../../providers/announcement_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({
    super.key,
    this.existing,
  });

  final AnnouncementModel? existing;

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  AnnouncementType _selectedType = AnnouncementType.general;
  bool _isLoading = false;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.existing!.title;
      _bodyController.text = widget.existing!.body;
      _selectedType = widget.existing!.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final payload = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'type': _selectedType.backendValue,
      };

      if (isEditing) {
        await ref
            .read(announcementNotifierProvider.notifier)
            .updateAnnouncement(widget.existing!.id, payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Announcement updated.');
          context.pop();
        }
      } else {
        await ref
            .read(announcementNotifierProvider.notifier)
            .create(payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Announcement posted.');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Announcement' : 'New Announcement',
        showBack: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _titleController,
                label: 'Title',
                hint: 'Announcement title',
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _bodyController,
                label: 'Body',
                hint: 'Write the announcement content...',
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Body is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppDimensions.space16),
              Text('Type', style: AppTypography.labelMedium),
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                children: AnnouncementType.values.map((type) {
                  final isSelected = _selectedType == type;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space12,
                        vertical: AppDimensions.space8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? type.color.withValues(alpha: 0.15)
                            : AppColors.surface100,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusSmall),
                        border: Border.all(
                          color: isSelected
                              ? type.color
                              : AppColors.surface200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(type.icon,
                              size: 14,
                              color: isSelected
                                  ? type.color
                                  : AppColors.grey600),
                          const SizedBox(width: AppDimensions.space4),
                          Text(
                            type.label,
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? type.color
                                  : AppColors.grey800,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppDimensions.space32),
              AppButton.primary(
                label: isEditing ? 'Update' : 'Post Announcement',
                onTap: _isLoading ? null : _submit,
                isLoading: _isLoading,
                icon: Icons.send_rounded,
              ),
              const SizedBox(height: AppDimensions.space40),
            ],
          ),
        ),
      ),
    );
  }
}
