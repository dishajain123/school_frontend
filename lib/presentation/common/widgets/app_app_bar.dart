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
            (subtitle != null ? 18 : 0),
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
      if (showNotificationBell)
        IconButton(
          tooltip: 'Notifications',
          icon: AppBadge(
            count: unreadCount,
            child: const Icon(
              Icons.notifications_outlined,
              color: AppColors.white,
              size: AppDimensions.iconMD,
            ),
          ),
          onPressed: () => context.push(RouteNames.notifications),
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
      toolbarHeight:
          AppDimensions.appBarHeight + (subtitle != null ? 18 : 0),
    );
  }
}