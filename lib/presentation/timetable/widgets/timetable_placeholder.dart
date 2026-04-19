import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';

class TimetablePlaceholder extends ConsumerWidget {
  const TimetablePlaceholder({super.key, required this.canUpload});
  final bool canUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: AppColors.navyDeep.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.calendar_view_week_outlined,
                size: 40,
                color: AppColors.navyMedium,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No timetable uploaded',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              canUpload
                  ? 'Upload a PDF or image timetable for this class.'
                  : 'The timetable hasn\'t been uploaded yet.\nCheck back later.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey500,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),
            if (canUpload) ...[
              const SizedBox(height: 28),
              AppButton.primary(
                label: 'Upload Timetable',
                onTap: () => context.push('/timetable/upload'),
                icon: Icons.upload_file_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }
}