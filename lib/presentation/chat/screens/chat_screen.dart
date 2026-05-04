import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../data/models/chat/message_model.dart';
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
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String get _title => widget.conversation?.displayName ?? 'Chat';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _showReactionPicker(MessageModel message) async {
    const emojiOptions = [
      '👍',
      '❤️',
      '😂',
      '😮',
      '😢',
      '🙏',
      '🔥',
      '👏',
      '🎉',
      '🤝',
      '✅',
      '💯',
      '😍',
      '😡',
      '😎',
      '🤔',
      '🙌',
      '🌟',
    ];
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
          child: SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: emojiOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final emoji = emojiOptions[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(emoji),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: emoji == '❤️'
                          ? AppColors.errorRed.withValues(alpha: 0.1)
                          : AppColors.surface100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emoji == '❤️'
                            ? AppColors.errorRed.withValues(alpha: 0.4)
                            : AppColors.surface200,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    await ref
        .read(chatRoomProvider(widget.conversationId).notifier)
        .reactToMessage(
          messageId: message.id,
          emoji: selected,
        );
  }

  Future<void> _deleteConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete chat'),
        content: const Text(
          'This chat will be deleted for everyone. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(conversationNotifierProvider.notifier)
          .deleteConversation(widget.conversationId);
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(RouteNames.conversations);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete conversation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatRoomProvider(widget.conversationId));
    final currentUser = ref.watch(currentUserProvider);
    final currentUserId = currentUser?.id ?? '';
    final canDeleteChat = currentUser != null &&
        (currentUser.role.isSchoolScopedAdmin ||
            currentUser.role == UserRole.teacher);
    final canReactToMessage = currentUser != null &&
        (currentUser.role == UserRole.parent ||
            currentUser.role == UserRole.student ||
            currentUser.role == UserRole.teacher ||
            currentUser.role.isSchoolScopedAdmin);

    ref.listen(chatRoomProvider(widget.conversationId), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount > prevCount && _isNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _ChatAppBar(
          title: _title,
          conversation: widget.conversation,
          isConnected: chatAsync.valueOrNull?.isConnected ?? false,
          onBack: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(RouteNames.dashboard);
            }
          },
          onReconnect: chatAsync.valueOrNull?.isConnected == false
              ? () => ref
                  .read(chatRoomProvider(widget.conversationId).notifier)
                  .reconnect()
              : null,
          showDelete: canDeleteChat,
          onDelete: canDeleteChat ? _deleteConversation : null,
        ),
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
              if (state.isLoadingMore)
                const LinearProgressIndicator(
                  color: AppColors.navyMedium,
                  backgroundColor: AppColors.surface100,
                  minHeight: 2,
                ),
              if (state.error != null) _ErrorBanner(message: state.error!),
              Expanded(
                child: state.messages.isEmpty
                    ? _EmptyChat(conversationName: _title)
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final previousMessage =
                              index < state.messages.length - 1
                                  ? state.messages[index + 1]
                                  : null;
                          final showDateSep = previousMessage != null &&
                              !_isSameDay(
                                  message.sentAt, previousMessage.sentAt);

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showDateSep)
                                DateSeparator(date: message.sentAt),
                              MessageBubble(
                                message: message,
                                isMine: message.isMine(currentUserId),
                                previousMessage: previousMessage,
                                onDoubleTap: canReactToMessage
                                    ? () => _showReactionPicker(message)
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
              ),
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
                        .read(chatRoomProvider(widget.conversationId).notifier)
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
}

class _ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatAppBar({
    required this.title,
    required this.conversation,
    required this.isConnected,
    required this.onBack,
    this.onReconnect,
    this.showDelete = false,
    this.onDelete,
  });

  final String title;
  final ConversationModel? conversation;
  final bool isConnected;
  final VoidCallback onBack;
  final VoidCallback? onReconnect;
  final bool showDelete;
  final VoidCallback? onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onBack,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: AppColors.white, size: 16),
                  ),
                ),
                const SizedBox(width: 12),
                if (conversation != null) ...[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: conversation!.avatarColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      conversation!.type.icon,
                      color: AppColors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleLargeOnDark.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isConnected
                                  ? AppColors.successGreen
                                  : AppColors.warningAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isConnected ? 'Connected' : 'Connecting…',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.white.withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (onReconnect != null)
                  GestureDetector(
                    onTap: onReconnect,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.refresh_rounded,
                          color: AppColors.white, size: 18),
                    ),
                  ),
                if (showDelete && onDelete != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_outline_rounded,
                          color: AppColors.white, size: 18),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 34,
                color: AppColors.navyMedium,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start the conversation',
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first message to $conversationName.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey500,
                height: 1.5,
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.errorLight,
      child: Text(
        message,
        style: AppTypography.labelSmall.copyWith(color: AppColors.errorDark),
        textAlign: TextAlign.center,
      ),
    );
  }
}
