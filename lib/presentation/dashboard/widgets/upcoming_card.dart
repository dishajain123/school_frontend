import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface100),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.event_available_outlined,
              size: 32,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 8),
            Text(
              'Nothing upcoming',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey400,
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space12),
        itemBuilder: (context, i) => _UpcomingItemCard(item: items[i]),
      ),
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
        width: 156,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.surface100,
            width: 1,
          ),
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
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon ?? Icons.event_outlined,
                    size: 14,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    item.dateLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey500,
                  ),
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
