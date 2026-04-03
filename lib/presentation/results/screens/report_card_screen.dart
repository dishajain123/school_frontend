import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/result_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

class ReportCardScreen extends ConsumerWidget {
  const ReportCardScreen({
    super.key,
    required this.studentId,
    required this.examId,
  });

  final String studentId;
  final String examId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (studentId: studentId, examId: examId);
    final reportAsync = ref.watch(reportCardProvider(params));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Report Card',
        showBack: true,
      ),
      body: reportAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(reportCardProvider(params)),
        ),
        data: (reportCard) => _ReportCardContent(
          url: reportCard.url,
          onRefresh: () => ref.invalidate(reportCardProvider(params)),
        ),
      ),
    );
  }
}

class _ReportCardContent extends StatelessWidget {
  const _ReportCardContent({
    required this.url,
    required this.onRefresh,
  });

  final String url;
  final VoidCallback onRefresh;

  void _open(BuildContext context) {
    // TODO: integrate url_launcher — launchUrl(Uri.parse(url))
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening report card PDF…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // PDF preview icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusXL),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.errorRed.withValues(alpha: 0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 48,
                      color: AppColors.errorRed,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space24),
                  Text(
                    'Report Card Ready',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    'Your report card has been generated.\nTap below to open or share it.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.grey600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.space32),

                  // URL preview chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space12,
                      vertical: AppDimensions.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface100,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link_outlined,
                            size: 14, color: AppColors.grey400),
                        const SizedBox(width: AppDimensions.space6),
                        Flexible(
                          child: Text(
                            url.length > 50
                                ? '${url.substring(0, 50)}…'
                                : url,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.grey600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Bottom actions
        Container(
          color: AppColors.white,
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space20,
            AppDimensions.space12,
            AppDimensions.space20,
            AppDimensions.space24,
          ),
          child: Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  label: 'Refresh',
                  onTap: onRefresh,
                  icon: Icons.refresh_rounded,
                ),
              ),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: AppButton.primary(
                  label: 'Open PDF',
                  onTap: () => _open(context),
                  icon: Icons.open_in_new_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}