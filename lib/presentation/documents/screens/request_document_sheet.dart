// presentation/documents/screens/request_document_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';
import '../../../providers/document_provider.dart';
import '../widgets/document_type_card.dart';

class RequestDocumentSheet extends ConsumerStatefulWidget {
  const RequestDocumentSheet({
    super.key,
    required this.studentId,
    this.allowedRequirements,
  });

  final String studentId;
  final List<RequiredDocumentModel>? allowedRequirements;

  @override
  ConsumerState<RequestDocumentSheet> createState() =>
      _RequestDocumentSheetState();
}

class _RequestDocumentSheetState extends ConsumerState<RequestDocumentSheet> {
  RequiredDocumentModel? _selected;
  final TextEditingController _customNameCtrl = TextEditingController();

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentProvider);
    final requirements = widget.allowedRequirements ??
        DocumentType.values
            .map((type) => RequiredDocumentModel(documentType: type))
            .toList(growable: false);
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // ── Drag handle ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: AppDimensions.space12),
            child: Center(
              child: Container(
                width: AppDimensions.dragHandleWidth,
                height: AppDimensions.dragHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.surface200,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),
          ),

          // ── Header ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space24,
              AppDimensions.space16,
              AppDimensions.space24,
              AppDimensions.space4,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                  child: const Icon(Icons.description_outlined,
                      size: 18, color: AppColors.navyDeep),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request Document',
                        style: AppTypography.headlineSmall),
                    Text(
                      'Ask the school to issue or upload it (e.g. ID card, report card)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(
                vertical: AppDimensions.space12,
                horizontal: AppDimensions.space24),
            height: 1,
            color: AppColors.surface100,
          ),

          // ── Scrollable body ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space24,
                0,
                AppDimensions.space24,
                AppDimensions.space8,
              ),
              child: Column(
                children: [
                  ...requirements.map(
                    (req) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppDimensions.space8),
                      child: DocumentTypeCard(
                        type: req.documentType,
                        isSelected: identical(_selected, req),
                        titleOverride:
                            req.documentType == DocumentType.other &&
                                    (req.note ?? '').trim().isNotEmpty
                                ? req.note!.trim()
                                : null,
                        descriptionOverride:
                            req.documentType == DocumentType.other &&
                                    (req.note ?? '').trim().isNotEmpty
                                ? ((req.note ?? '').toLowerCase().contains('fee'))
                                    ? 'Official fee receipt or fee statement from the school'
                                    : 'Requested by your school'
                                : null,
                        onTap: () => setState(() {
                          _selected = req;
                          if (req.documentType == DocumentType.other) {
                            _customNameCtrl.text = (req.note ?? '').trim();
                          } else {
                            _customNameCtrl.clear();
                          }
                        }),
                      ),
                    ),
                  ),
                  if (_selected?.documentType == DocumentType.other) ...[
                    const SizedBox(height: AppDimensions.space8),
                    TextField(
                      controller: _customNameCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Document name (required)',
                        hintText: 'e.g. Leaving certificate, Migration certificate',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'This custom name will be visible to school admin.',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.grey600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // ── Actions ───────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.space24,
              AppDimensions.space12,
              AppDimensions.space24,
              AppDimensions.space16 + bottomPadding,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border: Border(
                top: BorderSide(color: AppColors.surface100),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.grey600,
                        side: const BorderSide(color: AppColors.surface200),
                        // Override global infinite min width for Row layouts.
                        minimumSize:
                            const Size(0, AppDimensions.buttonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.space16),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: SizedBox(
                    height: AppDimensions.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _selected == null || state.isRequesting
                          ? null
                          : () => _submit(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyDeep,
                        foregroundColor: AppColors.white,
                        minimumSize:
                            const Size(0, AppDimensions.buttonHeight),
                        disabledBackgroundColor:
                            AppColors.navyDeep.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusMedium),
                        ),
                      ),
                      child: state.isRequesting
                          ? Text(
                              'Sending…',
                              style: AppTypography.buttonPrimary,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.send_rounded, size: 16),
                                const SizedBox(width: AppDimensions.space8),
                                Text('Request',
                                    style: AppTypography.buttonPrimary),
                              ],
                            ),
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
    final selectedType = _selected!.documentType;
    String? customNote;
    if (selectedType == DocumentType.other) {
      final text = _customNameCtrl.text.trim();
      if (text.isEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Please enter custom document name'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      customNote = text;
    }
    final ok = await ref.read(documentProvider.notifier).requestDocument(
          studentId: widget.studentId,
          documentType: selectedType,
          note: customNote,
        );
    if (ok) {
      if (!context.mounted) return;
      Navigator.of(context).pop(_selected);
    } else {
      if (!context.mounted) return;
      final err = ref.read(documentProvider).error ?? 'Request failed.';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
      );
    }
  }
}
