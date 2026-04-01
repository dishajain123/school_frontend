import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class UpcomingItem {
  const UpcomingItem({
    required this.title,
    required this.subtitle,
    required this.dateLabel,
    this.color,
    this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String dateLabel;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;
}

/// Horizontal scroll row of upcoming event cards.
class UpcomingCard extends StatelessWidget {
  const UpcomingCard({
    super.key,
    required this.title,
    required this.items,
    this.onSeeAll,
  });

  final String title;
  final List<UpcomingItem> items;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTypography.headlineSmall),
            if (onSeeAll != null)
              GestureDetector(
                onTap: onSeeAll,
                child: Text('See all',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.navyMedium,
                      fontWeight: FontWeight.w600,
                    )),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.space12),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: AppDecorations.cardFlat,
            child: Text(
              'Nothing upcoming',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey400,
              ),
              textAlign: TextAlign.center,
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimensions.space12),
              itemBuilder: (context, i) =>
                  _UpcomingItemCard(item: items[i]),
            ),
          ),
      ],
    );
  }
}

class _UpcomingItemCard extends StatelessWidget {
  const _UpcomingItemCard({required this.item});
  final UpcomingItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.color ?? AppColors.navyMedium;

    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusMedium),
          boxShadow: AppDecorations.shadow1,
          border: Border.all(
              color: AppColors.surface200, width: AppDimensions.borderThin),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: AppDecorations.quickActionContainer(color),
                  child: Icon(
                    item.icon ?? Icons.event_outlined,
                    size: 14,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space6,
                      vertical: AppDimensions.space2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    item.dateLabel,
                    style: AppTypography.labelSmall.copyWith(
                        color: color, fontWeight: FontWeight.w600,
                        fontSize: 9),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.space2),
                Text(
                  item.subtitle,
                  style: AppTypography.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
