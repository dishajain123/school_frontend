import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/submission_provider.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class GradeBottomSheet extends ConsumerStatefulWidget {
  final String submissionId;
  final String assignmentId;
  final String studentName;
  final String? existingGrade;
  final String? existingFeedback;

  const GradeBottomSheet({
    super.key,
    required this.submissionId,
    required this.assignmentId,
    required this.studentName,
    this.existingGrade,
    this.existingFeedback,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String submissionId,
    required String assignmentId,
    required String studentName,
    String? existingGrade,
    String? existingFeedback,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GradeBottomSheet(
        submissionId: submissionId,
        assignmentId: assignmentId,
        studentName: studentName,
        existingGrade: existingGrade,
        existingFeedback: existingFeedback,
      ),
    );
  }

  @override
  ConsumerState<GradeBottomSheet> createState() => _GradeBottomSheetState();
}

class _GradeBottomSheetState extends ConsumerState<GradeBottomSheet> {
  late final TextEditingController _gradeCtrl;
  late final TextEditingController _feedbackCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gradeCtrl = TextEditingController(text: widget.existingGrade ?? '');
    _feedbackCtrl =
        TextEditingController(text: widget.existingFeedback ?? '');
  }

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(submissionsProvider(widget.assignmentId).notifier)
          .gradeSubmission(
            widget.submissionId,
            grade: _gradeCtrl.text.trim(),
            feedback: _feedbackCtrl.text.trim().isEmpty
                ? null
                : _feedbackCtrl.text.trim(),
          );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Grade submitted successfully');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      padding: EdgeInsets.only(
        left: AppDimensions.space24,
        right: AppDimensions.space24,
        top: AppDimensions.space20,
        bottom: AppDimensions.space24 + bottomPadding,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space20),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade Submission',
                        style: AppTypography.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.studentName,
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grey400),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.space24),

            // Grade field
            AppTextField(
              controller: _gradeCtrl,
              label: 'Grade',
              hint: 'e.g. A+, 85/100, Excellent',
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Grade is required';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppDimensions.space16),

            // Feedback field
            AppTextField(
              controller: _feedbackCtrl,
              label: 'Feedback (optional)',
              hint: 'Write feedback for the student...',
              maxLines: 4,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: AppDimensions.space24),

            // Submit button
            AppButton.primary(
              label: 'Submit Grade',
              onTap: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
