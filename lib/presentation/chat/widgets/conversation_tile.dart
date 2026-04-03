import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chat/conversation_model.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.isLast = false,
  });

  final ConversationModel conversation;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.navyLight.withValues(alpha: 0.06),
        highlightColor: AppColors.surface50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space12,
              ),
              child: Row(
                children: [
                  // Avatar
                  _ConversationAvatar(conversation: conversation),
                  const SizedBox(width: AppDimensions.space12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                conversation.displayName,
                                style: AppTypography.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space8),
                            Text(
                              DateFormatter.formatRelative(
                                  conversation.updatedAt),
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.space4),
                        Row(
                          children: [
                            _TypeBadge(type: conversation.type),
                            const SizedBox(width: AppDimensions.space8),
                            Expanded(
                              child: Text(
                                'Tap to open conversation',
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: AppDimensions.iconSM,
                    color: AppColors.grey400,
                  ),
                ],
              ),
            ),
            if (!isLast)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.surface100,
                indent: AppDimensions.space16 + 40 + AppDimensions.space12,
                endIndent: 0,
              ),
          ],
        ),
      ),
    );
  }
}

class _ConversationAvatar extends StatelessWidget {
  const _ConversationAvatar({required this.conversation});
  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppDimensions.avatarMd,
      height: AppDimensions.avatarMd,
      decoration: BoxDecoration(
        color: conversation.avatarColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          conversation.type.icon,
          color: AppColors.white,
          size: AppDimensions.iconSM,
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type});
  final ConversationType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: type == ConversationType.group
            ? AppColors.infoLight
            : AppColors.navyLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        type == ConversationType.group ? 'Group' : 'DM',
        style: AppTypography.labelSmall.copyWith(
          fontSize: 9,
          color: type == ConversationType.group
              ? AppColors.infoDark
              : AppColors.navyMedium,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}