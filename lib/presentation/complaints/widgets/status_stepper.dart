import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/complaint/complaint_model.dart';

class StatusStepper extends StatelessWidget {
  const StatusStepper({super.key, required this.currentStatus});

  final ComplaintStatus currentStatus;

  static const List<ComplaintStatus> _steps = [
    ComplaintStatus.open,
    ComplaintStatus.inProgress,
    ComplaintStatus.resolved,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStatus == ComplaintStatus.closed
        ? _steps.length - 1
        : currentStatus.indexValue;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final connectorIndex = i ~/ 2;
          final done = connectorIndex < currentIndex;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: done ? AppColors.successGreen : AppColors.surface200,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final step = _steps[stepIndex];
        final done = stepIndex < currentIndex;
        final active = stepIndex == currentIndex;
        final stepColor = done ? AppColors.successGreen : step.color;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.successGreen
                    : active
                        ? stepColor
                        : AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(
                  color: done || active ? stepColor : AppColors.surface200,
                  width: active ? 2 : 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: stepColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 15, color: AppColors.white)
                    : Icon(
                        step.icon,
                        size: 13,
                        color: active ? AppColors.white : stepColor,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 72,
              child: Text(
                step.label,
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: active || done ? AppColors.grey800 : AppColors.grey400,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}