import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:image_picker/image_picker.dart";

import "../../../core/theme/app_colors.dart";
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

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fabCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryAlbumListNotifierProvider.notifier).load();
      ref.read(albumPhotoListProvider(widget.albumId).notifier).load();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
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
      SnackbarUtils.showError(context, error ?? "Photo upload failed");
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
          context, "$uploadedCount of ${images.length} photos uploaded");
    }
  }

  Future<String?> _askCaption() async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Add caption"),
          content: TextField(
            controller: controller,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: "Optional photo caption",
              filled: true,
              fillColor: AppColors.surface50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
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
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.4),
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Upload Photos",
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 16),
                _UploadOption(
                  icon: Icons.photo_outlined,
                  label: "Single Photo",
                  subtitle: "Pick one photo with optional caption",
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadSinglePhoto();
                  },
                ),
                const SizedBox(height: 10),
                _UploadOption(
                  icon: Icons.collections_outlined,
                  label: "Multiple Photos",
                  subtitle: "Select and upload several photos at once",
                  onTap: () {
                    Navigator.of(context).pop();
                    _uploadMultiplePhotos();
                  },
                ),
                const SizedBox(height: 20),
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
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _showUploadChoice,
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_a_photo_outlined,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          if (photosState.isLoading && photosState.items.isEmpty)
            _buildShimmer()
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
                            ? "Tap the camera icon to upload event photos."
                            : "Photos will appear here once uploaded.",
                        icon: Icons.photo_library_outlined,
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: Text(
                          "${photosState.items.length} Photos",
                          style: AppTypography.caption.copyWith(
                            color: AppColors.grey400,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
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
                            onLongPress:
                                canManage ? () => _toggleFeature(photo.id) : null,
                          );
                        },
                      ),
                    ),
                  ],
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
                color: AppColors.goldPrimary,
                backgroundColor: AppColors.surface100,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AppLoading.card(height: double.infinity),
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  const _UploadOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: AppColors.navyDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.grey300),
          ],
        ),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navyDeep.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    size: 18, color: AppColors.navyDeep),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  album?.eventName ?? "Album",
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_outlined,
                  size: 14, color: AppColors.grey400),
              const SizedBox(width: 6),
              Text(
                album == null
                    ? "Date unavailable"
                    : DateFormatter.formatDate(album!.eventDate),
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (album?.description != null &&
              album!.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(height: 1, color: AppColors.surface100),
            const SizedBox(height: 10),
            Text(
              album!.description!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey600,
                height: 1.5,
                fontSize: 12,
              ),
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
    final photo = widget.photos[_currentIndex];

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.white, size: 16),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${_currentIndex + 1} / ${widget.photos.length}",
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final p = widget.photos[index];
              return InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: p.photoUrl ?? "",
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      size: 56,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              );
            },
          ),
          if (photo.caption != null &&
              photo.caption.toString().trim().isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
                child: Text(
                  photo.caption.toString(),
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
