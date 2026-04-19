import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AttendanceRing extends StatefulWidget {
  const AttendanceRing({
    super.key,
    required this.percentage,
    this.size = 72,
  });

  final double percentage;
  final double size;

  @override
  State<AttendanceRing> createState() => _AttendanceRingState();
}

class _AttendanceRingState extends State<AttendanceRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.percentage / 100).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _ringColor(double pct) {
    if (pct >= 85) return AppColors.successGreen;
    if (pct >= 75) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final color = _ringColor(widget.percentage);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: _anim.value,
                strokeWidth: 5,
                backgroundColor: AppColors.surface100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeCap: StrokeCap.round,
              ),
              Text(
                '${widget.percentage.toStringAsFixed(0)}%',
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}