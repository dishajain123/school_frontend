import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/document/document_model.dart';

/// A single document list item with:
/// - Type icon (color-coded)
/// - Document type label + request/generate timestamps
/// - Status chip (animated spinner for PROCESSING)
/// - Download / open file when the document has a stored file (any review stage)
class DocumentTile extends StatelessWidget {
  const DocumentTile({
    super.key,
    required this.document,
    this.onDownload,
  });

  final DocumentModel document;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final type = document.documentType;
    final status = document.status;

    return Container(
      decoration: AppDecorations.card,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Left color accent stripe ─────────────────────────────────
          Container(
            height: 3,
            color: type.color,
          ),

          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Icon container ─────────────────────────────────────
                _DocumentIcon(type: type, status: status),
                const SizedBox(width: AppDimensions.space12),

                // ── Info column ────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.label,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((document.studentAdmissionNumber ?? '').isNotEmpty ||
                          (document.studentName ?? '').isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space2),
                        Text(
                          [
                            if ((document.studentAdmissionNumber ?? '').isNotEmpty)
                              'Adm ${document.studentAdmissionNumber}',
                            if ((document.studentName ?? '').isNotEmpty)
                              document.studentName!,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDimensions.space4),
                      _TimestampRow(document: document),
                      if (document.hasFailed &&
                          (document.reviewNote ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: AppDimensions.space6),
                        Text(
                          'Admin feedback: ${document.reviewNote!.trim()}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.errorRed,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: AppDimensions.space8),

                // ── Status + action ────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusChip(status: status),
                    if (onDownload != null) ...[
                      const SizedBox(height: AppDimensions.space8),
                      _DownloadButton(onTap: onDownload!),
                    ],
                    if (document.hasFailed &&
                        (document.reviewNote ?? '').trim().isEmpty) ...[
                      const SizedBox(height: AppDimensions.space8),
                      Text(
                        'Contact admin',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.errorRed,
                        ),
                      ),
                    ],
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

// ── Document Icon ─────────────────────────────────────────────────────────────

class _DocumentIcon extends StatelessWidget {
  const _DocumentIcon({required this.type, required this.status});
  final DocumentType type;
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: type.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: Icon(type.icon, color: type.color, size: 22),
          ),
          if (status == DocumentStatus.processing)
            Positioned.fill(
              child: _SpinningIndicator(color: type.color),
            ),
        ],
      ),
    );
  }
}

class _SpinningIndicator extends StatelessWidget {
  const _SpinningIndicator({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: 2.5,
      valueColor: AlwaysStoppedAnimation<Color>(
        color.withValues(alpha: 0.5),
      ),
    );
  }
}

// ── Timestamp Row ─────────────────────────────────────────────────────────────

class _TimestampRow extends StatelessWidget {
  const _TimestampRow({required this.document});
  final DocumentModel document;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 11, color: AppColors.grey400),
            const SizedBox(width: 3),
            Text(
              'Requested ${DateFormatter.formatRelative(document.requestedAt)}',
              style: AppTypography.caption,
            ),
          ],
        ),
        if (document.generatedAt != null) ...[
          const SizedBox(height: AppDimensions.space2),
          Row(
            children: [
              const Icon(Icons.check_rounded,
                  size: 11, color: AppColors.successGreen),
              const SizedBox(width: 3),
              Text(
                'Generated ${DateFormatter.formatRelative(document.generatedAt!)}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Status Chip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedStatusIcon(status: status),
          const SizedBox(width: AppDimensions.space4),
          Text(
            status.label,
            style: AppTypography.labelSmall.copyWith(
              color: status.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedStatusIcon extends StatelessWidget {
  const _AnimatedStatusIcon({required this.status});
  final DocumentStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == DocumentStatus.processing) {
      return SizedBox(
        width: AppDimensions.iconXS,
        height: AppDimensions.iconXS,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          valueColor: AlwaysStoppedAnimation<Color>(status.color),
        ),
      );
    }

    final icon = Icon(
      status.icon,
      color: status.color,
      size: AppDimensions.iconXS,
    );
    return icon;
  }
}

// ── Download Button ───────────────────────────────────────────────────────────

class _DownloadButton extends StatefulWidget {
  const _DownloadButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space8,
            vertical: AppDimensions.space4,
          ),
          decoration: BoxDecoration(
            color: AppColors.navyDeep,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.download_rounded,
                color: AppColors.white,
                size: AppDimensions.iconXS,
              ),
              const SizedBox(width: AppDimensions.space4),
              Text(
                'Download',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
