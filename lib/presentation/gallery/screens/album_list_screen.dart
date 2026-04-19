import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_typography.dart";
import "../../../providers/gallery_provider.dart";
import "../../common/widgets/app_app_bar.dart";
import "../../common/widgets/app_empty_state.dart";
import "../../common/widgets/app_error_state.dart";
import "../../common/widgets/app_loading.dart";
import "../../common/widgets/app_scaffold.dart";
import "../widgets/album_card.dart";

class AlbumListScreen extends ConsumerStatefulWidget {
  const AlbumListScreen({super.key});

  @override
  ConsumerState<AlbumListScreen> createState() => _AlbumListScreenState();
}

class _AlbumListScreenState extends ConsumerState<AlbumListScreen>
    with SingleTickerProviderStateMixin {
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
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(galleryAlbumListNotifierProvider);
    final canManage = ref.watch(galleryCanManageProvider);

    return AppScaffold(
      appBar: AppAppBar(
        title: "School Gallery",
        showBack: true,
        actions: [
          if (canManage)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => context.push(RouteNames.createAlbum),
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: albumsAsync.when(
        loading: () => _buildShimmer(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(galleryAlbumListNotifierProvider.notifier).load(),
        ),
        data: (state) {
          if (state.isLoading && state.items.isEmpty) return _buildShimmer();

          if (state.items.isEmpty) {
            return RefreshIndicator(
              color: AppColors.navyDeep,
              onRefresh: () async {
                await ref
                    .read(galleryAlbumListNotifierProvider.notifier)
                    .refresh();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.7,
                    child: AppEmptyState(
                      title: "No albums yet",
                      subtitle: "School event photos will appear here.",
                      icon: Icons.photo_library_outlined,
                      actionLabel: canManage ? "Create Album" : null,
                      onAction: canManage
                          ? () => context.push(RouteNames.createAlbum)
                          : null,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.navyDeep,
            onRefresh: () async {
              await ref
                  .read(galleryAlbumListNotifierProvider.notifier)
                  .refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          "${state.items.length} Albums",
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.grey500,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final album = state.items[index];
                      final photoState =
                          ref.watch(albumPhotoListProvider(album.id));
                      return AlbumCard(
                        album: album,
                        photoCount: photoState.total,
                        onTap: () => context.push(
                          RouteNames.albumDetailPath(album.id),
                          extra: album,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AppLoading.card(height: double.infinity),
      ),
    );
  }
}
