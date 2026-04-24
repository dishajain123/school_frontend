import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chat/message_model.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showSenderLabel = false,
    this.previousMessage,
    this.onDoubleTap,
  });

  final MessageModel message;
  final bool isMine;
  final bool showSenderLabel;
  final MessageModel? previousMessage;
  final VoidCallback? onDoubleTap;

  bool get _isSameMinute {
    if (previousMessage == null) return false;
    final prev = previousMessage!.sentAt;
    final curr = message.sentAt;
    return prev.year == curr.year &&
        prev.month == curr.month &&
        prev.day == curr.day &&
        prev.hour == curr.hour &&
        prev.minute == curr.minute &&
        previousMessage!.senderId == message.senderId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMine ? 56 : 12,
        right: isMine ? 12 : 56,
        top: _isSameMinute ? 2 : 10,
        bottom: 2,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _BubbleBody(
              message: message,
              isMine: isMine,
              onDoubleTap: onDoubleTap,
            ),
            if (message.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: _ReactionRow(
                  reactions: message.reactions,
                  isMine: isMine,
                  myReaction: message.myReaction,
                ),
              ),
            if (!_isSameMinute)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  DateFormatter.formatTime(message.sentAt),
                  style: AppTypography.caption.copyWith(
                    fontSize: 10,
                    color: AppColors.grey400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({
    required this.message,
    required this.isMine,
    this.onDoubleTap,
  });
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onDoubleTap;

  Color get _bgColor => isMine ? AppColors.navyMedium : AppColors.white;

  Color get _textColor => isMine ? AppColors.white : AppColors.grey800;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: isMine ? 0.15 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (message.hasFile && message.messageType == MessageType.file) {
      return _FileContent(message: message, textColor: _textColor);
    }
    if (message.hasFile && message.messageType == MessageType.image) {
      return _ImageContent(fileKey: message.fileKey!, textColor: _textColor);
    }
    return Text(
      message.content ?? '',
      style: AppTypography.bodyMedium.copyWith(
        color: _textColor,
        height: 1.45,
        fontSize: 14,
      ),
    );
  }
}

class _ReactionRow extends StatelessWidget {
  const _ReactionRow({
    required this.reactions,
    required this.isMine,
    required this.myReaction,
  });

  final List<MessageReactionSummary> reactions;
  final bool isMine;
  final String? myReaction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
      spacing: 6,
      runSpacing: 4,
      children: reactions.map((reaction) {
        final isMineReaction =
            myReaction != null && myReaction == reaction.emoji;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isMineReaction
                ? AppColors.infoBlue.withValues(alpha: 0.15)
                : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMineReaction ? AppColors.infoBlue : AppColors.surface200,
            ),
          ),
          child: Text(
            '${reaction.emoji} ${reaction.count}',
            style: AppTypography.caption.copyWith(
              color: _labelColor(reaction.emoji),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _labelColor(String emoji) {
    if (emoji == '❤️') return AppColors.errorRed;
    return AppColors.grey700;
  }
}

class _FileContent extends StatelessWidget {
  const _FileContent({required this.message, required this.textColor});
  final MessageModel message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.attach_file_rounded, size: 16, color: textColor),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content?.isNotEmpty == true
                    ? message.content!
                    : 'Attachment',
                style: AppTypography.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Tap to download',
                style: AppTypography.caption.copyWith(
                  color: textColor.withValues(alpha: 0.65),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageContent extends StatelessWidget {
  const _ImageContent({required this.fileKey, required this.textColor});
  final String fileKey;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.image_outlined, size: 16, color: textColor),
        ),
        const SizedBox(width: 10),
        Text(
          'Image',
          style: AppTypography.labelMedium.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: AppColors.surface200,
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                border: Border.all(color: AppColors.surface200),
              ),
              child: Text(
                DateFormatter.formatDate(date),
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey500,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: AppColors.surface200,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
