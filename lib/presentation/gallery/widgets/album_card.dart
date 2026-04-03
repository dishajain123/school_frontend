import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
import "../../../core/theme/app_typography.dart";
import "../../../core/utils/date_formatter.dart";
import "../../../data/models/gallery/album_model.dart";
import "../../common/widgets/app_card.dart";

class AlbumCard extends StatelessWidget {
  const AlbumCard({
    super.key,
    required this.album,
    required this.photoCount,
    this.onTap,
  });

  final AlbumModel album;
  final int photoCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _AlbumBackground(url: album.coverPhotoUrl),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x220B1F3A),
                    Color(0x990B1F3A),
                  ],
                ),
              ),
            ),
            Positioned(
              top: AppDimensions.space12,
              right: AppDimensions.space12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.photo_library_outlined,
                      size: AppDimensions.iconXS,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: AppDimensions.space4),
                    Text(
                      "$photoCount",
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: AppDimensions.space12,
              right: AppDimensions.space12,
              bottom: AppDimensions.space12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    album.eventName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.titleLargeOnDark,
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Row(
                    children: [
                      const Icon(
                        Icons.event_outlined,
                        size: AppDimensions.iconXS,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: AppDimensions.space4),
                      Text(
                        DateFormatter.formatDate(album.eventDate),
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumBackground extends StatelessWidget {
  const _AlbumBackground({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navyDeep, AppColors.navyMedium],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.photo_library_outlined,
            size: 44,
            color: AppColors.white,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppColors.surface100),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.surface100,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 40,
          color: AppColors.grey400,
        ),
      ),
    );
  }
}
