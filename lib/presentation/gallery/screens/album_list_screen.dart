import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/router/route_names.dart";
import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
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

class _AlbumListScreenState extends ConsumerState<AlbumListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(galleryAlbumListNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(galleryAlbumListNotifierProvider);
    final canManage = ref.watch(galleryCanManageProvider);

    return AppScaffold(
      appBar: const AppAppBar(
        title: "School Gallery",
        showBack: true,
      ),
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.createAlbum),
              tooltip: "Create Album",
              backgroundColor: AppColors.goldPrimary,
              child: const Icon(Icons.add_rounded),
            )
          : null,
      body: albumsAsync.when(
        loading: () => AppLoading.grid(count: 6),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () =>
              ref.read(galleryAlbumListNotifierProvider.notifier).load(),
        ),
        data: (state) {
          if (state.isLoading && state.items.isEmpty) {
            return AppLoading.grid(count: 6);
          }

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
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.space16,
                AppDimensions.space16,
                AppDimensions.space16,
                AppDimensions.pageBottomScroll,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppDimensions.gridGap2col,
                mainAxisSpacing: AppDimensions.gridGap2col,
                childAspectRatio: 1,
              ),
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                final album = state.items[index];
                final photoState = ref.watch(albumPhotoListProvider(album.id));
                final count = photoState.total;
                return AlbumCard(
                  album: album,
                  photoCount: count,
                  onTap: () {
                    context.push(
                      RouteNames.albumDetailPath(album.id),
                      extra: album,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
