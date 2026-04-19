// presentation/documents/screens/request_document_screen.dart

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

class RequestDocumentScreen extends ConsumerStatefulWidget {
  const RequestDocumentScreen({super.key, required this.studentId});

  final String studentId;

  @override
  ConsumerState<RequestDocumentScreen> createState() =>
      _RequestDocumentScreenState();
}

class _RequestDocumentScreenState
    extends ConsumerState<RequestDocumentScreen>
    with SingleTickerProviderStateMixin {
  DocumentType? _selected;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

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
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppDimensions.space8),
                      _HeaderCard(),
                      const SizedBox(height: AppDimensions.space20),
                      _TypesLabel(),
                      const SizedBox(height: AppDimensions.space12),
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
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
              _BottomActionBar(
                selected: _selected,
                isLoading: state.isRequesting,
                bottomPadding: viewPadding.bottom,
                onSubmit: () => _submit(context),
              ),
            ],
          ),
        ),
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
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.white, size: 18),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  '${_selected!.label} requested! It will be ready shortly.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                  ),
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

class _HeaderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: AppDecorations.shadow2,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.white, size: 22),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Document Request',
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  'Generated in background · auto-updates when ready',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypesLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.goldPrimary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        ),
        const SizedBox(width: AppDimensions.space8),
        Text(
          'Select Document Type',
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
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
                      border: Border.all(
                        color: selected!.color.withValues(alpha: 0.2),
                        width: AppDimensions.borderThin,
                      ),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.check_circle_rounded,
                            color: selected!.color, size: 16),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyDeep,
                foregroundColor: AppColors.white,
                disabledBackgroundColor:
                    AppColors.navyDeep.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
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
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: AppDimensions.space8),
                        Text('Request Document',
                            style: AppTypography.buttonPrimary),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
