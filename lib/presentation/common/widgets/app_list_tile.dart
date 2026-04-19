import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Consistent list row following the design system spec.
///
/// - 64px min height (72px with subtitle)
/// - Leading: any widget (AppAvatar, icon container, etc.)
/// - Trailing: any widget (chevron, status chip, etc.)
/// - InkWell ripple on tap
/// - Optional divider below (hidden when [isLast] is true)
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.isLast = false,
    this.dense = false,
    this.enabled = true,
    this.padding,
    this.titleStyle,
    this.subtitleStyle,
    this.showDivider = true,
    this.dividerIndent,
    this.borderRadius,
    this.backgroundColor,
    this.contentPadding,
  });

  /// Usually [AppAvatar] or a 40px icon container.
  final Widget? leading;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When true, the bottom divider is hidden.
  final bool isLast;

  /// Dense mode: 56px height, slightly smaller text.
  final bool dense;
  final bool enabled;

  /// Outer padding around the tile.
  final EdgeInsetsGeometry? padding;

  final dynamic titleStyle;
  final dynamic subtitleStyle;
  final bool showDivider;

  /// Left indent for the divider line (defaults to 56px).
  final double? dividerIndent;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? contentPadding;

  double get _minHeight =>
      dense ? AppDimensions.listTileDenseHeight : AppDimensions.listTileHeight;

  @override
  Widget build(BuildContext context) {
    final tile = Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        onLongPress: enabled ? onLongPress : null,
        borderRadius: borderRadius,
        splashColor: AppColors.navyLight.withValues(alpha: 0.06),
        highlightColor: AppColors.surface50,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: contentPadding ??
                EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: dense
                      ? AppDimensions.space8
                      : AppDimensions.space12,
                ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppDimensions.space12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: titleStyle ??
                            (dense
                                ? AppTypography.titleSmall
                                : AppTypography.titleMedium)
                                .copyWith(
                              color: enabled
                                  ? AppColors.grey800
                                  : AppColors.grey400,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppDimensions.space4),
                        Text(
                          subtitle!,
                          style: subtitleStyle ??
                              AppTypography.bodySmall.copyWith(
                                color: enabled
                                    ? AppColors.grey600
                                    : AppColors.grey400,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppDimensions.space8),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (showDivider && !isLast) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          Divider(
            height: 1,
            thickness: AppDimensions.borderThin,
            color: AppColors.surface100,
            indent: dividerIndent ?? AppDimensions.listTileDividerIndent,
            endIndent: 0,
          ),
        ],
      );
    }

    return tile;
  }
}
