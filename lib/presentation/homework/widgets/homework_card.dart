import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/homework/homework_model.dart';

/// Card widget for a single homework entry.
///
/// [subjectName] is optional — when provided (teachers), it drives the colour
/// stripe and label.  When null (students/parents), a consistent colour is
/// derived from the [homework.subjectId] hash so each subject always renders
/// the same colour across sessions.
class HomeworkCard extends StatelessWidget {
  const HomeworkCard({
    super.key,
    required this.homework,
    this.subjectName,
    this.onTap,
  });

  final HomeworkModel homework;
  final String? subjectName;
  final VoidCallback? onTap;

  // ── Colour helpers ──────────────────────────────────────────────────────────

  /// Returns a deterministic colour for a subject based on its name.
  static Color _colorFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return AppColors.subjectMath;
    if (lower.contains('science') || lower.contains('bio'))
      return AppColors.subjectScience;
    if (lower.contains('english')) return AppColors.subjectEnglish;
    if (lower.contains('hindi')) return AppColors.subjectHindi;
    if (lower.contains('history') || lower.contains('social'))
      return AppColors.subjectHistory;
    if (lower.contains('physics')) return AppColors.subjectPhysics;
    if (lower.contains('chem')) return AppColors.subjectChem;
    return AppColors.subjectDefault;
  }

  /// Derives a consistent colour from the subject UUID when the name is unknown.
  static Color _colorFromId(String id) {
    const palette = <Color>[
      AppColors.subjectMath,
      AppColors.subjectScience,
      AppColors.subjectEnglish,
      AppColors.subjectHindi,
      AppColors.subjectHistory,
      AppColors.subjectPhysics,
      AppColors.subjectChem,
      AppColors.subjectDefault,
    ];
    final index = id.codeUnits.fold(0, (acc, x) => acc + x) % palette.length;
    return palette[index];
  }

  Color get _accentColor => subjectName != null
      ? _colorFromName(subjectName!)
      : _colorFromId(homework.subjectId);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space6,
      ),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left subject colour stripe ──────────────────────
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.only(
                        topLeft:
                            Radius.circular(AppDimensions.radiusMedium),
                        bottomLeft:
                            Radius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                  ),

                  // ── Card content ────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppDimensions.space12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: subject chip + date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (subjectName != null) ...[
                                _SubjectChip(
                                    name: subjectName!, color: color),
                                const SizedBox(width: AppDimensions.space8),
                              ],
                              const Spacer(),
                              _DateLabel(date: homework.date),
                            ],
                          ),

                          const SizedBox(height: AppDimensions.space8),

                          // Description — main focal point
                          Text(
                            homework.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey800,
                              height: 1.55,
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

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        name,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateLabel extends StatelessWidget {
  const _DateLabel({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 11, color: AppColors.grey400),
        const SizedBox(width: 4),
        Text(
          DateFormatter.formatDate(date),
          style: AppTypography.caption.copyWith(color: AppColors.grey400),
        ),
      ],
    );
  }
}

// ── AppColors extension for subject colours ───────────────────────────────────
// (mirrors assignment_card.dart — defined here so homework_card is self-contained)

extension _SubjectColors on AppColors {
  static const Color subjectMath = Color(0xFF6366F1);
  static const Color subjectScience = Color(0xFF10B981);
  static const Color subjectEnglish = Color(0xFF3B82F6);
  static const Color subjectHindi = Color(0xFFEC4899);
  static const Color subjectHistory = Color(0xFFF97316);
  static const Color subjectPhysics = Color(0xFF8B5CF6);
  static const Color subjectChem = Color(0xFF14B8A6);
  static const Color subjectDefault = Color(0xFF64748B);
}