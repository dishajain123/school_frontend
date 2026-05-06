import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';

/// PDF preview for timetable-style URLs: white page background, starts at page 1,
/// pinch-zoom on the **outer** [InteractiveViewer] to zoom out and see more of the page.
class TimetablePdfNetworkViewer extends StatefulWidget {
  const TimetablePdfNetworkViewer({
    super.key,
    required this.url,
    this.interactiveMinScale = 0.3,
  });

  final String url;
  final double interactiveMinScale;

  @override
  State<TimetablePdfNetworkViewer> createState() =>
      _TimetablePdfNetworkViewerState();
}

class _TimetablePdfNetworkViewerState extends State<TimetablePdfNetworkViewer> {
  final PdfViewerController _controller = PdfViewerController();
  bool _loadFailed = false;
  String? _loadErrorText;

  @override
  void didUpdateWidget(covariant TimetablePdfNetworkViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _loadFailed = false;
        _loadErrorText = null;
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url.trim());
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      SnackbarUtils.showError(context, 'Could not open the file');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return ColoredBox(
        color: AppColors.white,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_outlined,
                  size: 40,
                  color: AppColors.grey400,
                ),
                const SizedBox(height: AppDimensions.space12),
                Text(
                  'Could not open this PDF in the app.',
                  textAlign: TextAlign.center,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_loadErrorText != null &&
                    _loadErrorText!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    _loadErrorText!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.grey600,
                    ),
                  ),
                ],
                const SizedBox(height: AppDimensions.space16),
                TextButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Open in browser'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final themedViewer = Theme(
      data: Theme.of(context).copyWith(
        canvasColor: AppColors.white,
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: AppColors.white,
            ),
      ),
      child: ColoredBox(
        color: AppColors.white,
        child: SfPdfViewer.network(
          widget.url,
          key: ValueKey<String>(widget.url),
          controller: _controller,
          pageLayoutMode: PdfPageLayoutMode.continuous,
          scrollDirection: PdfScrollDirection.vertical,
          interactionMode: PdfInteractionMode.pan,
          canShowPaginationDialog: false,
          canShowScrollHead: false,
          enableDoubleTapZooming: false,
          maxZoomLevel: 1,
          initialZoomLevel: 1,
          pageSpacing: 8,
          onDocumentLoaded: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              try {
                _controller.jumpToPage(1);
              } catch (_) {}
            });
          },
          onDocumentLoadFailed: (details) {
            if (!mounted) return;
            final msg = details.description.isNotEmpty
                ? details.description
                : details.error.toString();
            setState(() {
              _loadFailed = true;
              _loadErrorText = msg.isNotEmpty ? msg : null;
            });
          },
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : size.width;
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : (size.height * 0.45).clamp(240.0, size.height);

        return InteractiveViewer(
          clipBehavior: Clip.hardEdge,
          minScale: widget.interactiveMinScale,
          maxScale: 4,
          boundaryMargin: const EdgeInsets.all(160),
          child: SizedBox(
            width: w,
            height: h,
            child: themedViewer,
          ),
        );
      },
    );
  }
}
