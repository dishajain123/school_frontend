import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/announcement/announcement_model.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';

class AnnouncementDetailScreen extends ConsumerWidget {
  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  final AnnouncementModel announcement;

  bool _canEdit(CurrentUser? user) {
    if (user == null) return false;
    return user.hasPermission('announcement:create');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final color = announcement.type.color;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Announcement',
        showBack: true,
        actions: _canEdit(user)
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(
                    RouteNames.createAnnouncement,
                    extra: announcement,
                  ),
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space6,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(announcement.type.icon, size: 14, color: color),
                  const SizedBox(width: AppDimensions.space4),
                  Text(
                    announcement.type.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.space16),

            // Title
            Text(announcement.title, style: AppTypography.headlineMedium),
            const SizedBox(height: AppDimensions.space8),

            // Date
            Text(
              DateFormatter.formatDateTime(announcement.publishedAt),
              style: AppTypography.caption,
            ),

            if (announcement.targetRole != null ||
                announcement.targetStandardId != null) ...[
              const SizedBox(height: AppDimensions.space8),
              Wrap(
                spacing: AppDimensions.space8,
                children: [
                  if (announcement.targetRole != null)
                    _Badge(
                      label: 'For: ${announcement.targetRole}',
                      color: AppColors.navyMedium,
                    ),
                ],
              ),
            ],

            const SizedBox(height: AppDimensions.space24),
            const Divider(color: AppColors.surface200),
            const SizedBox(height: AppDimensions.space24),

            // Body
            Text(
              announcement.body,
              style: AppTypography.bodyLarge.copyWith(height: 1.7),
            ),

            // Attachment
            if (announcement.attachmentUrl != null) ...[
              const SizedBox(height: AppDimensions.space32),
              AppButton.secondary(
                label: 'Download Attachment',
                onTap: () async {
                  final uri = Uri.parse(announcement.attachmentUrl!);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: Icons.download_outlined,
              ),
            ],

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space8,
        vertical: AppDimensions.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}