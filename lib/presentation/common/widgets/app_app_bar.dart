import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/notification_provider.dart';
import 'app_badge.dart';

class AppAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBack = false,
    this.actions = const [],
    this.subtitle,
    this.bottom,
    this.showNotificationBell = true,
    this.backgroundColor,
    this.centerTitle = false,
    this.onBackPressed,
    this.elevation = 0,
  }) : assert(
          title != null || titleWidget != null,
          'Either title or titleWidget must be provided',
        );

  final String? title;
  final Widget? titleWidget;
  final bool showBack;
  final List<Widget> actions;
  final String? subtitle;
  final PreferredSizeWidget? bottom;
  final bool showNotificationBell;
  final Color? backgroundColor;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final double elevation;

  @override
  Size get preferredSize => Size.fromHeight(
        AppDimensions.appBarHeight +
            (bottom?.preferredSize.height ?? 0) +
            (subtitle != null ? 20 : 0),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    final effectiveTitle = titleWidget ??
        Column(
          crossAxisAlignment: centerTitle
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title!,
              style: AppTypography.titleLargeOnDark.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.65),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

    final effectiveActions = <Widget>[
      ...actions,
      if (showNotificationBell)
        _NotificationButton(unreadCount: unreadCount),
      const SizedBox(width: 4),
    ];

    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.navyDeep,
      foregroundColor: AppColors.white,
      elevation: elevation,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      leading: showBack
          ? _BackButton(
              onPressed: onBackPressed ??
                  () {
                    if (context.canPop()) {
                      context.pop();
                      return;
                    }
                    context.go(RouteNames.dashboard);
                  },
            )
          : null,
      title: effectiveTitle,
      actions: effectiveActions,
      bottom: bottom,
      toolbarHeight: AppDimensions.appBarHeight + (subtitle != null ? 20 : 0),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 16,
          ),
        ),
        tooltip: 'Back',
        onPressed: onPressed,
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.unreadCount});
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        tooltip: 'Notifications',
        icon: AppBadge(
          count: unreadCount,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: 18,
            ),
          ),
        ),
        onPressed: () => context.push(RouteNames.notifications),
      ),
    );
  }
}