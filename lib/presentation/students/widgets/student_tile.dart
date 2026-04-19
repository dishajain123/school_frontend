import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/student/student_model.dart';

class StudentTile extends StatefulWidget {
  const StudentTile({
    super.key,
    required this.student,
    required this.onTap,
    this.standardName,
    this.isLast = false,
    this.showSelection = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  final StudentModel student;
  final VoidCallback onTap;
  final String? standardName;
  final bool isLast;
  final bool showSelection;
  final bool isSelected;
  final ValueChanged<bool>? onSelectionChanged;

  @override
  State<StudentTile> createState() => _StudentTileState();
}

class _StudentTileState extends State<StudentTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
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
    final student = widget.student;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (widget.showSelection) ...[
                GestureDetector(
                  onTap: () =>
                      widget.onSelectionChanged?.call(!widget.isSelected),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.navyDeep
                          : AppColors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.isSelected
                            ? AppColors.navyDeep
                            : AppColors.surface200,
                        width: 1.5,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(Icons.check_rounded,
                            size: 13, color: AppColors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              _StudentAvatar(
                  admissionNumber: student.admissionNumber,
                  initials: student.initials),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.displayName,
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
                        _MetaText(label: 'Adm ${student.admissionNumber}'),
                        if (widget.standardName != null)
                          _MiniChip(
                            label: widget.standardName!,
                            color: AppColors.infoBlue,
                          ),
                        if (student.section != null)
                          _MetaText(label: 'Sec ${student.section}'),
                        if (student.rollNumber != null)
                          _MetaText(label: 'Roll ${student.rollNumber}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (student.isPromoted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Promoted',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
              if (!widget.showSelection) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.grey400),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({required this.admissionNumber, required this.initials});
  final String admissionNumber;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.avatarBackground(admissionNumber);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            Color.lerp(color, Colors.black, 0.15) ?? color,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
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

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
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
    );
  }
}
