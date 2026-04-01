import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../common/widgets/app_avatar.dart';

class ParentTile extends StatelessWidget {
  const ParentTile({
    super.key,
    required this.parent,
    required this.onTap,
    this.isLast = false,
  });

  final ParentModel parent;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.navyLight.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space16,
            vertical: AppDimensions.space12,
          ),
          child: Row(
            children: [
              AppAvatar.md(
                imageUrl: parent.profilePhotoUrl,
                name: parent.displayName,
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.displayName,
                      style: AppTypography.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppDimensions.space4),
                    Row(
                      children: [
                        _RelationBadge(relation: parent.relation),
                        if (parent.occupation != null) ...[
                          const SizedBox(width: AppDimensions.space8),
                          Expanded(
                            child: Text(
                              parent.occupation!,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.space8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: parent.isActive
                          ? AppColors.successGreen
                          : AppColors.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelationBadge extends StatelessWidget {
  const _RelationBadge({required this.relation});
  final RelationType relation;

  Color get _color {
    switch (relation) {
      case RelationType.mother:
        return AppColors.subjectHindi;
      case RelationType.father:
        return AppColors.infoBlue;
      case RelationType.guardian:
        return AppColors.subjectMath;
    }
  }

  IconData get _icon {
    switch (relation) {
      case RelationType.mother:
        return Icons.female_rounded;
      case RelationType.father:
        return Icons.male_rounded;
      case RelationType.guardian:
        return Icons.supervisor_account_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10, color: _color),
          const SizedBox(width: 3),
          Text(
            relation.label,
            style: AppTypography.labelSmall.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}