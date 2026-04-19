import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/assignment/submission_model.dart';
import '../../../providers/assignment_provider.dart';
import '../../../providers/submission_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_text_field.dart';

class AssignmentDetailScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  const AssignmentDetailScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends ConsumerState<AssignmentDetailScreen>
    with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _animCtrl.dispose();
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
      SnackbarUtils.showError(context, 'Provide text response or attach a file');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      MultipartFile? multipartFile;
      if (_pickedFile != null && _pickedFile!.bytes != null) {
        multipartFile = MultipartFile.fromBytes(_pickedFile!.bytes!, filename: _pickedFile!.name);
      } else if (_pickedFile != null && _pickedFile!.path != null) {
        multipartFile = await MultipartFile.fromFile(_pickedFile!.path!, filename: _pickedFile!.name);
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
        setState(() { _textCtrl.clear(); _pickedFile = null; });
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignmentAsync = ref.watch(assignmentDetailProvider(widget.assignmentId));
    final currentUser = ref.watch(currentUserProvider);
    final canCreate = currentUser?.hasPermission('assignment:create') ?? false;
    final canSubmit = currentUser?.hasPermission('submission:create') ?? false;
    final canGrade = currentUser?.hasPermission('submission:grade') ?? false;

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Assignment',
        showBack: true,
        actions: [
          if (canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined, color: AppColors.white, size: 16),
                ),
                onPressed: () => context.push(
                  RouteNames.createAssignment,
                  extra: {'editId': widget.assignmentId},
                ),
              ),
            ),
        ],
      ),
      body: assignmentAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(assignmentDetailProvider(widget.assignmentId)),
        ),
        data: (assignment) {
          return FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AssignmentHero(assignment: assignment),
                    const SizedBox(height: 20),
                    if (assignment.description != null && assignment.description!.isNotEmpty) ...[
                      _SectionLabel('Description'),
                      const SizedBox(height: 8),
                      _ContentCard(
                        child: Text(
                          assignment.description!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey700,
                            height: 1.65,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (assignment.fileUrl != null) ...[
                      _SectionLabel('Attachment'),
                      const SizedBox(height: 8),
                      _AttachmentButton(fileUrl: assignment.fileUrl!),
                      const SizedBox(height: 20),
                    ],
                    if (canGrade) ...[
                      AppButton.secondary(
                        label: 'View Student Solutions',
                        onTap: () => context.push(RouteNames.submissionListPath(widget.assignmentId)),
                        icon: Icons.fact_check_outlined,
                      ),
                    ],
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AssignmentHero extends StatelessWidget {
  const _AssignmentHero({required this.assignment});
  final dynamic assignment;

  @override
  Widget build(BuildContext context) {
    final dueColor = assignment.isOverdue
        ? AppColors.errorRed
        : assignment.isDueToday
            ? AppColors.warningAmber
            : AppColors.successGreen;
    final dueBg = assignment.isOverdue
        ? AppColors.errorLight
        : assignment.isDueToday
            ? AppColors.warningLight
            : AppColors.successLight;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  assignment.title,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (assignment.isActive ? AppColors.successGreen : AppColors.grey400)
                      .withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (assignment.isActive ? AppColors.successGreen : AppColors.grey400)
                        .withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  assignment.isActive ? 'Active' : 'Closed',
                  style: AppTypography.labelSmall.copyWith(
                    color: assignment.isActive ? AppColors.successGreen : AppColors.grey400,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: dueBg.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: dueColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: dueColor),
                const SizedBox(width: 7),
                Text(
                  'Due: ${DateFormatter.formatDate(assignment.dueDate)}',
                  style: AppTypography.labelMedium.copyWith(
                    color: dueColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                if (assignment.isOverdue) ...[
                  const SizedBox(width: 6),
                  Text('· Overdue',
                      style: AppTypography.caption.copyWith(color: dueColor)),
                ] else if (assignment.isDueToday) ...[
                  const SizedBox(width: 6),
                  Text('· Today',
                      style: AppTypography.caption.copyWith(color: dueColor)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.titleSmall.copyWith(
        color: AppColors.grey800,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surface100),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({required this.fileUrl});
  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.infoBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.infoBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Assignment File',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.infoBlue)),
                  Text('Tap to view',
                      style: AppTypography.caption.copyWith(
                          color: AppColors.infoBlue.withValues(alpha: 0.65))),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: AppColors.infoBlue, size: 16),
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
    final selectedChildId = widgetRef.watch(selectedChildIdProvider);
    final submissionState = widgetRef.watch(submissionCreateProvider);

    if (submissionState is AsyncData<SubmissionModel?> && submissionState.value != null) {
      return _SubmittedCard(submission: submissionState.value!);
    }

    if (!assignment.isActive) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline, color: AppColors.grey400, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This assignment is closed for submissions.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
              ),
            ),
          ],
        ),
      );
    }

    String? studentId;
    if (currentUser?.role == UserRole.parent ||
        currentUser?.role == UserRole.student) {
      studentId = selectedChildId;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Submit Assignment'),
        const SizedBox(height: 12),
        AppTextField(
          controller: textCtrl,
          label: 'Your Response (optional)',
          hint: 'Write your text answer here...',
          maxLines: 5,
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onPickFile,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pickedFile != null
                  ? AppColors.navyDeep.withValues(alpha: 0.04)
                  : AppColors.surface50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: pickedFile != null ? AppColors.navyMedium.withValues(alpha: 0.4) : AppColors.surface200,
                width: pickedFile != null ? 1.5 : 1,
              ),
            ),
            child: pickedFile == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.attach_file_rounded, color: AppColors.navyMedium, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to attach file (PDF, image, doc)',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.navyMedium),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.navyDeep.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.insert_drive_file_outlined,
                            color: AppColors.navyDeep, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(pickedFile!.name,
                            style: AppTypography.titleSmall, overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: onRemoveFile,
                        child: const Icon(Icons.close_rounded, size: 18, color: AppColors.grey400),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),
        AppButton.primary(
          label: 'Submit Assignment',
          onTap: studentId != null ? () => onSubmit(studentId!) : null,
          isLoading: isSubmitting,
          isDisabled: studentId == null,
          icon: Icons.upload_rounded,
        ),
        if (studentId == null) ...[
          const SizedBox(height: 8),
          Text(
            'Select a student to submit the assignment.',
            style: AppTypography.caption.copyWith(color: AppColors.errorRed),
          ),
        ],
      ],
    );
  }
}

class _SubmittedCard extends StatelessWidget {
  const _SubmittedCard({required this.submission});
  final SubmissionModel submission;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_rounded, color: AppColors.successGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Text('Submitted',
                  style: AppTypography.titleSmall.copyWith(color: AppColors.successGreen)),
              if (submission.isLate) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Late',
                      style: AppTypography.labelSmall.copyWith(
                          color: AppColors.errorRed, fontWeight: FontWeight.w600, fontSize: 10)),
                ),
              ],
            ],
          ),
          if (submission.isGraded && submission.grade != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Grade: ',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.grey600)),
                Text(submission.grade!,
                    style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navyDeep, fontWeight: FontWeight.w700)),
              ],
            ),
            if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Feedback: ${submission.feedback!}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.grey600)),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text('Awaiting grade',
                style: AppTypography.caption.copyWith(color: AppColors.grey500)),
          ],
        ],
      ),
    );
  }
}
