import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_typography.dart";
import "../../../data/models/gallery/photo_model.dart";
import "../../../providers/gallery_provider.dart";

class PhotoGridItem extends ConsumerStatefulWidget {
  const PhotoGridItem({
    super.key,
    required this.photo,
    this.onTap,
    this.onFeatureTap,
    this.canToggleFeature = false,
    this.canInteract = false,
  });

  final PhotoModel photo;
  final VoidCallback? onTap;
  final VoidCallback? onFeatureTap;
  final bool canToggleFeature;
  final bool canInteract;

  @override
  ConsumerState<PhotoGridItem> createState() => _PhotoGridItemState();
}

class _PhotoGridItemState extends ConsumerState<PhotoGridItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interactionState = ref.watch(photoInteractionProvider(widget.photo.id));

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.photo.photoUrl ?? "",
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surface100,
                    child: const Center(
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surface100,
                    child: const Icon(Icons.broken_image_outlined,
                        size: 28, color: AppColors.grey400),
                  ),
                ),
                if (widget.photo.isFeatured) ...[
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.goldPrimary.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: GestureDetector(
                      onTap: widget.canToggleFeature ? widget.onFeatureTap : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.goldPrimary.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                size: 10, color: AppColors.white),
                            const SizedBox(width: 3),
                            Text(
                              "Featured",
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                if (widget.canToggleFeature && !widget.photo.isFeatured)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: widget.onFeatureTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.photo.isFeatured
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 10,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                "Set",
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 6,
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: !widget.canInteract || interactionState.isSubmitting
                              ? null
                              : () {
                                  ref
                                      .read(photoInteractionProvider(widget.photo.id)
                                          .notifier)
                                      .toggleReaction();
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                interactionState.hasReacted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 13,
                                color: interactionState.hasReacted
                                    ? AppColors.errorRed
                                    : AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${interactionState.reactionsCount}',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.mode_comment_outlined,
                              size: 13,
                              color: AppColors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${interactionState.totalComments}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
