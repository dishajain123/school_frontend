import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../common/widgets/app_button.dart';
import 'timetable_pdf_network_viewer.dart';

class TimetableViewer extends StatelessWidget {
  const TimetableViewer({super.key, required this.timetable});
  final TimetableModel timetable;

  @override
  Widget build(BuildContext context) {
    final url = timetable.fileUrl!;
    if (timetable.isPdf) {
      return _PdfViewer(url: url);
    }
    if (timetable.isImage) return _ImageViewer(url: url);
    return _UnsupportedViewer(url: url, fileName: timetable.fileName);
  }
}

class _PdfViewer extends StatelessWidget {
  const _PdfViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: TimetablePdfNetworkViewer(url: url),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Pinch to zoom out or in for the full page',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: AppColors.grey500),
          ),
        ),
        _DownloadBar(onDownload: () => _openDownload(context, url)),
      ],
    );
  }
}

Future<void> _openDownload(BuildContext context, String rawUrl) async {
  final uri = Uri.tryParse(rawUrl.trim());
  if (uri == null) return;
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: AppColors.navyDeep,
                          strokeWidth: 2,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Loading timetable...',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image_outlined,
                          size: 48, color: AppColors.grey400),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load image',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.grey400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pinch_outlined, size: 14, color: AppColors.grey400),
              const SizedBox(width: 5),
              Text(
                'Pinch to zoom',
                style: AppTypography.caption.copyWith(color: AppColors.grey400),
              ),
            ],
          ),
        ),
        _DownloadBar(onDownload: () => _openDownload(context, url)),
      ],
    );
  }
}

class _UnsupportedViewer extends StatelessWidget {
  const _UnsupportedViewer({required this.url, required this.fileName});
  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surface100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.insert_drive_file_outlined,
                      size: 40, color: AppColors.grey400),
                ),
                const SizedBox(height: 20),
                Text(
                  fileName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preview is not available for this file type.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        _DownloadBar(onDownload: () => _openDownload(context, url)),
      ],
    );
  }
}

class _DownloadBar extends StatelessWidget {
  const _DownloadBar({required this.onDownload});

  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10 + bottom),
      child: AppButton.secondary(
        label: 'Download',
        onTap: onDownload,
        icon: Icons.download_outlined,
      ),
    );
  }
}
