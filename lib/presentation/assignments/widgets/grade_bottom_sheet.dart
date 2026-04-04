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
  final bool existingApproved;

  const GradeBottomSheet({
    super.key,
    required this.submissionId,
    required this.assignmentId,
    required this.studentName,
    this.existingGrade,
    this.existingFeedback,
    this.existingApproved = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String submissionId,
    required String assignmentId,
    required String studentName,
    String? existingGrade,
    String? existingFeedback,
    bool existingApproved = false,
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
        existingApproved: existingApproved,
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
  bool _approved = false;

  @override
  void initState() {
    super.initState();
    _gradeCtrl = TextEditingController(text: widget.existingGrade ?? '');
    _feedbackCtrl =
        TextEditingController(text: widget.existingFeedback ?? '');
    _approved = widget.existingApproved;
  }

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final grade = _gradeCtrl.text.trim();
    final feedback = _feedbackCtrl.text.trim();
    if (grade.isEmpty && feedback.isEmpty && _approved == widget.existingApproved) {
      SnackbarUtils.showError(
        context,
        'Add grade/feedback or change approval status',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(submissionsProvider(widget.assignmentId).notifier)
          .gradeSubmission(
            widget.submissionId,
            grade: grade.isEmpty ? null : grade,
            feedback: feedback.isEmpty ? null : feedback,
            isApproved: _approved,
          );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Submission reviewed successfully');
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
                        'Review Submission',
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
              label: 'Grade (optional)',
              hint: 'e.g. A+, 85/100, Excellent',
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: AppDimensions.space16),

            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Approve Submission',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.grey800,
                ),
              ),
              subtitle: Text(
                'Mark this submission as teacher-approved',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              value: _approved,
              onChanged: _isLoading ? null : (v) => setState(() => _approved = v),
              activeColor: AppColors.successGreen,
            ),

            const SizedBox(height: AppDimensions.space8),

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
              label: 'Save Review',
              onTap: _submit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
