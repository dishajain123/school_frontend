import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../presentation/common/widgets/app_app_bar.dart';
import '../../../presentation/common/widgets/app_empty_state.dart';
import '../../../presentation/common/widgets/app_error_state.dart';
import '../../../presentation/common/widgets/app_loading.dart';
import '../../../presentation/common/widgets/app_scaffold.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/auth_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/new_conversation_sheet.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    _fabCtrl.forward();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  void _openChat(BuildContext context, ConversationModel conversation) {
    context.push(RouteNames.chatRoomPath(conversation.id), extra: conversation);
  }

  Future<void> _showNewConversationSheet() async {
    final result = await showModalBottomSheet<ConversationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => const NewConversationSheet(),
    );
    if (result != null && mounted) {
      _openChat(context, result);
    }
  }

  Future<void> _deleteConversation(ConversationModel conversation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete chat'),
        content: Text(
          'Delete "${conversation.displayName}" for all participants?',
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
          .deleteConversation(conversation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conversation deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete conversation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationNotifierProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canDeleteChat = currentUser != null &&
        (currentUser.role.isSchoolScopedAdmin ||
            currentUser.role == UserRole.teacher);

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Messages',
        showBack: true,
        actions: [
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
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.white, size: 18),
              ),
              tooltip: 'Refresh',
              onPressed: () =>
                  ref.read(conversationNotifierProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: GestureDetector(
          onTap: _showNewConversationSheet,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A5F), Color(0xFF0F2340)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.edit_outlined,
                color: AppColors.white, size: 22),
          ),
        ),
      ),
      body: conversationsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(conversationNotifierProvider.notifier).refresh(),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return const AppEmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'Start a conversation by tapping the compose button.',
              iconColor: AppColors.navyLight,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(conversationNotifierProvider.notifier).refresh(),
            color: AppColors.navyDeep,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: conversations.length,
              itemBuilder: (context, i) {
                final conversation = conversations[i];
                return ConversationTile(
                  conversation: conversation,
                  isLast: i == conversations.length - 1,
                  onTap: () => _openChat(context, conversation),
                  onDelete: canDeleteChat
                      ? () => _deleteConversation(conversation)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: AppLoading.card(height: 72),
      ),
    );
  }
}
