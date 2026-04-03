import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../data/models/chat/message_model.dart';
import '../../../presentation/common/widgets/app_app_bar.dart';
import '../../../presentation/common/widgets/app_error_state.dart';
import '../../../presentation/common/widgets/app_loading.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.conversation,
  });

  final String conversationId;
  final ConversationModel? conversation;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Mark messages as read when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRoomProvider(widget.conversationId).notifier).markAllRead();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // With reverse: true, maxScrollExtent = top of chat (oldest messages)
    final nearTop = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200;
    if (nearTop && !_isLoadingMore) {
      setState(() => _isLoadingMore = true);
      ref
          .read(chatRoomProvider(widget.conversationId).notifier)
          .loadMore()
          .then((_) {
        if (mounted) setState(() => _isLoadingMore = false);
      });
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return true;
    return _scrollController.position.pixels < 200;
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, // 0 = bottom in reversed list
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String get _title {
    return widget.conversation?.displayName ?? 'Chat';
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatRoomProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';

    // Auto-scroll when new message arrives
    ref.listen(chatRoomProvider(widget.conversationId), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount > prevCount && _isNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.white, size: AppDimensions.iconMD),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _ChatAppBarTitle(
          title: _title,
          conversation: widget.conversation,
          isConnected: chatAsync.valueOrNull?.isConnected ?? false,
        ),
        actions: [
          chatAsync.whenOrNull(
            data: (state) => state.isConnected
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: AppColors.white),
                    onPressed: () => ref
                        .read(chatRoomProvider(widget.conversationId)
                            .notifier)
                        .reconnect(),
                    tooltip: 'Reconnect',
                  ),
          ) ??
              const SizedBox.shrink(),
          const SizedBox(width: AppDimensions.space4),
        ],
      ),
      body: chatAsync.when(
        loading: () => AppLoading.listView(count: 10, withAvatar: true),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(chatRoomProvider(widget.conversationId)),
        ),
        data: (state) {
          return Column(
            children: [
              // Loading older messages indicator
              if (state.isLoadingMore)
                const LinearProgressIndicator(
                  color: AppColors.navyMedium,
                  backgroundColor: AppColors.surface100,
                  minHeight: 2,
                ),
              // Error banner
              if (state.error != null) _ErrorBanner(message: state.error!),
              // Messages list
              Expanded(
                child: state.messages.isEmpty
                    ? _EmptyChat(conversationName: _title)
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // newest at bottom
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.space8,
                        ),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final previousMessage =
                              index < state.messages.length - 1
                                  ? state.messages[index + 1]
                                  : null;

                          // Day separator: check if date changed between messages
                          // In reversed list, index+1 is the OLDER message
                          final showDateSep =
                              previousMessage != null &&
                                  !_isSameDay(
                                      message.sentAt,
                                      previousMessage.sentAt);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDateSep)
                                DateSeparator(date: message.sentAt),
                              MessageBubble(
                                message: message,
                                isMine: message.isMine(currentUserId),
                                previousMessage: previousMessage,
                              ),
                            ],
                          );
                        },
                      ),
              ),
              // Input bar
              MessageInputBar(
                isConnected: state.isConnected,
                isSending: state.isSending,
                onSendText: (text) => ref
                    .read(chatRoomProvider(widget.conversationId).notifier)
                    .sendText(text),
                onSendFile: ({
                  required filePath,
                  required fileName,
                  required messageType,
                }) =>
                    ref
                        .read(chatRoomProvider(widget.conversationId)
                            .notifier)
                        .sendFile(
                          filePath: filePath,
                          fileName: fileName,
                          messageType: messageType,
                        ),
                onRetryConnect: () => ref
                    .read(chatRoomProvider(widget.conversationId).notifier)
                    .reconnect(),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ChatAppBarTitle extends StatelessWidget {
  const _ChatAppBarTitle({
    required this.title,
    required this.conversation,
    required this.isConnected,
  });

  final String title;
  final ConversationModel? conversation;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        if (conversation != null)
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: conversation!.avatarColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                conversation!.type.icon,
                color: AppColors.white,
                size: AppDimensions.iconSM,
              ),
            ),
          ),
        if (conversation != null)
          const SizedBox(width: AppDimensions.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.titleLargeOnDark.copyWith(fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? AppColors.successGreen
                          : AppColors.grey400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space4),
                  Text(
                    isConnected ? 'Connected' : 'Connecting…',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.conversationName});
  final String conversationName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.navyLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppColors.navyLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            Text(
              'Start the conversation',
              style: AppTypography.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space8),
            Text(
              'Send your first message to $conversationName.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space8,
      ),
      color: AppColors.errorLight,
      child: Text(
        message,
        style: AppTypography.labelSmall.copyWith(color: AppColors.errorDark),
        textAlign: TextAlign.center,
      ),
    );
  }
}