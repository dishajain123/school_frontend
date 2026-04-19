import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../common/widgets/app_button.dart';

class TimetableViewer extends StatelessWidget {
  const TimetableViewer({super.key, required this.timetable});
  final TimetableModel timetable;

  @override
  Widget build(BuildContext context) {
    final url = timetable.fileUrl!;
    if (timetable.isPdf) {
      return _PdfViewer(url: url, fileName: timetable.fileName);
    }
    if (timetable.isImage) return _ImageViewer(url: url);
    return _UnsupportedViewer(url: url, fileName: timetable.fileName);
  }
}

class _PdfViewer extends StatelessWidget {
  const _PdfViewer({required this.url, required this.fileName});
  final String url;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: AppColors.errorRed.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_outlined,
                        size: 44, color: AppColors.errorRed),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fileName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'PDF Document',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.grey500,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap "Open PDF" below to view',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomActionBar(url: url, primaryLabel: 'Open PDF'),
      ],
    );
  }
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
        _BottomActionBar(url: url, primaryLabel: 'Download Image'),
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
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
                    'Preview not available for this file type.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        _BottomActionBar(url: url, primaryLabel: 'Open File'),
      ],
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.url, required this.primaryLabel});
  final String url;
  final String primaryLabel;

  void _launch(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening: $primaryLabel'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      child: Row(
        children: [
          Expanded(
            child: AppButton.secondary(
              label: primaryLabel,
              onTap: () => _launch(context),
              icon: Icons.open_in_new_rounded,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _launch(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.surface200),
              ),
              child: const Icon(Icons.share_outlined,
                  size: 20, color: AppColors.navyDeep),
            ),
          ),
        ],
      ),
    );
  }
}