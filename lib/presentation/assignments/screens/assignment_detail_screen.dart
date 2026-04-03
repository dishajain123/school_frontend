import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/assignment/submission_model.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/submission_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_text_field.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() =>
      _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState
    extends ConsumerState<AssignmentDetailScreen> {
  final _textCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _removeFile() => setState(() => _pickedFile = null);

  Future<void> _submitAssignment(String studentId) async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty && _pickedFile == null) {
      SnackbarUtils.showError(
          context, 'Provide text response or attach a file');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      MultipartFile? multipartFile;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        multipartFile = MultipartFile.fromBytes(
          _pickedFile!.bytes!,
          filename: _pickedFile!.name,
        );
      } else if (_pickedFile != null && _pickedFile!.path != null) {
        multipartFile = await MultipartFile.fromFile(
          _pickedFile!.path!,
          filename: _pickedFile!.name,
        );
      }

      await ref.read(submissionCreateProvider.notifier).submit(
            assignmentId: widget.assignmentId,
            studentId: studentId,
            textResponse: text.isEmpty ? null : text,
            file: multipartFile,
          );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Assignment submitted successfully!');
        ref.invalidate(assignmentDetailProvider(widget.assignmentId));
        setState(() {
          _textCtrl.clear();
          _pickedFile = null;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync =
        ref.watch(assignmentDetailProvider(widget.assignmentId));
    final currentUser = ref.watch(currentUserProvider);
    final canCreate = currentUser?.hasPermission('assignment:create') ?? false;
    final canSubmit = currentUser?.hasPermission('submission:create') ?? false;
    final canGrade = currentUser?.hasPermission('submission:grade') ?? false;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Assignment Details',
        showBack: true,
        actions: [
          if (canCreate)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.grey800),
              onPressed: () => context.push(
                RouteNames.createAssignment,
                extra: {'editId': widget.assignmentId},
              ),
            ),
        ],
      ),
      body: assignmentAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.navyDeep),
        ),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(assignmentDetailProvider(widget.assignmentId)),
        ),
        data: (assignment) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header card ──────────────────────────────────────────
                _HeaderCard(assignment: assignment),

                const SizedBox(height: AppDimensions.space20),

                // ── Description ──────────────────────────────────────────
                if (assignment.description != null &&
                    assignment.description!.isNotEmpty) ...[
                  _SectionLabel('Description'),
                  const SizedBox(height: AppDimensions.space8),
                  _BodyCard(
                    child: Text(
                      assignment.description!,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.grey800, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // ── Attachment ───────────────────────────────────────────
                if (assignment.fileUrl != null) ...[
                  _SectionLabel('Attachment'),
                  const SizedBox(height: AppDimensions.space8),
                  _AttachmentButton(fileUrl: assignment.fileUrl!),
                  const SizedBox(height: AppDimensions.space20),
                ],

                // ── Teacher: View Submissions ────────────────────────────
                if (canGrade) ...[
                  AppButton.secondary(
                    label: 'View Submissions',
                    onTap: () => context.push(
                      RouteNames.submissionList,
                      extra: widget.assignmentId,
                    ),
                  ),
                ],

                // ── Student/Parent: Submission area ──────────────────────
                if (canSubmit && !canGrade) ...[
                  _SubmissionSection(
                    assignmentId: widget.assignmentId,
                    assignment: assignment,
                    currentUser: currentUser,
                    textCtrl: _textCtrl,
                    pickedFile: _pickedFile,
                    isSubmitting: _isSubmitting,
                    onPickFile: _pickFile,
                    onRemoveFile: _removeFile,
                    onSubmit: _submitAssignment,
                    ref: ref,
                  ),
                ],

                const SizedBox(height: AppDimensions.space40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final dynamic assignment;
  const _HeaderCard({required this.assignment});

  @override
  Widget build(BuildContext context) {
    final dueColor = assignment.isOverdue
        ? AppColors.errorRed
        : assignment.isDueToday
            ? AppColors.warningAmber
            : AppColors.grey600;
    final bgColor = assignment.isOverdue
        ? AppColors.errorLight
        : assignment.isDueToday
            ? AppColors.warningLight
            : AppColors.surface50;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.surface200),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top strip (navy)
          Container(
            decoration: const BoxDecoration(
              color: AppColors.navyDeep,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusLarge),
                topRight: Radius.circular(AppDimensions.radiusLarge),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space20,
              vertical: AppDimensions.space16,
            ),
            child: Text(
              assignment.title,
              style: AppTypography.headlineSmall
                  .copyWith(color: AppColors.white),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              children: [
                // Due date
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 16, color: dueColor),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        'Due: ${DateFormatter.formatDate(assignment.dueDate)}',
                        style: AppTypography.titleSmall
                            .copyWith(color: dueColor),
                      ),
                      if (assignment.isOverdue) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Text('(Overdue)',
                            style: AppTypography.bodySmall
                                .copyWith(color: dueColor)),
                      ],
                      if (assignment.isDueToday) ...[
                        const SizedBox(width: AppDimensions.space8),
                        Text('(Today)',
                            style: AppTypography.bodySmall
                                .copyWith(color: dueColor)),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.space12),

                // Active badge
                Row(
                  children: [
                    _InfoRow(
                        icon: Icons.toggle_on_outlined,
                        label: assignment.isActive ? 'Active' : 'Closed'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.grey400),
        const SizedBox(width: 4),
        Text(label,
            style:
                AppTypography.bodySmall.copyWith(color: AppColors.grey600)),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: AppTypography.titleSmall.copyWith(
          color: AppColors.grey800,
          fontWeight: FontWeight.w600,
        ));
  }
}

class _BodyCard extends StatelessWidget {
  final Widget child;
  const _BodyCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: child,
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  final String fileUrl;
  const _AttachmentButton({required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Open in PDF viewer or browser
        // context.push(RouteNames.pdfViewer, extra: fileUrl);
      },
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.infoBlue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_outlined,
                color: AppColors.infoBlue, size: 20),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assignment File',
                      style: AppTypography.titleSmall
                          .copyWith(color: AppColors.infoBlue)),
                  Text('Tap to view',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.infoBlue.withOpacity(0.7))),
                ],
              ),
            ),
            const Icon(Icons.open_in_new,
                color: AppColors.infoBlue, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SubmissionSection extends ConsumerWidget {
  final String assignmentId;
  final dynamic assignment;
  final dynamic currentUser;
  final TextEditingController textCtrl;
  final PlatformFile? pickedFile;
  final bool isSubmitting;
  final VoidCallback onPickFile;
  final VoidCallback onRemoveFile;
  final Future<void> Function(String studentId) onSubmit;
  final WidgetRef ref;

  const _SubmissionSection({
    required this.assignmentId,
    required this.assignment,
    required this.currentUser,
    required this.textCtrl,
    required this.pickedFile,
    required this.isSubmitting,
    required this.onPickFile,
    required this.onRemoveFile,
    required this.onSubmit,
    required this.ref,
  });

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    // Resolve student ID based on role
    final selectedChildId = widgetRef.watch(selectedChildIdProvider);
    final submissionState = widgetRef.watch(submissionCreateProvider);

    // If already submitted, show submission status
    if (submissionState is AsyncData<SubmissionModel?> &&
        submissionState.value != null) {
      final sub = submissionState.value!;
      return _SubmittedCard(submission: sub);
    }

    if (!assignment.isActive) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.space16),
        decoration: BoxDecoration(
          color: AppColors.surface100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.grey400),
            const SizedBox(width: AppDimensions.space12),
            Text(
              'This assignment is closed for submissions.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
            ),
          ],
        ),
      );
    }

    // Determine student ID
    String? studentId;
    if (currentUser?.role?.name == 'STUDENT') {
      // Fetched from student profile — resolved via parent/student provider
      studentId = selectedChildId;
    } else if (currentUser?.role?.name == 'PARENT') {
      studentId = selectedChildId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Submit Assignment'),
        const SizedBox(height: AppDimensions.space12),

        // Text response field
        AppTextField(
          controller: textCtrl,
          label: 'Your Response (optional)',
          hint: 'Write your text answer here...',
          maxLines: 5,
        ),

        const SizedBox(height: AppDimensions.space16),

        // File picker
        GestureDetector(
          onTap: onPickFile,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(
                  color: AppColors.surface200,
                  style: BorderStyle.solid),
            ),
            child: pickedFile == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_file,
                          color: AppColors.navyLight, size: 20),
                      const SizedBox(width: AppDimensions.space8),
                      Text(
                        'Tap to attach a file (PDF, image, doc)',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.navyLight),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          color: AppColors.navyDeep, size: 20),
                      const SizedBox(width: AppDimensions.space8),
                      Expanded(
                        child: Text(
                          pickedFile!.name,
                          style: AppTypography.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: AppColors.grey400),
                        onPressed: onRemoveFile,
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: AppDimensions.space20),

        AppButton.primary(
          label: 'Submit Assignment',
          onTap: studentId != null ? () => onSubmit(studentId!) : null,
          isLoading: isSubmitting,
          isDisabled: studentId == null,
        ),

        if (studentId == null) ...[
          const SizedBox(height: AppDimensions.space8),
          Text(
            'Select a student to submit the assignment.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.errorRed),
          ),
        ],
      ],
    );
  }
}

class _SubmittedCard extends StatelessWidget {
  final SubmissionModel submission;
  const _SubmittedCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 20),
              const SizedBox(width: AppDimensions.space8),
              Text('Submitted',
                  style: AppTypography.titleSmall
                      .copyWith(color: AppColors.successGreen)),
              if (submission.isLate) ...[
                const SizedBox(width: AppDimensions.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Late',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.errorRed, fontSize: 11)),
                ),
              ],
            ],
          ),
          if (submission.isGraded && submission.grade != null) ...[
            const SizedBox(height: AppDimensions.space12),
            Row(
              children: [
                Text('Grade: ',
                    style: AppTypography.titleSmall
                        .copyWith(color: AppColors.grey600)),
                Text(submission.grade!,
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            if (submission.feedback != null &&
                submission.feedback!.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.space6),
              Text('Feedback: ${submission.feedback!}',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.grey600)),
            ],
          ] else ...[
            const SizedBox(height: AppDimensions.space6),
            Text('Awaiting grade',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.grey400)),
          ],
        ],
      ),
    );
  }
}
