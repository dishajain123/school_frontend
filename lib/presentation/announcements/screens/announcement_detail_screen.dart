import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_outlined,
                          color: AppColors.white, size: 16),
                    ),
                    onPressed: () => context.push(
                      RouteNames.createAnnouncement,
                      extra: announcement,
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnnouncementHero(announcement: announcement, color: color),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BodyCard(announcement: announcement),
                  if (announcement.attachmentUrl != null) ...[
                    const SizedBox(height: 16),
                    AppButton.secondary(
                      label: 'Download Attachment',
                      onTap: () {
                        _showAttachmentDialog(
                          context,
                          announcement.attachmentUrl!,
                        );
                      },
                      icon: Icons.download_outlined,
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementHero extends StatelessWidget {
  const _AnnouncementHero({
    required this.announcement,
    required this.color,
  });

  final AnnouncementModel announcement;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navyDeep, AppColors.navyMedium],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(announcement.type.icon, size: 12, color: color),
                    const SizedBox(width: 5),
                    Text(
                      announcement.type.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (announcement.targetRole != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'For: ${announcement.targetRole}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(
            announcement.title,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: 13,
                    color: AppColors.white.withValues(alpha: 0.6),
                  ),
              const SizedBox(width: 5),
              Text(
                DateFormatter.formatDateTime(announcement.publishedAt),
                style: AppTypography.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              if (announcement.attachmentUrl != null) ...[
                const SizedBox(width: 12),
                    Icon(
                      Icons.attach_file_rounded,
                      size: 13,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                const SizedBox(width: 4),
                Text(
                  'Has attachment',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _BodyCard extends StatelessWidget {
  const _BodyCard({required this.announcement});
  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Text(
        announcement.body,
        style: AppTypography.bodyLarge.copyWith(
          height: 1.75,
          color: AppColors.grey700,
          fontSize: 15,
        ),
      ),
    );
  }
}

void _showAttachmentDialog(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Attachment Link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Copy this link and open it in your browser to download the attachment:',
          ),
          const SizedBox(height: 8),
          SelectableText(
            url,
            style: AppTypography.bodySmall.copyWith(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
