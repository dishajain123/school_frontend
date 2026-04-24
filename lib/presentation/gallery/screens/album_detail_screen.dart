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
import "../../../providers/auth_provider.dart";
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
          fileBytes: await image.readAsBytes(),
          fileName: image.name,
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
          .uploadPhoto(
            fileBytes: await image.readAsBytes(),
            fileName: image.name,
          );
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Future<void> _deleteAlbum(AlbumModel album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete album?'),
        content: Text(
          'This will remove "${album.eventName}" and all its photos. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref
        .read(galleryAlbumListNotifierProvider.notifier)
        .deleteAlbum(album.id);
    if (!mounted) return;

    if (success) {
      SnackbarUtils.showSuccess(context, 'Album deleted successfully');
      Navigator.of(context).maybePop();
    } else {
      final error =
          ref.read(galleryAlbumListNotifierProvider).valueOrNull?.error;
      SnackbarUtils.showError(context, error ?? 'Failed to delete album');
    }
  }

  Future<void> _editAlbum(AlbumModel album) async {
    final nameController = TextEditingController(text: album.eventName);
    final descriptionController =
        TextEditingController(text: album.description ?? '');
    DateTime selectedDate = album.eventDate;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Edit Album'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Event Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Event Date'),
                      subtitle: Text(DateFormatter.formatDate(selectedDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(DateTime.now().year - 10),
                          lastDate: DateTime(DateTime.now().year + 5),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      nameController.dispose();
      descriptionController.dispose();
      return;
    }

    final eventName = nameController.text.trim();
    final description = descriptionController.text.trim();
    nameController.dispose();
    descriptionController.dispose();

    if (eventName.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Event name is required');
      return;
    }

    final payload = <String, dynamic>{
      'event_name': eventName,
      'event_date': DateFormatter.formatDateForApi(selectedDate),
      'description': description.isEmpty ? null : description,
    };

    final updated = await ref
        .read(galleryAlbumListNotifierProvider.notifier)
        .updateAlbum(albumId: album.id, payload: payload);
    if (!mounted) return;
    if (updated != null) {
      SnackbarUtils.showSuccess(context, 'Album updated successfully');
    } else {
      final error =
          ref.read(galleryAlbumListNotifierProvider).valueOrNull?.error;
      SnackbarUtils.showError(context, error ?? 'Failed to update album');
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosState = ref.watch(albumPhotoListProvider(widget.albumId));
    final canManage = ref.watch(galleryCanManageProvider);
    final canDeleteAlbum = ref.watch(galleryCanDeleteAlbumProvider);
    final canInteract = ref.watch(galleryCanInteractProvider);
    final album = ref.watch(galleryAlbumByIdProvider(widget.albumId)) ??
        widget.initialAlbum;

    return AppScaffold(
      appBar: AppAppBar(
        title: album?.eventName ?? "Album",
        showBack: true,
        actions: [
          if (canManage && album != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => _editAlbum(album),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
          if (canDeleteAlbum && album != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => _deleteAlbum(album),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete_outline,
                      color: AppColors.white, size: 18),
                ),
              ),
            ),
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
                            canInteract: canInteract,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _FullScreenViewer(
                                    photos: photosState.items,
                                    initialIndex: index,
                                    canInteract: canInteract,
                                  ),
                                ),
                              );
                            },
                            onFeatureTap: canManage
                                ? () => _toggleFeature(photo.id)
                                : null,
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

class _FullScreenViewer extends ConsumerStatefulWidget {
  const _FullScreenViewer({
    required this.photos,
    required this.initialIndex,
    required this.canInteract,
  });

  final List<PhotoModel> photos;
  final int initialIndex;
  final bool canInteract;

  @override
  ConsumerState<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends ConsumerState<_FullScreenViewer> {
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

  Future<void> _openInteractionsSheet(String photoId) async {
    final commentController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Consumer(
              builder: (context, ref, _) {
                final interactionState =
                    ref.watch(photoInteractionProvider(photoId));
                final currentUser = ref.watch(currentUserProvider);

                return Column(
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surface200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Reactions & Comments',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: widget.canInteract &&
                                  !interactionState.isSubmitting
                              ? () => ref
                                  .read(photoInteractionProvider(photoId)
                                      .notifier)
                                  .toggleReaction()
                              : null,
                          icon: Icon(
                            interactionState.hasReacted
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: interactionState.hasReacted
                                ? AppColors.errorRed
                                : AppColors.grey600,
                          ),
                          label: Text('${interactionState.reactionsCount}'),
                        ),
                      ],
                    ),
                    if (interactionState.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          interactionState.error!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.errorRed,
                          ),
                        ),
                      ),
                    Expanded(
                      child: interactionState.isLoading
                          ? const Center(
                              child: CircularProgressIndicator.adaptive())
                          : interactionState.comments.isEmpty
                              ? Center(
                                  child: Text(
                                    'No comments yet',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: interactionState.comments.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 16,
                                    color: AppColors.surface100,
                                  ),
                                  itemBuilder: (context, index) {
                                    final comment =
                                        interactionState.comments[index];
                                    final role =
                                        _roleLabel(comment.commenterRole);
                                    final canDeleteComment =
                                        currentUser?.id == comment.commentedBy;
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              role,
                                              style: AppTypography.labelMedium
                                                  .copyWith(
                                                color: AppColors.navyDeep,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              DateFormatter.formatRelative(
                                                  comment.createdAt),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: AppColors.grey500,
                                              ),
                                            ),
                                            const Spacer(),
                                            if (canDeleteComment)
                                              IconButton(
                                                visualDensity:
                                                    VisualDensity.compact,
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                                tooltip: 'Delete comment',
                                                onPressed:
                                                    interactionState.isSubmitting
                                                        ? null
                                                        : () async {
                                                            final ok = await ref
                                                                .read(photoInteractionProvider(
                                                                        photoId)
                                                                    .notifier)
                                                                .deleteComment(
                                                                    comment.id);
                                                            if (!context.mounted) {
                                                              return;
                                                            }
                                                            if (ok) {
                                                              SnackbarUtils
                                                                  .showSuccess(
                                                                context,
                                                                'Comment deleted',
                                                              );
                                                            } else {
                                                              SnackbarUtils
                                                                  .showError(
                                                                context,
                                                                'Failed to delete comment',
                                                              );
                                                            }
                                                          },
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 18,
                                                  color: AppColors.grey500,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          comment.comment,
                                          style:
                                              AppTypography.bodyMedium.copyWith(
                                            color: AppColors.grey700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                    ),
                    if (!widget.canInteract)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Only parents, students, teachers, and trustees can react/comment.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.grey500,
                          ),
                        ),
                      ),
                    if (widget.canInteract)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commentController,
                              minLines: 1,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Write a comment',
                                isDense: true,
                                filled: true,
                                fillColor: AppColors.surface50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: interactionState.isSubmitting
                                ? null
                                : () async {
                                    final ok = await ref
                                        .read(photoInteractionProvider(photoId)
                                            .notifier)
                                        .addComment(commentController.text);
                                    if (ok) commentController.clear();
                                  },
                            icon: const Icon(Icons.send_rounded),
                            color: AppColors.navyDeep,
                          ),
                        ],
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    commentController.dispose();
  }

  String _roleLabel(String raw) {
    final normalized = raw.trim().toUpperCase();
    if (normalized == 'PARENT') return 'Parent';
    if (normalized == 'STUDENT') return 'Student';
    if (normalized == 'TEACHER') return 'Teacher';
    if (normalized == 'TRUSTEE') return 'Trustee';
    if (normalized == 'PRINCIPAL') return 'Principal';
    return 'User';
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_currentIndex];
    final interactionState = ref.watch(photoInteractionProvider(photo.id));

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
        actions: [
          IconButton(
            onPressed: () => _openInteractionsSheet(photo.id),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.mode_comment_outlined, color: AppColors.white),
                if (interactionState.totalComments > 0)
                  Positioned(
                    right: -7,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${interactionState.totalComments}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
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
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
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
          Positioned(
            right: 14,
            bottom: photo.caption != null &&
                    photo.caption.toString().trim().isNotEmpty
                ? 96
                : 24,
            child: GestureDetector(
              onTap: widget.canInteract && !interactionState.isSubmitting
                  ? () {
                      ref
                          .read(photoInteractionProvider(photo.id).notifier)
                          .toggleReaction();
                    }
                  : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      interactionState.hasReacted
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 14,
                      color: interactionState.hasReacted
                          ? AppColors.errorRed
                          : AppColors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${interactionState.reactionsCount}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.mode_comment_outlined,
                        size: 14, color: AppColors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${interactionState.totalComments}',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
