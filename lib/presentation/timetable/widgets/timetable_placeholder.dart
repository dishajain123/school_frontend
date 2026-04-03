import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';

class TimetablePlaceholder extends ConsumerWidget {
  const TimetablePlaceholder({
    super.key,
    required this.canUpload,
  });

  /// When true (PRINCIPAL), shows an "Upload Timetable" action button.
  final bool canUpload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusXL),
              ),
              child: const Icon(
                Icons.calendar_view_week_outlined,
                size: 44,
                color: AppColors.grey400,
              ),
            ),

            const SizedBox(height: AppDimensions.space24),

            Text(
              'No timetable uploaded',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppDimensions.space8),

            Text(
              canUpload
                  ? 'Upload a PDF or image timetable\nfor this class below.'
                  : 'The timetable hasn\'t been uploaded yet.\nCheck back later.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),

            if (canUpload) ...[
              const SizedBox(height: AppDimensions.space24),
              AppButton.primary(
                label: 'Upload Timetable',
                onTap: () => context.push('/timetable/upload'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
