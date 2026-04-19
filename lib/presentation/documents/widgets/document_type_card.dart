// presentation/documents/widgets/document_type_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';

class DocumentTypeCard extends StatefulWidget {
  const DocumentTypeCard({
    super.key,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final DocumentType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<DocumentTypeCard> createState() => _DocumentTypeCardState();
}

class _DocumentTypeCardState extends State<DocumentTypeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _description(DocumentType type) {
    switch (type) {
      case DocumentType.idCard:
        return 'Official student identity card';
      case DocumentType.bonafide:
        return 'Certificate confirming enrollment status';
      case DocumentType.leavingCert:
        return 'Required for school transfers';
      case DocumentType.reportCard:
        return 'Academic performance report';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final type = widget.type;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppDimensions.space12),
          decoration: BoxDecoration(
            color: isSelected
                ? type.color.withValues(alpha: 0.05)
                : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? type.color.withValues(alpha: 0.6)
                  : AppColors.surface200,
              width: isSelected
                  ? AppDimensions.borderMedium
                  : AppDimensions.borderThin,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: type.color.withValues(alpha: 0.14),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppDecorations.shadow1,
          ),
          child: Row(
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? type.color.withValues(alpha: 0.14)
                      : type.color.withValues(alpha: 0.08),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(type.icon, color: type.color, size: 21),
              ),
              const SizedBox(width: AppDimensions.space12),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type.label,
                      style: AppTypography.titleSmall.copyWith(
                        color: isSelected ? type.color : AppColors.grey800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.space2),
                    Text(
                      _description(type),
                      style: AppTypography.caption.copyWith(
                        color: isSelected
                            ? type.color.withValues(alpha: 0.65)
                            : AppColors.grey500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.space8),

              // Selection indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: type.color,
                        size: AppDimensions.iconMD)
                    : const Icon(Icons.radio_button_unchecked_rounded,
                        key: ValueKey('unselected'),
                        color: AppColors.surface200,
                        size: AppDimensions.iconMD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
