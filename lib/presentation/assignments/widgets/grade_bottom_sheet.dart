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
  _ReviewAction _action = _ReviewAction.reviewed;

  @override
  void initState() {
    super.initState();
    _gradeCtrl = TextEditingController(text: widget.existingGrade ?? '');
    _feedbackCtrl = TextEditingController(text: widget.existingFeedback ?? '');
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
    var feedback = _feedbackCtrl.text.trim();
    if (_action == _ReviewAction.reviewed && feedback.isEmpty) {
      feedback = 'Reviewed by teacher';
    } else if (_action == _ReviewAction.redo && feedback.isEmpty) {
      feedback = 'Redo required. Please revise and resubmit.';
    }
    if (grade.isEmpty && feedback.isEmpty && _approved == widget.existingApproved) {
      SnackbarUtils.showError(context, 'Add grade/feedback or change approval status');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(submissionsProvider(widget.assignmentId).notifier).gradeSubmission(
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
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surface200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.rate_review_outlined,
                          color: AppColors.navyDeep, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Review Submission',
                              style: AppTypography.titleLarge.copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(widget.studentName,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.grey500)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, color: AppColors.grey500, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AppTextField(
                  controller: _gradeCtrl,
                  label: 'Grade (optional)',
                  hint: 'e.g. A+, 85/100, Excellent',
                  textInputAction: TextInputAction.next,
                  prefixIconData: Icons.grade_outlined,
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surface200),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                    title: Text('Approve Submission',
                        style: AppTypography.titleSmall.copyWith(color: AppColors.grey800)),
                    subtitle: Text('Mark as teacher-approved',
                        style: AppTypography.caption.copyWith(color: AppColors.grey500)),
                    value: _approved,
                    onChanged: _isLoading ? null : (v) => setState(() => _approved = v),
                    activeColor: AppColors.successGreen,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ReviewChip(
                      label: 'Reviewed',
                      isSelected: _action == _ReviewAction.reviewed,
                      color: AppColors.successGreen,
                      bg: AppColors.successLight,
                      icon: Icons.check_circle_outline_rounded,
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _action = _ReviewAction.reviewed),
                    ),
                    const SizedBox(width: 10),
                    _ReviewChip(
                      label: 'Needs Redo',
                      isSelected: _action == _ReviewAction.redo,
                      color: AppColors.warningAmber,
                      bg: AppColors.warningLight,
                      icon: Icons.refresh_rounded,
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _action = _ReviewAction.redo),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _feedbackCtrl,
                  label: 'Feedback (optional)',
                  hint: 'Write feedback for the student...',
                  maxLines: 4,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 24),
                AppButton.primary(
                  label: 'Save Review',
                  onTap: _submit,
                  isLoading: _isLoading,
                  icon: Icons.save_outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.bg,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color, bg;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? bg : AppColors.surface50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color.withValues(alpha: 0.4) : AppColors.surface200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? color : AppColors.grey400),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected ? color : AppColors.grey500,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ReviewAction { reviewed, redo }