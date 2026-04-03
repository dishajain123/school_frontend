import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_file_picker.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class CreateComplaintScreen extends ConsumerStatefulWidget {
  const CreateComplaintScreen({super.key});

  @override
  ConsumerState<CreateComplaintScreen> createState() =>
      _CreateComplaintScreenState();
}

class _CreateComplaintScreenState extends ConsumerState<CreateComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  ComplaintCategory _category = ComplaintCategory.other;
  bool _isAnonymous = false;
  File? _attachment;
  String? _attachmentName;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'category': _category.backendValue,
      'description': _descriptionController.text.trim(),
      'is_anonymous': _isAnonymous,
      if (_attachmentName != null && _attachmentName!.trim().isNotEmpty)
        'attachment_key': _attachmentName,
    };

    final created =
        await ref.read(complaintNotifierProvider.notifier).create(payload);

    if (!mounted) return;

    if (created != null) {
      SnackbarUtils.showSuccess(context, 'Complaint submitted successfully');
      context.pop(true);
    } else {
      final message = ref.read(complaintNotifierProvider).valueOrNull?.error ??
          'Failed to submit complaint';
      SnackbarUtils.showError(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintNotifierProvider).valueOrNull;
    final isSubmitting = state?.isSubmitting ?? false;
    final user = ref.watch(currentUserProvider);

    final displayIdentity = user == null
        ? 'Unknown user'
        : (user.email ?? user.phone ?? 'User ${user.id.substring(0, 8)}');

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Create Complaint',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Category',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey600,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
            DropdownButtonFormField<ComplaintCategory>(
              initialValue: _category,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface50,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.surface200,
                    width: AppDimensions.borderMedium,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.surface200,
                    width: AppDimensions.borderMedium,
                  ),
                ),
              ),
              items: ComplaintCategory.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Icon(c.icon,
                              size: AppDimensions.iconSM, color: c.color),
                          const SizedBox(width: AppDimensions.space8),
                          Text(c.label),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _category = value);
                }
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Describe the issue clearly',
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Description is required';
                }
                if (v.trim().length < 10) {
                  return 'Please add more details';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(color: AppColors.surface200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _isAnonymous,
                    title: Text(
                      'Submit anonymously',
                      style: AppTypography.titleSmall,
                    ),
                    subtitle: Text(
                      'Hide your identity from complaint details.',
                      style: AppTypography.caption,
                    ),
                    onChanged: (v) => setState(() => _isAnonymous = v),
                  ),
                  if (!_isAnonymous)
                    Padding(
                      padding: const EdgeInsets.only(top: AppDimensions.space8),
                      child: Text(
                        'Submitting as: $displayIdentity',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            AppFilePicker(
              label: 'Attach file (optional)',
              hint: 'PDF, image, or document',
              allowedTypes: FilePickerType.document,
              onFilePicked: (file) {
                setState(() {
                  _attachment = file;
                  _attachmentName = file?.path.split('/').last;
                });
              },
              onFileRemoved: () {
                setState(() {
                  _attachment = null;
                  _attachmentName = null;
                });
              },
            ),
            const SizedBox(height: AppDimensions.space8),
            if (_attachment != null)
              Text(
                'Attachment selected: ${_attachmentName ?? 'file'}',
                style: AppTypography.caption.copyWith(color: AppColors.grey600),
              ),
            const SizedBox(height: AppDimensions.space32),
            AppButton.primary(
              label: 'Submit Complaint',
              onTap: isSubmitting ? null : _submit,
              isLoading: isSubmitting,
              icon: Icons.send_rounded,
            ),
            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}
