import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/homework/homework_model.dart';

class HomeworkCard extends StatefulWidget {
  const HomeworkCard({
    super.key,
    required this.homework,
    this.subjectName,
    this.onTap,
  });

  final HomeworkModel homework;
  final String? subjectName;
  final VoidCallback? onTap;

  @override
  State<HomeworkCard> createState() => _HomeworkCardState();
}

class _HomeworkCardState extends State<HomeworkCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.985)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  static Color _colorFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF6366F1);
    if (lower.contains('science') || lower.contains('bio')) return const Color(0xFF10B981);
    if (lower.contains('english')) return const Color(0xFF3B82F6);
    if (lower.contains('hindi')) return const Color(0xFFEC4899);
    if (lower.contains('history') || lower.contains('social')) return const Color(0xFFF97316);
    if (lower.contains('physics')) return const Color(0xFF8B5CF6);
    if (lower.contains('chem')) return const Color(0xFF14B8A6);
    return const Color(0xFF64748B);
  }

  static Color _colorFromId(String id) {
    const palette = <Color>[
      Color(0xFF6366F1),
      Color(0xFF10B981),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFFF97316),
      Color(0xFF8B5CF6),
      Color(0xFF14B8A6),
      Color(0xFF64748B),
    ];
    final index = id.codeUnits.fold(0, (acc, x) => acc + x) % palette.length;
    return palette[index];
  }

  Color get _accentColor => widget.subjectName != null
      ? _colorFromName(widget.subjectName!)
      : _colorFromId(widget.homework.subjectId);

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
        onTapUp: widget.onTap != null
            ? (_) {
                _ctrl.reverse();
                widget.onTap?.call();
              }
            : null,
        onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (widget.subjectName != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        widget.subjectName!,
                                        style: AppTypography.labelSmall.copyWith(
                                          color: color,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.calendar_today_outlined,
                                      size: 11, color: AppColors.grey400),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormatter.formatDate(widget.homework.date),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.grey400,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.homework.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey700,
                              height: 1.6,
                              fontSize: 14,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}