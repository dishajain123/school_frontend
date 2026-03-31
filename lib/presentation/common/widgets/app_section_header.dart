import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Bold section label row with an optional "See all" / action link.
///
/// Used inside scrollable screens to visually separate content sections:
/// ```dart
/// AppSectionHeader(
///   title: 'Recent Announcements',
///   actionLabel: 'See all',
///   onAction: () => context.push(RouteNames.announcements),
/// )
/// ```
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.padding,
    this.showAccent = false,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsetsGeometry? padding;

  /// When true, adds a gold left-border accent strip to the title.
  final bool showAccent;

  /// Completely custom trailing widget (overrides [actionLabel]).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    Widget titleContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: AppTypography.headlineSmall,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppDimensions.space2),
          Text(
            subtitle!,
            style: AppTypography.bodySmall,
          ),
        ],
      ],
    );

    if (showAccent) {
      titleContent = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Expanded(child: titleContent),
          ],
        ),
      );
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: titleContent),
          if (trailing != null)
            trailing!
          else if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: AppDimensions.space8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.navyMedium,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: AppDimensions.iconXS - 2,
                      color: AppColors.navyMedium,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}