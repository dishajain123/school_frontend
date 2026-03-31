import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'app_badge.dart';

/// Custom [AppBar] that enforces the design system consistently across all screens.
///
/// Features:
/// - Navy deep background with white text/icons
/// - Optional back button using [GoRouter.pop]
/// - Optional subtitle below the title
/// - Notification bell with unread count badge
/// - Optional [TabBar] via [bottom]
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.showBack = false,
    this.actions = const [],
    this.subtitle,
    this.bottom,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.backgroundColor,
    this.centerTitle = false,
    this.onBackPressed,
    this.elevation = 0,
  }) : assert(
          title != null || titleWidget != null,
          'Either title or titleWidget must be provided',
        );

  /// Plain string title — mutually exclusive with [titleWidget].
  final String? title;

  /// Custom widget title — takes precedence over [title] if both provided.
  final Widget? titleWidget;

  final bool showBack;
  final List<Widget> actions;
  final String? subtitle;

  /// Optional [TabBar] pinned below the AppBar.
  final PreferredSizeWidget? bottom;

  /// When > 0, renders a badge over the notification bell icon.
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final Color? backgroundColor;
  final bool centerTitle;
  final VoidCallback? onBackPressed;
  final double elevation;

  @override
  Size get preferredSize => Size.fromHeight(
        AppDimensions.appBarHeight +
            (bottom?.preferredSize.height ?? 0) +
            (subtitle != null ? 18 : 0),
      );

  @override
  Widget build(BuildContext context) {
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
              style: AppTypography.titleLargeOnDark.copyWith(fontSize: 18),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        );

    final effectiveActions = <Widget>[
      ...actions,
      if (onNotificationTap != null)
        _NotificationBell(
          count: notificationCount,
          onTap: onNotificationTap!,
        ),
      const SizedBox(width: AppDimensions.space4),
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
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.white,
                size: AppDimensions.iconMD,
              ),
              tooltip: 'Back',
              onPressed: onBackPressed ??
                  () {
                    if (context.canPop()) context.pop();
                  },
            )
          : null,
      title: effectiveTitle,
      actions: effectiveActions,
      bottom: bottom,
      toolbarHeight: AppDimensions.appBarHeight +
          (subtitle != null ? 18 : 0),
    );
  }
}

/// Notification bell icon with optional badge overlay.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      icon: AppBadge(
        count: count,
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.white,
          size: AppDimensions.iconMD,
        ),
      ),
      onPressed: onTap,
    );
  }
}