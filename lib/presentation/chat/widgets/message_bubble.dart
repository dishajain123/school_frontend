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
  });

  final MessageModel message;
  final bool isMine;
  final bool showSenderLabel;
  final MessageModel? previousMessage;

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
        left: isMine ? 64 : AppDimensions.space16,
        right: isMine ? AppDimensions.space16 : 64,
        top: _isSameMinute ? 2 : AppDimensions.space8,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BubbleBody(message: message, isMine: isMine),
          if (!_isSameMinute)
            Padding(
              padding: const EdgeInsets.only(
                top: AppDimensions.space4,
                left: AppDimensions.space4,
                right: AppDimensions.space4,
              ),
              child: Text(
                DateFormatter.formatTime(message.sentAt),
                style: AppTypography.caption.copyWith(fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _BubbleBody extends StatelessWidget {
  const _BubbleBody({required this.message, required this.isMine});
  final MessageModel message;
  final bool isMine;

  Color get _bgColor =>
      isMine ? AppColors.navyMedium : AppColors.white;

  Color get _textColor => isMine ? AppColors.white : AppColors.grey800;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.72,
      ),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(AppDimensions.radiusMedium),
          topRight: const Radius.circular(AppDimensions.radiusMedium),
          bottomLeft: Radius.circular(
              isMine ? AppDimensions.radiusMedium : AppDimensions.space4),
          bottomRight: Radius.circular(
              isMine ? AppDimensions.space4 : AppDimensions.radiusMedium),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: AppDimensions.space8,
      ),
      child: _buildContent(),
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
      style: AppTypography.bodyMedium.copyWith(color: _textColor, height: 1.4),
    );
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
        Icon(Icons.attach_file_rounded,
            size: AppDimensions.iconSM, color: textColor),
        const SizedBox(width: AppDimensions.space8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content?.isNotEmpty == true
                    ? message.content!
                    : 'Attachment',
                style: AppTypography.labelMedium.copyWith(color: textColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Tap to download',
                style: AppTypography.caption.copyWith(
                  color: textColor.withValues(alpha: 0.7),
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
        Icon(Icons.image_outlined,
            size: AppDimensions.iconSM, color: textColor),
        const SizedBox(width: AppDimensions.space8),
        Text(
          'Image',
          style: AppTypography.labelMedium.copyWith(color: textColor),
        ),
      ],
    );
  }
}

/// Shows a date separator between messages from different days.
class DateSeparator extends StatelessWidget {
  const DateSeparator({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.surface200, thickness: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space4,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                DateFormatter.formatDate(date),
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Divider(color: AppColors.surface200, thickness: 1),
          ),
        ],
      ),
    );
  }
}