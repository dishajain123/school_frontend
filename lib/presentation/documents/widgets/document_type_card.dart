import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/document/document_model.dart';
import '../../../core/theme/app_decorations.dart';

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
      case DocumentType.leavingCertificate:
        return 'Required for school transfers';
      case DocumentType.reportCard:
        return 'Academic performance report';
      case DocumentType.transferCertificate:
        return 'For admission to another institution';
      case DocumentType.characterCertificate:
        return 'Certificate of good conduct';
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: isSelected
                ? type.color.withValues(alpha: 0.06)
                : AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: isSelected ? type.color : AppColors.surface200,
              width: isSelected
                  ? AppDimensions.borderMedium
                  : AppDimensions.borderThin,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: type.color.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppDecorations.shadow1,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.12),
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusMedium),
                ),
                child: Icon(type.icon, color: type.color, size: 22),
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
                            ? type.color.withValues(alpha: 0.7)
                            : AppColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppDimensions.space8),

              // Selection indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: isSelected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('selected'),
                        color: type.color,
                        size: AppDimensions.iconMD)
                    : Icon(Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('unselected'),
                        color: AppColors.grey400,
                        size: AppDimensions.iconMD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_import
