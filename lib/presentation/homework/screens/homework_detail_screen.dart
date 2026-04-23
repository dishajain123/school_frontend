import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/homework/homework_model.dart';
import '../../../data/models/homework/homework_submission_model.dart';
import '../../../data/repositories/homework_repository.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/homework_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class HomeworkDetailScreen extends ConsumerStatefulWidget {
  const HomeworkDetailScreen({
    super.key,
    required this.homeworkId,
    this.initialHomework,
  });

  final String homeworkId;
  final HomeworkModel? initialHomework;

  @override
  ConsumerState<HomeworkDetailScreen> createState() =>
      _HomeworkDetailScreenState();
}

class _HomeworkDetailScreenState extends ConsumerState<HomeworkDetailScreen> {
  final _responseCtrl = TextEditingController();
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitResponse({
    required HomeworkModel homework,
    required UserRole role,
  }) async {
    final text = _responseCtrl.text.trim();
    if (text.isEmpty && _pickedFile == null) {
      SnackbarUtils.showError(
        context,
        'Please enter response text or attach a file',
      );
      return;
    }

    String? studentId;
    if (role == UserRole.parent) {
      studentId = ref.read(selectedChildIdProvider);
      if (studentId == null) {
        SnackbarUtils.showError(context, 'Please select a child first');
        return;
      }
    }
    if (role == UserRole.student) {
      studentId = await ref.read(currentStudentIdProvider.future);
      if (!mounted) return;
      if (studentId == null) {
        SnackbarUtils.showError(context, 'Student profile not found');
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(homeworkRepositoryProvider);
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
      await repo.createResponse(
        homeworkId: homework.id,
        textResponse: text.isEmpty ? null : text,
        studentId: role == UserRole.parent ? studentId : null,
        file: multipartFile,
      );
      if (!mounted) return;
      _responseCtrl.clear();
      setState(() => _pickedFile = null);
      ref.invalidate(
        homeworkResponsesProvider((
          homeworkId: homework.id,
          studentId: role == UserRole.parent ? studentId : null,
        )),
      );
      SnackbarUtils.showSuccess(context, 'Homework response submitted');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        if (!mounted) return;
        ref.invalidate(
          homeworkResponsesProvider((
            homeworkId: homework.id,
            studentId: role == UserRole.parent ? studentId : null,
          )),
        );
        SnackbarUtils.showInfo(
          context,
          'Already submitted from linked account. Showing existing response.',
        );
        return;
      }
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reviewSubmission(HomeworkSubmissionModel submission) async {
    final feedbackCtrl = TextEditingController(text: submission.feedback ?? '');
    bool approved = submission.isApproved;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Response',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: feedbackCtrl,
                    label: 'Feedback',
                    hint: 'Write review feedback...',
                    minLines: 3,
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: approved,
                    onChanged: (value) => setSheetState(() => approved = value),
                    title: const Text('Mark as approved'),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Save Review'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != true) return;

    try {
      final repo = ref.read(homeworkRepositoryProvider);
      await repo.reviewResponse(
        submissionId: submission.id,
        feedback:
            feedbackCtrl.text.trim().isEmpty ? null : feedbackCtrl.text.trim(),
        isApproved: approved,
      );
      if (!mounted) return;
      ref.invalidate(
        homeworkResponsesProvider((
          homeworkId: widget.homeworkId,
          studentId: null,
        )),
      );
      SnackbarUtils.showSuccess(context, 'Review updated');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty && mounted) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  void _removePickedFile() {
    setState(() => _pickedFile = null);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final role = user?.role;
    final selectedChildId = ref.watch(selectedChildIdProvider);
    final studentIdAsync = ref.watch(currentStudentIdProvider);

    if (role == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Homework', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (role == UserRole.parent && selectedChildId == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Homework Details', showBack: true),
        body: AppEmptyState(
          icon: Icons.family_restroom_outlined,
          title: 'Select Child',
          subtitle:
              'Please select a child to view or submit homework response.',
        ),
      );
    }

    if (role == UserRole.student && studentIdAsync.isLoading) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'Homework Details', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final studentIdFilter = switch (role) {
      UserRole.parent => selectedChildId,
      UserRole.student => studentIdAsync.valueOrNull,
      _ => null,
    };

    final responseAsync = ref.watch(
      homeworkResponsesProvider((
        homeworkId: widget.homeworkId,
        studentId: role == UserRole.parent ? studentIdFilter : null,
      )),
    );
    final canRespond = role == UserRole.parent || role == UserRole.student;
    final hasExistingSubmission =
        canRespond && (responseAsync.valueOrNull?.items.isNotEmpty ?? false);
    final canReview = role == UserRole.teacher;
    final hw = widget.initialHomework;

    return AppScaffold(
      appBar: const AppAppBar(title: 'Homework Details', showBack: true),
      body: hw == null
          ? const AppEmptyState(
              icon: Icons.menu_book_outlined,
              title: 'Homework not found',
              subtitle: 'Please go back and open homework again.',
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyDeep.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    hw.description,
                    style: AppTypography.bodyMedium.copyWith(height: 1.5),
                  ),
                ),
                if (hw.fileUrl != null && hw.fileUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _HomeworkAttachmentButton(fileUrl: hw.fileUrl!),
                  ),
                if (canRespond && !hasExistingSubmission) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: AppTextField(
                      controller: _responseCtrl,
                      label: 'Your Response',
                      hint: 'Write completed work details...',
                      minLines: 3,
                      maxLines: 6,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: GestureDetector(
                      onTap: _pickFile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _pickedFile != null
                              ? AppColors.navyDeep.withValues(alpha: 0.04)
                              : AppColors.surface50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _pickedFile != null
                                ? AppColors.navyMedium.withValues(alpha: 0.4)
                                : AppColors.surface200,
                            width: _pickedFile != null ? 1.5 : 1,
                          ),
                        ),
                        child: _pickedFile == null
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.attach_file_rounded,
                                      color: AppColors.navyMedium, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Attach response file (PDF/image/doc)',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.navyMedium,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: AppColors.navyDeep,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _pickedFile!.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.bodySmall,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _removePickedFile,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 18,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitResponse(
                                  homework: hw,
                                  role: role,
                                ),
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Submit Response'),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: responseAsync.when(
                    loading: AppLoading.fullPage,
                    error: (e, _) => AppErrorState(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(
                        homeworkResponsesProvider((
                          homeworkId: widget.homeworkId,
                          studentId:
                              role == UserRole.parent ? studentIdFilter : null,
                        )),
                      ),
                    ),
                    data: (response) {
                      final hasExistingSubmissionInList =
                          canRespond && response.items.isNotEmpty;
                      if (response.items.isEmpty) {
                        return const AppEmptyState(
                          icon: Icons.assignment_outlined,
                          title: 'No responses yet',
                          subtitle:
                              'Responses will appear here after submission.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: response.items.length +
                            (hasExistingSubmissionInList ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          if (hasExistingSubmissionInList && index == 0) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.successGreen
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Submitted already for this child. '
                                'Both parent and student accounts stay synced.',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.successGreen,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          }
                          final item = response.items[
                              hasExistingSubmissionInList ? index - 1 : index];
                          return _SubmissionCard(
                            item: item,
                            canReview: canReview,
                            onReview: canReview
                                ? () => _reviewSubmission(item)
                                : null,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  const _SubmissionCard({
    required this.item,
    required this.canReview,
    this.onReview,
  });

  final HomeworkSubmissionModel item;
  final bool canReview;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final statusColor = item.isReviewed
        ? (item.isApproved ? AppColors.successGreen : AppColors.warningAmber)
        : AppColors.infoBlue;
    final statusLabel = item.isReviewed
        ? (item.isApproved ? 'Reviewed • Approved' : 'Reviewed')
        : 'Pending Review';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.studentName ??
                      item.studentAdmissionNumber ??
                      'Student Response',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  statusLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.textResponse,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.grey700),
          ),
          if (item.fileUrl != null && item.fileUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _HomeworkAttachmentButton(fileUrl: item.fileUrl!),
          ],
          if ((item.feedback ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Teacher Feedback: ${item.feedback}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.navyMedium,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (canReview) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HomeworkAttachmentButton extends StatelessWidget {
  const _HomeworkAttachmentButton({required this.fileUrl});

  final String fileUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_outlined,
            color: AppColors.infoBlue,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              fileUrl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.infoBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => SnackbarUtils.showInfo(
              context,
              'Attachment URL: $fileUrl',
            ),
            icon: const Icon(
              Icons.open_in_new_rounded,
              color: AppColors.infoBlue,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
