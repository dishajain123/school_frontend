import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AttentionItem {
  const AttentionItem({
    required this.label,
    required this.icon,
    required this.color,
    this.count,
    this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final int? count;
  final VoidCallback? onTap;
}

class NeedsAttentionSection extends StatelessWidget {
  const NeedsAttentionSection({super.key, required this.items});
  final List<AttentionItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.errorRed,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Needs Attention',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.grey700,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map((item) => _AttentionTile(item: item)),
      ],
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        item.onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: item.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: item.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, size: 17, color: item.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: item.color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.count.toString(),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: item.color),
          ],
        ),
      ),
    );
  }
}