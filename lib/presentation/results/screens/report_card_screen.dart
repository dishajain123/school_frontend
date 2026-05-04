import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_error_state.dart';
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
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportCardProvider(params)),
        ),
        data: (report) => _ReportUrlCard(url: report.url),
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AppLoading.card(height: 220),
    );
  }
}

class _ReportUrlCard extends StatelessWidget {
  const _ReportUrlCard({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Card Link',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The report card is available as a secure link.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.surface200),
                ),
                child: SelectableText(
                  url,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showPdfPreview(context, url),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: const Text('View PDF'),
                    ),
                    TextButton.icon(
                      onPressed: () => _downloadPdf(context, url),
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Download'),
                    ),
                    TextButton.icon(
                      onPressed: () => _showOpenDialog(context, url),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Open Link'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _downloadPdf(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    SnackbarUtils.showError(context, 'Unable to open download link');
  }
}

void _showPdfPreview(BuildContext context, String url) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      height: MediaQuery.of(ctx).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Expanded(
            child: SfPdfViewer.network(url),
          ),
        ],
      ),
    ),
  );
}

void _showOpenDialog(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Open Report Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Copy and open this link in your browser:'),
          const SizedBox(height: 8),
          SelectableText(
            url,
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
