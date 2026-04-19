import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/parent/parent_model.dart';

class ParentTile extends StatefulWidget {
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
  State<ParentTile> createState() => _ParentTileState();
}

class _ParentTileState extends State<ParentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.985)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parent = widget.parent;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _ParentAvatar(
                name: parent.displayName,
                relation: parent.relation,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parent.displayName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.grey800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _RelationChip(relation: parent.relation),
                        if (parent.occupation != null)
                          _MetaText(label: parent.occupation!),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: parent.isActive
                          ? AppColors.successGreen
                          : AppColors.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
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

class _ParentAvatar extends StatelessWidget {
  const _ParentAvatar({
    required this.name,
    required this.relation,
  });

  final String name;
  final RelationType relation;

  Color get _baseColor {
    switch (relation) {
      case RelationType.mother:
        return AppColors.subjectHindi;
      case RelationType.father:
        return AppColors.infoBlue;
      case RelationType.guardian:
        return AppColors.subjectMath;
    }
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _baseColor;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.18) ?? color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _initials,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _RelationChip extends StatelessWidget {
  const _RelationChip({required this.relation});
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
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            relation.label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.grey500,
        fontSize: 11,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}