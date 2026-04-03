import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';
import '../../../providers/document_provider.dart';
import '../widgets/document_type_card.dart';

/// Modal bottom sheet variant for requesting a document.
/// Presented via showModalBottomSheet from DocumentListScreen.
class RequestDocumentSheet extends ConsumerStatefulWidget {
  const RequestDocumentSheet({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<RequestDocumentSheet> createState() =>
      _RequestDocumentSheetState();
}

class _RequestDocumentSheetState extends ConsumerState<RequestDocumentSheet> {
  DocumentType? _selected;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space12),
            child: Center(
              child: Container(
                width: AppDimensions.dragHandleWidth,
                height: AppDimensions.dragHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
          ),

          // ── Scrollable body ──────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space24,
                AppDimensions.space16,
                AppDimensions.space24,
                AppDimensions.space8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Document',
                    style: AppTypography.headlineSmall,
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    'Select a document type to request.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppDimensions.space20),

                  ...DocumentType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(
                          bottom: AppDimensions.space8),
                      child: DocumentTypeCard(
                        type: type,
                        isSelected: _selected == type,
                        onTap: () => setState(() => _selected = type),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Actions ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.space24,
              AppDimensions.space8,
              AppDimensions.space24,
              AppDimensions.space16 + bottomPadding,
            ),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                // Submit
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed:
                          _selected == null || state.isRequesting
                              ? null
                              : () => _submit(context),
                      child: state.isRequesting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.white),
                              ),
                            )
                          : const Text('Request'),
                    ),
                  ),
                ),
              ],
            ),
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
    Navigator.of(context).pop();
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.white, size: 18),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  '${_selected!.label} requested! Generating in background.',
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
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

