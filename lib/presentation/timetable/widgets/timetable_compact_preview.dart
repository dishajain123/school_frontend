import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../common/widgets/app_button.dart';

/// Summary of an existing timetable file — download only (no in-app preview).
class TimetableCompactPreview extends StatelessWidget {
  const TimetableCompactPreview({
    super.key,
    required this.timetable,
    /// Optional label e.g. exam schedule name when listing multiple.
    this.heading,
    /// When [false], hides the "upload below" replacement hint (read-only screens).
    this.showReplaceHint = true,
  });

  final TimetableModel timetable;
  final String? heading;
  final bool showReplaceHint;

  Future<void> _openFile() async {
    final raw = timetable.fileUrl?.trim();
    if (raw == null || raw.isEmpty) return;
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final url = timetable.fileUrl;
    final hasUrl = url != null && url.isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (heading != null && heading!.trim().isNotEmpty) ...[
            Text(
              heading!.trim(),
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.grey800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Current file: ${timetable.fileName}',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            showReplaceHint
                ? 'Use Download to open the file, or replace it by uploading below.'
                : 'Tap Download to open the exam schedule file.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Uploaded by ${timetable.uploadedByName?.trim().isNotEmpty == true ? timetable.uploadedByName!.trim() : 'Staff'} on ${DateFormatter.formatDateTime(timetable.updatedAt)}',
            style: AppTypography.caption.copyWith(
              color: AppColors.grey500,
            ),
          ),
          const SizedBox(height: 12),
          AppButton.secondary(
            label: 'Download',
            onTap: hasUrl ? _openFile : null,
            icon: Icons.download_outlined,
            isDisabled: !hasUrl,
          ),
        ],
      ),
    );
  }
}
