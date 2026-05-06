import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/notification/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/notification_filter_bar.dart';
import '../widgets/notification_tile.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadInbox(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(notificationNotifierProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(notificationNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Notifications',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: () =>
                  ref.read(notificationNotifierProvider.notifier).markAllRead(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                ),
                backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.1),
              ),
              child: Text(
                'Mark all read',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.goldPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref
              .read(notificationNotifierProvider.notifier)
              .loadInbox(refresh: true),
        ),
        data: (notifState) => FadeTransition(
          opacity: _fade,
          child: Column(
            children: [
              NotificationFilterBar(
                selectedType: notifState.typeFilter,
                selectedRead: notifState.isReadFilter,
                onFilterChanged: (type, isRead) {
                  ref.read(notificationNotifierProvider.notifier).setFilter(
                        typeFilter: type,
                        isReadFilter: isRead,
                        clearType: type == null,
                        clearRead: isRead == null,
                      );
                },
              ),
              if (notifState.items.isNotEmpty)
                _UnreadBadgeRow(
                  unreadCount: notifState.items
                      .where((n) => !n.isRead)
                      .length,
                ),
              Container(height: 1, color: AppColors.surface100),
              Expanded(
                child: notifState.isLoading
                    ? _buildShimmer()
                    : notifState.error != null && notifState.items.isEmpty
                        ? AppErrorState(
                            message: notifState.error,
                            onRetry: () => ref
                                .read(notificationNotifierProvider.notifier)
                                .loadInbox(refresh: true),
                          )
                        : notifState.items.isEmpty
                            ? const AppEmptyState(
                                title: 'All caught up!',
                                subtitle:
                                    "You're all caught up! Notifications will appear here.",
                                icon: Icons.notifications_none_outlined,
                              )
                            : RefreshIndicator(
                                onRefresh: () => ref
                                    .read(notificationNotifierProvider.notifier)
                                    .loadInbox(refresh: true),
                                color: AppColors.navyDeep,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(
                                      top: 8, bottom: 40),
                                  itemCount: notifState.items.length +
                                      (notifState.isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == notifState.items.length) {
                                      return AppLoading.paginating();
                                    }
                                    final notification =
                                        notifState.items[index];
                                    return _buildWithDateHeader(
                                      notifState.items,
                                      index,
                                      notification,
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWithDateHeader(
    List<NotificationModel> items,
    int index,
    NotificationModel notification,
  ) {
    bool showHeader = false;
    String headerLabel = '';

    if (index == 0) {
      showHeader = true;
      headerLabel = _getDateLabel(notification.createdAt);
    } else {
      final prev = items[index - 1];
      final prevLabel = _getDateLabel(prev.createdAt);
      final currLabel = _getDateLabel(notification.createdAt);
      if (prevLabel != currLabel) {
        showHeader = true;
        headerLabel = currLabel;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _DateHeaderLabel(label: headerLabel),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: NotificationTile(
            notification: notification,
            onTap: () async {
              if (!notification.isRead) {
                await ref
                    .read(notificationNotifierProvider.notifier)
                    .markRead([notification.id]);
              }

              if (!mounted) return;

              // Navigate to related content based on notification type
              if (notification.type == NotificationType.announcement &&
                  notification.referenceId != null) {
                context.go(
                  RouteNames.announcementDetailPath(notification.referenceId!),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 80),
      ),
    );
  }

  String _getDateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return DateFormatter.formatDate(dt);
  }
}

class _DateHeaderLabel extends StatelessWidget {
  const _DateHeaderLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey500,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: AppColors.surface200,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnreadBadgeRow extends StatelessWidget {
  const _UnreadBadgeRow({required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (unreadCount == 0) return const SizedBox.shrink();
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$unreadCount unread',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
