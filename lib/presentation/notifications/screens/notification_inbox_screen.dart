import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
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
    extends ConsumerState<NotificationInboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(notificationNotifierProvider.notifier)
          .loadInbox(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          TextButton(
            onPressed: () {
              ref
                  .read(notificationNotifierProvider.notifier)
                  .markAllRead();
            },
            child: Text(
              'Mark all read',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.goldPrimary,
              ),
            ),
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => AppLoading.listView(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref
              .read(notificationNotifierProvider.notifier)
              .loadInbox(refresh: true),
        ),
        data: (notifState) => Column(
          children: [
            NotificationFilterBar(
              selectedType: notifState.typeFilter,
              selectedRead: notifState.isReadFilter,
              onFilterChanged: (type, isRead) {
                ref
                    .read(notificationNotifierProvider.notifier)
                    .setFilter(
                      typeFilter: type,
                      isReadFilter: isRead,
                      clearType: type == null,
                      clearRead: isRead == null,
                    );
              },
            ),
            Expanded(
              child: notifState.isLoading
                  ? AppLoading.listView()
                  : notifState.error != null && notifState.items.isEmpty
                      ? AppErrorState(
                          message: notifState.error,
                          onRetry: () => ref
                              .read(notificationNotifierProvider.notifier)
                              .loadInbox(refresh: true),
                        )
                      : notifState.items.isEmpty
                          ? const AppEmptyState(
                              title: 'No notifications',
                              subtitle:
                                  'You\'re all caught up! Notifications will appear here.',
                              icon: Icons.notifications_none_outlined,
                            )
                          : RefreshIndicator(
                              onRefresh: () => ref
                                  .read(notificationNotifierProvider.notifier)
                                  .loadInbox(refresh: true),
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                    vertical: AppDimensions.space8),
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
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space16,
              AppDimensions.space8,
            ),
            child: Text(
              headerLabel,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        NotificationTile(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              ref
                  .read(notificationNotifierProvider.notifier)
                  .markRead([notification.id]);
            }
          },
        ),
      ],
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