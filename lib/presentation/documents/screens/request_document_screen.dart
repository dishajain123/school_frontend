import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';
import '../../../providers/document_provider.dart';
import '../widgets/document_type_card.dart';

/// Standalone full-screen document request screen.
/// Used when navigating via RouteNames.requestDocument.
/// The studentId MUST be passed via route extras.
class RequestDocumentScreen extends ConsumerStatefulWidget {
  const RequestDocumentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<RequestDocumentScreen> createState() =>
      _RequestDocumentScreenState();
}

class _RequestDocumentScreenState
    extends ConsumerState<RequestDocumentScreen> {
  DocumentType? _selected;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Request Document', style: AppTypography.titleLargeOnDark),
      ),
      body: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.space8),

                  // Header
                  Text(
                    'Select Document Type',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    'The document will be generated in the background. '
                    'You\'ll see it update automatically when ready.',
                    style: AppTypography.bodySmall,
                  ),

                  const SizedBox(height: AppDimensions.space24),

                  // Document type cards
                  ...DocumentType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.space12),
                      child: DocumentTypeCard(
                        type: type,
                        isSelected: _selected == type,
                        onTap: () => setState(() => _selected = type),
                      ),
                    ),
                  ),

                  // Extra space for the sticky bottom bar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // ── Sticky bottom action bar ──────────────────────────────────
          _BottomActionBar(
            selected: _selected,
            isLoading: state.isRequesting,
            bottomPadding: viewPadding.bottom,
            onSubmit: () => _submit(context),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_selected == null) return;
    final ok = await ref.read(documentProvider.notifier).requestDocument(
          studentId: widget.studentId,
          documentType: _selected!,
        );
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selected!.label} requested! It will be ready shortly.',
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
      context.pop();
    } else {
      final err = ref.read(documentProvider).error ?? 'Request failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
    }
  }
}

// ── Bottom Action Bar ─────────────────────────────────────────────────────────

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.selected,
    required this.isLoading,
    required this.bottomPadding,
    required this.onSubmit,
  });

  final DocumentType? selected;
  final bool isLoading;
  final double bottomPadding;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space12,
        AppDimensions.space16,
        AppDimensions.space12 + bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: AppDecorations.shadowBottomNav,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected type preview
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: selected != null
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                        bottom: AppDimensions.space12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space8,
                    ),
                    decoration: BoxDecoration(
                      color: selected!.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall),
                    ),
                    child: Row(
                      children: [
                        Icon(selected!.icon,
                            color: selected!.color, size: 16),
                        const SizedBox(width: AppDimensions.space8),
                        Expanded(
                          child: Text(
                            'Requesting: ${selected!.label}',
                            style: AppTypography.labelMedium.copyWith(
                              color: selected!.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: selected == null || isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('Request Document'),
            ),
          ),
        ],
      ),
    );
  }
}

