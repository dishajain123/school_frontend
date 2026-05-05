import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_loading.dart';

class ReportCardScreen extends ConsumerWidget {
  const ReportCardScreen({
    super.key,
    required this.studentId,
    required this.examId,
  });

  final String studentId;
  final String examId;

  bool _canUpload(CurrentUser? user) {
    if (user == null) return false;
    if (!user.hasPermission('result:create')) return false;
    return user.role == UserRole.teacher || user.role.isSchoolScopedAdmin;
  }

  Future<void> _uploadReportCard(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );
    if (!context.mounted || picked == null || picked.files.isEmpty) return;

    final file = picked.files.first;
    final uploaded = await ref.read(uploadReportCardProvider.notifier).upload(
          studentId: studentId,
          examId: examId,
          file: file,
        );
    if (!context.mounted) return;

    if (uploaded != null) {
      ref.invalidate(
          reportCardProvider((studentId: studentId, examId: examId)));
      SnackbarUtils.showSuccess(
          context, 'Report card PDF uploaded successfully.');
    } else {
      final err = ref.read(uploadReportCardProvider).error ??
          'Failed to upload report card';
      SnackbarUtils.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (studentId: studentId, examId: examId);
    final reportAsync = ref.watch(reportCardProvider(params));
    final user = ref.watch(currentUserProvider);
    final uploadState = ref.watch(uploadReportCardProvider);
    final canUpload = _canUpload(user);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Report Card',
        showBack: true,
        onBackPressed: user?.role == UserRole.parent
            ? () => context.go(RouteNames.dashboard)
            : null,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            onPressed: () => ref.invalidate(reportCardProvider(params)),
          ),
          if (canUpload)
            TextButton.icon(
              onPressed: uploadState.isUploading
                  ? null
                  : () => _uploadReportCard(context, ref),
              icon: uploadState.isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded,
                      color: AppColors.white, size: 16),
              label: Text(
                uploadState.isUploading ? 'Uploading' : 'Upload PDF',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: reportAsync.when(
        loading: _buildShimmer,
        error: (e, _) {
          final msg = e.toString().toLowerCase();
          final looksMissing = msg.contains('404') ||
              msg.contains('results not found') ||
              msg.contains('not found');
          if (looksMissing) {
            return AppEmptyState(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Report card not available yet',
              subtitle: canUpload
                  ? 'There is no PDF on file and no marks to generate one yet. '
                      'Use Upload PDF above, or pull Try again after the office '
                      'attaches results.'
                  : 'The school may still be preparing this report card, or '
                      'marks are not published yet.',
              actionLabel: 'Try again',
              onAction: () =>
                  ref.invalidate(reportCardProvider(params)),
            );
          }
          return AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(reportCardProvider(params)),
          );
        },
        data: (report) => _ReportCardDownloadBody(url: report.url),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(child: AppLoading.card(height: 160)),
    );
  }
}

/// No in-app PDF preview — download only (student, parent, teacher, principal).
class _ReportCardDownloadBody extends StatelessWidget {
  const _ReportCardDownloadBody({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.navyDeep.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 44,
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Report card ready',
                      textAlign: TextAlign.center,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap Download to open or save the PDF on your device.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppButton.primary(
                label: 'Download',
                onTap: () => downloadReportPdf(context, url),
                icon: Icons.download_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> downloadReportPdf(BuildContext context, String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return;
  final launched =
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    SnackbarUtils.showError(context, 'Unable to start download');
  }
}
