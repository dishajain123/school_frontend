import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
import "../../../core/theme/app_typography.dart";
import "../../../core/utils/date_formatter.dart";
import "../../../core/utils/snackbar_utils.dart";
import "../../../data/models/gallery/album_model.dart";
import "../../../data/models/gallery/photo_model.dart";
import "../../../providers/gallery_provider.dart";
import "../../common/widgets/app_app_bar.dart";
import "../../common/widgets/app_empty_state.dart";
import "../../common/widgets/app_error_state.dart";
import "../../common/widgets/app_loading.dart";
import "../../common/widgets/app_scaffold.dart";
import "../widgets/photo_grid_item.dart";

class AlbumDetailScreen extends ConsumerStatefulWidget {
  const AlbumDetailScreen({
    super.key,
    required this.albumId,
    this.initialAlbum,
  });

  final String albumId;
  final AlbumModel? initialAlbum;

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryAlbumListNotifierProvider.notifier).load();
      ref.read(albumPhotoListProvider(widget.albumId).notifier).load();
    });
  }

  Future<void> _uploadSinglePhoto() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    final caption = await _askCaption();
    if (caption == "__cancel__") return;

    final success = await ref
        .read(albumPhotoListProvider(widget.albumId).notifier)
        .uploadPhoto(
          file: File(image.path),
          caption: caption,
        );

    if (!mounted) return;
    if (success) {
      SnackbarUtils.showSuccess(context, "Photo uploaded successfully");
    } else {
      final error = ref.read(albumPhotoListProvider(widget.albumId)).error;
      SnackbarUtils.showError(
        context,
        error ?? "Photo upload failed",
      );
    }
  }

  Future<void> _uploadMultiplePhotos() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isEmpty) return;

    int uploadedCount = 0;
    for (final image in images) {
      final success = await ref
          .read(albumPhotoListProvider(widget.albumId).notifier)
          .uploadPhoto(file: File(image.path));
      if (success) uploadedCount += 1;
    }

    if (!mounted) return;
    if (uploadedCount == images.length) {
      SnackbarUtils.showSuccess(context, "${images.length} photos uploaded");
    } else {
      SnackbarUtils.showInfo(
        context,
        "$uploadedCount of ${images.length} photos uploaded",
      );
    }
  }

  Future<String?> _askCaption() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add caption"),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: "Optional photo caption",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop("__cancel__"),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Skip"),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _showUploadChoice() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: const Text("Upload single photo"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadSinglePhoto();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.collections_outlined),
                  title: const Text("Upload multiple photos"),
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadMultiplePhotos();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFeature(String photoId) async {
    final updated = await ref
        .read(albumPhotoListProvider(widget.albumId).notifier)
        .toggleFeature(photoId);
    if (!mounted || updated == null) return;

    SnackbarUtils.showSuccess(
      context,
      updated.isFeatured ? "Photo marked as featured" : "Photo unfeatured",
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(albumPhotoListProvider(widget.albumId));
    final canManage = ref.watch(galleryCanManageProvider);
    final album = ref.watch(galleryAlbumByIdProvider(widget.albumId)) ??
        widget.initialAlbum;

    return AppScaffold(
      appBar: AppAppBar(
        title: album?.eventName ?? "Album",
        showBack: true,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: _showUploadChoice,
              tooltip: "Upload Photos",
              backgroundColor: AppColors.goldPrimary,
              child: const Icon(Icons.add_a_photo_outlined),
            )
          : null,
      body: Stack(
        children: [
          if (photosState.isLoading && photosState.items.isEmpty)
            AppLoading.grid(count: 8)
          else if (photosState.error != null && photosState.items.isEmpty)
            AppErrorState(
              message: photosState.error,
              onRetry: () => ref
                  .read(albumPhotoListProvider(widget.albumId).notifier)
                  .load(),
            )
          else
            RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () async {
                await ref
                    .read(albumPhotoListProvider(widget.albumId).notifier)
                    .load();
                await ref
                    .read(galleryAlbumListNotifierProvider.notifier)
                    .refresh();
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _AlbumHeader(album: album),
                  ),
                  if (photosState.items.isEmpty)
                    SliverFillRemaining(
                      child: AppEmptyState(
                        title: "No photos yet",
                        subtitle: canManage
                            ? "Upload event photos to build this album."
                            : "Photos will appear here once uploaded.",
                        icon: Icons.photo_library_outlined,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.space16,
                        AppDimensions.space8,
                        AppDimensions.space16,
                        AppDimensions.pageBottomScroll,
                      ),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: AppDimensions.space8,
                          mainAxisSpacing: AppDimensions.space8,
                          childAspectRatio: 1,
                        ),
                        itemCount: photosState.items.length,
                        itemBuilder: (context, index) {
                          final photo = photosState.items[index];
                          return PhotoGridItem(
                            photo: photo,
                            canToggleFeature: canManage,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _FullScreenViewer(
                                    photos: photosState.items,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                            },
                            onLongPress: canManage
                                ? () => _toggleFeature(photo.id)
                                : null,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          if (photosState.isSubmitting)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                color: AppColors.navyMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _AlbumHeader extends StatelessWidget {
  const _AlbumHeader({required this.album});

  final AlbumModel? album;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space8,
      ),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            album?.eventName ?? "Album",
            style: AppTypography.headlineSmall,
          ),
          const SizedBox(height: AppDimensions.space8),
          Row(
            children: [
              const Icon(
                Icons.event_outlined,
                size: AppDimensions.iconSM,
                color: AppColors.grey600,
              ),
              const SizedBox(width: AppDimensions.space8),
              Text(
                album == null
                    ? "Date unavailable"
                    : DateFormatter.formatDate(album!.eventDate),
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
          if (album?.description != null &&
              album!.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppDimensions.space12),
            Text(
              album!.description!,
              style: AppTypography.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _FullScreenViewer extends StatefulWidget {
  const _FullScreenViewer({
    required this.photos,
    required this.initialIndex,
  });

  final List<PhotoModel> photos;
  final int initialIndex;

  @override
  State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: Text(
          "${_currentIndex + 1} / ${widget.photos.length}",
          style: AppTypography.titleLargeOnDark,
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5,
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photo.photoUrl ?? "",
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        size: AppDimensions.iconJumbo,
                        color: AppColors.grey400,
                      ),
                    ),
                  ),
                ),
              ),
              if (photo.caption != null &&
                  photo.caption.toString().trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    0,
                    AppDimensions.space16,
                    AppDimensions.space20,
                  ),
                  child: Text(
                    photo.caption.toString(),
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
