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

class _CreateComplaintScreenState extends ConsumerState<CreateComplaintScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  ComplaintCategory _category = ComplaintCategory.other;
  bool _isAnonymous = false;
  File? _attachment;
  String? _attachmentName;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _animCtrl.dispose();
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
      appBar: const AppAppBar(title: 'Create Complaint', showBack: true),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _FormCard(
                        title: 'Category',
                        icon: Icons.category_outlined,
                        children: [
                          _CategoryGrid(
                            selected: _category,
                            onSelected: (c) =>
                                setState(() => _category = c),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Description',
                        icon: Icons.edit_note_rounded,
                        children: [
                          AppTextField(
                            controller: _descriptionController,
                            label: '',
                            hint: 'Describe the issue clearly...',
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Privacy',
                        icon: Icons.shield_outlined,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Submit anonymously',
                                      style: AppTypography.titleSmall.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isAnonymous
                                          ? 'Your identity is hidden'
                                          : 'Submitting as: $displayIdentity',
                                      style: AppTypography.caption.copyWith(
                                        color: _isAnonymous
                                            ? AppColors.successGreen
                                            : AppColors.grey500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: _isAnonymous,
                                activeColor: AppColors.navyDeep,
                                onChanged: (v) =>
                                    setState(() => _isAnonymous = v),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Attachment',
                        icon: Icons.attach_file_rounded,
                        children: [
                          AppFilePicker(
                            label: 'Attach file (optional)',
                            hint: 'PDF, image, or document',
                            allowedTypes: FilePickerType.document,
                            onFilePicked: (file) {
                              setState(() {
                                _attachment = file;
                                _attachmentName =
                                    file?.path.split('/').last;
                              });
                            },
                            onFileRemoved: () {
                              setState(() {
                                _attachment = null;
                                _attachmentName = null;
                              });
                            },
                          ),
                          if (_attachment != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.successGreen.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded,
                                      size: 13, color: AppColors.successGreen),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _attachmentName ?? 'file',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.successGreen,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _SubmitBar(isSubmitting: isSubmitting, onSubmit: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.selected, required this.onSelected});
  final ComplaintCategory selected;
  final ValueChanged<ComplaintCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintCategory.values.map((cat) {
        final isSelected = selected == cat;
        final color = cat.color;
        return GestureDetector(
          onTap: () => onSelected(cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? color.withValues(alpha: 0.5)
                    : AppColors.surface200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon,
                    size: 14, color: isSelected ? color : AppColors.grey500),
                const SizedBox(width: 6),
                Text(
                  cat.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: isSelected ? color : AppColors.grey700,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
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

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isSubmitting, required this.onSubmit});
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: 'Submit Complaint',
        onTap: isSubmitting ? null : onSubmit,
        isLoading: isSubmitting,
        icon: Icons.send_rounded,
      ),
    );
  }
}