import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../common/widgets/app_button.dart';

/// Renders the timetable file inline in the view screen.
///
/// PDF  → _PdfViewer   (flutter_pdfview / syncfusion integration point)
/// Image → _ImageViewer (InteractiveViewer with pinch-zoom)
/// Other → _UnsupportedViewer (open-externally fallback)
class TimetableViewer extends StatelessWidget {
  const TimetableViewer({super.key, required this.timetable});
  final TimetableModel timetable;

  @override
  Widget build(BuildContext context) {
    final url = timetable.fileUrl!;
    if (timetable.isPdf) return _PdfViewer(url: url, fileName: timetable.fileName);
    if (timetable.isImage) return _ImageViewer(url: url);
    return _UnsupportedViewer(url: url, fileName: timetable.fileName);
  }
}

// ── PDF viewer ────────────────────────────────────────────────────────────────

class _PdfViewer extends StatelessWidget {
  const _PdfViewer({required this.url, required this.fileName});
  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    // TODO: Replace _PdfIconPreview with:
    //   flutter_pdfview → PDFView(filePath: localPath) after downloading
    //   syncfusion      → SfPdfViewer.network(url)
    return Column(
      children: [
        Expanded(child: _PdfIconPreview(fileName: fileName)),
        _BottomActionBar(url: url, primaryLabel: 'Open PDF'),
      ],
    );
  }
}

class _PdfIconPreview extends StatelessWidget {
  const _PdfIconPreview({required this.fileName});
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            ),
            child: const Icon(Icons.picture_as_pdf_outlined,
                size: 40, color: AppColors.errorRed),
          ),
          const SizedBox(height: AppDimensions.space16),
          Text(fileName,
              style: AppTypography.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppDimensions.space8),
          Text('Tap "Open PDF" to view',
              style: AppTypography.bodySmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Image viewer ──────────────────────────────────────────────────────────────

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
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      color: AppColors.navyDeep,
                      strokeWidth: 2,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      size: 56, color: AppColors.grey400),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space6),
          child: Text('Pinch to zoom',
              style: AppTypography.caption
                  .copyWith(color: AppColors.grey400)),
        ),
        _BottomActionBar(url: url, primaryLabel: 'Download Image'),
      ],
    );
  }
}

// ── Unsupported format fallback ───────────────────────────────────────────────

class _UnsupportedViewer extends StatelessWidget {
  const _UnsupportedViewer({required this.url, required this.fileName});
  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.insert_drive_file_outlined,
            size: 56, color: AppColors.grey400),
        const SizedBox(height: AppDimensions.space16),
        Text(fileName,
            style: AppTypography.titleMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppDimensions.space8),
        Text('Preview not available for this file type.',
            style: AppTypography.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: AppDimensions.space32),
        _BottomActionBar(url: url, primaryLabel: 'Open File'),
      ],
    );
  }
}

// ── Bottom action bar — Download / Share ──────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.url,
    required this.primaryLabel,
  });
  final String url;
  final String primaryLabel;

  void _launch(BuildContext context) {
    // TODO: integrate url_launcher: launchUrl(Uri.parse(url))
    // or share_plus: Share.shareUri(Uri.parse(url))
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $primaryLabel'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space20,
        AppDimensions.space8,
        AppDimensions.space20,
        AppDimensions.space20,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: primaryLabel,
              onTap: () => _launch(context),
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          // Share icon button
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.surface200),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined,
                  size: 20, color: AppColors.navyDeep),
              tooltip: 'Share',
              onPressed: () => _launch(context),
            ),
          ),
        ],
      ),
    );
  }
}