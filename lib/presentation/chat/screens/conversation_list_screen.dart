import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../presentation/common/widgets/app_app_bar.dart';
import '../../../presentation/common/widgets/app_empty_state.dart';
import '../../../presentation/common/widgets/app_error_state.dart';
import '../../../presentation/common/widgets/app_loading.dart';
import '../../../presentation/common/widgets/app_scaffold.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/new_conversation_sheet.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationNotifierProvider);

    return AppScaffold(
      appBar: AppAppBar(
        title: 'Messages',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.read(conversationNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationSheet(context, ref),
        tooltip: 'New conversation',
        child: const Icon(Icons.edit_outlined),
      ),
      body: conversationsAsync.when(
        loading: () => AppLoading.listView(count: 8),
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
              subtitle:
                  'Start a conversation by tapping the compose button.',
              iconColor: AppColors.navyLight,
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(conversationNotifierProvider.notifier).refresh(),
            color: AppColors.navyDeep,
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, i) {
                final conversation = conversations[i];
                return ConversationTile(
                  conversation: conversation,
                  isLast: i == conversations.length - 1,
                  onTap: () => _openChat(context, conversation),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _openChat(BuildContext context, ConversationModel conversation) {
    context.push(
      RouteNames.chatRoomPath(conversation.id),
      extra: conversation,
    );
  }

  Future<void> _showNewConversationSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showModalBottomSheet<ConversationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: const NewConversationSheet(),
      ),
    );

    if (result != null && context.mounted) {
      _openChat(context, result);
    }
  }
}