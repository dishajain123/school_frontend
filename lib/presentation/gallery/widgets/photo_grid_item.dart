import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
import "../../../core/theme/app_typography.dart";
import "../../../data/models/gallery/photo_model.dart";

class PhotoGridItem extends StatelessWidget {
  const PhotoGridItem({
    super.key,
    required this.photo,
    this.onTap,
    this.onLongPress,
    this.canToggleFeature = false,
  });

  final PhotoModel photo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool canToggleFeature;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: photo.photoUrl ?? "",
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surface100),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surface100,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: AppDimensions.iconLG,
                    color: AppColors.grey400,
                  ),
                ),
              ),
              if (photo.isFeatured)
                Positioned(
                  top: AppDimensions.space8,
                  left: AppDimensions.space8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space6,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: AppDimensions.iconXS,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: AppDimensions.space2),
                        Text(
                          "Featured",
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (canToggleFeature)
                Positioned(
                  right: AppDimensions.space8,
                  bottom: AppDimensions.space8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space6,
                      vertical: AppDimensions.space4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.45),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusSmall),
                    ),
                    child: Text(
                      "Hold to feature",
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
