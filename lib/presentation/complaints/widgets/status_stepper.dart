import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/complaint/complaint_model.dart';

class StatusStepper extends StatelessWidget {
  const StatusStepper({
    super.key,
    required this.currentStatus,
  });

  final ComplaintStatus currentStatus;

  static const List<ComplaintStatus> _steps = [
    ComplaintStatus.open,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
    ComplaintStatus.closed,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStatus.indexValue;

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final connectorIndex = i ~/ 2;
          final done = connectorIndex < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: done ? AppColors.successGreen : AppColors.surface200,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final step = _steps[stepIndex];
        final done = stepIndex < currentIndex;
        final active = stepIndex == currentIndex;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.successGreen
                    : (active ? step.color : AppColors.white),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: done || active ? step.color : AppColors.surface200,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: AppColors.white,
                      )
                    : Icon(
                        step.icon,
                        size: 12,
                        color: active ? AppColors.white : step.color,
                      ),
              ),
            ),
            const SizedBox(height: AppDimensions.space6),
            SizedBox(
              width: 70,
              child: Text(
                step.label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: active || done ? AppColors.grey800 : AppColors.grey400,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
