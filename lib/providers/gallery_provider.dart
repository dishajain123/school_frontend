import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/auth/current_user.dart';
import '../data/models/gallery/album_model.dart';
import '../data/models/gallery/photo_model.dart';
import '../data/repositories/gallery_repository.dart';
import 'auth_provider.dart';

class GalleryAlbumListState {
  const GalleryAlbumListState({
    this.items = const [],
    this.total = 0,
    this.photoCounts = const {},
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<AlbumModel> items;
  final int total;
  final Map<String, int> photoCounts;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  GalleryAlbumListState copyWith({
    List<AlbumModel>? items,
    int? total,
    Map<String, int>? photoCounts,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return GalleryAlbumListState(
      items: items ?? this.items,
      total: total ?? this.total,
      photoCounts: photoCounts ?? this.photoCounts,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class GalleryAlbumListNotifier extends AsyncNotifier<GalleryAlbumListState> {
  @override
  Future<GalleryAlbumListState> build() async {
    return const GalleryAlbumListState();
  }

  Future<void> load({bool refresh = false}) async {
    final current = state.valueOrNull ?? const GalleryAlbumListState();
    state = AsyncData(current.copyWith(isLoading: true, clearError: true));

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final result = await repo.listAlbums();
      state = AsyncData(
        (state.valueOrNull ?? const GalleryAlbumListState()).copyWith(
          items: result.items,
          total: result.total,
          isLoading: false,
        ),
      );
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const GalleryAlbumListState()).copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<AlbumModel?> createAlbum(Map<String, dynamic> payload) async {
    final current = state.valueOrNull ?? const GalleryAlbumListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final created = await repo.createAlbum(payload);
      final prev = state.valueOrNull ?? const GalleryAlbumListState();

      final counts = Map<String, int>.from(prev.photoCounts);
      counts[created.id] = 0;

      state = AsyncData(
        prev.copyWith(
          items: [created, ...prev.items],
          total: prev.total + 1,
          photoCounts: counts,
          isSubmitting: false,
        ),
      );
      return created;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const GalleryAlbumListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<AlbumModel?> updateAlbum({
    required String albumId,
    required Map<String, dynamic> payload,
  }) async {
    final current = state.valueOrNull ?? const GalleryAlbumListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final updated = await repo.updateAlbum(albumId: albumId, payload: payload);
      final prev = state.valueOrNull ?? const GalleryAlbumListState();
      final updatedItems = prev.items
          .map((album) => album.id == albumId ? updated : album)
          .toList();
      state = AsyncData(
        prev.copyWith(
          items: updatedItems,
          isSubmitting: false,
        ),
      );
      return updated;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const GalleryAlbumListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<bool> deleteAlbum(String albumId) async {
    final current = state.valueOrNull ?? const GalleryAlbumListState();
    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      final repo = ref.read(galleryRepositoryProvider);
      await repo.deleteAlbum(albumId);

      final prev = state.valueOrNull ?? const GalleryAlbumListState();
      final updatedItems = prev.items.where((album) => album.id != albumId).toList();
      final updatedCounts = Map<String, int>.from(prev.photoCounts)
        ..remove(albumId);

      state = AsyncData(
        prev.copyWith(
          items: updatedItems,
          total: updatedItems.length,
          photoCounts: updatedCounts,
          isSubmitting: false,
        ),
      );
      return true;
    } catch (e) {
      state = AsyncData(
        (state.valueOrNull ?? const GalleryAlbumListState()).copyWith(
          isSubmitting: false,
          error: e.toString(),
        ),
      );
      return false;
    }
  }

  void setPhotoCount(String albumId, int count) {
    final current = state.valueOrNull;
    if (current == null) return;
    final counts = Map<String, int>.from(current.photoCounts);
    counts[albumId] = count;
    state = AsyncData(current.copyWith(photoCounts: counts));
  }

  void incrementPhotoCount(String albumId, {int by = 1}) {
    final current = state.valueOrNull;
    if (current == null) return;
    final counts = Map<String, int>.from(current.photoCounts);
    counts[albumId] = (counts[albumId] ?? 0) + by;
    state = AsyncData(current.copyWith(photoCounts: counts));
  }

  void upsertAlbumCover({
    required String albumId,
    String? coverPhotoKey,
    String? coverPhotoUrl,
    bool clearCover = false,
  }) {
    final current = state.valueOrNull;
    if (current == null) return;

    final updatedItems = current.items.map((album) {
      if (album.id != albumId) return album;
      return album.copyWith(
        coverPhotoKey: coverPhotoKey,
        coverPhotoUrl: coverPhotoUrl,
        clearCoverPhoto: clearCover,
      );
    }).toList();

    state = AsyncData(current.copyWith(items: updatedItems));
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(clearError: true));
    }
  }
}

final galleryAlbumListNotifierProvider =
    AsyncNotifierProvider<GalleryAlbumListNotifier, GalleryAlbumListState>(
  GalleryAlbumListNotifier.new,
);

class AlbumPhotoListState {
  const AlbumPhotoListState({
    this.items = const [],
    this.total = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final List<PhotoModel> items;
  final int total;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  AlbumPhotoListState copyWith({
    List<PhotoModel>? items,
    int? total,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return AlbumPhotoListState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AlbumPhotoListNotifier extends StateNotifier<AlbumPhotoListState> {
  AlbumPhotoListNotifier(this.ref, this.albumId)
      : super(const AlbumPhotoListState()) {
    load();
  }

  final Ref ref;
  final String albumId;

  Future<void> load({bool refresh = false}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final result = await repo.listPhotos(albumId);
      state = state.copyWith(
        items: result.items,
        total: result.total,
        isLoading: false,
      );
      ref
          .read(galleryAlbumListNotifierProvider.notifier)
          .setPhotoCount(albumId, result.total);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> uploadPhoto({
    required List<int> fileBytes,
    required String fileName,
    String? caption,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final uploaded = await repo.uploadPhoto(
        albumId: albumId,
        fileBytes: fileBytes,
        fileName: fileName,
        caption: caption,
      );

      state = state.copyWith(
        items: [uploaded, ...state.items],
        total: state.total + 1,
        isSubmitting: false,
      );

      final albumNotifier = ref.read(galleryAlbumListNotifierProvider.notifier);
      albumNotifier.incrementPhotoCount(albumId);
      if (uploaded.isFeatured) {
        albumNotifier.upsertAlbumCover(
          albumId: albumId,
          coverPhotoKey: uploaded.photoKey,
          coverPhotoUrl: uploaded.photoUrl,
        );
      }
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<PhotoModel?> toggleFeature(String photoId) async {
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final repo = ref.read(galleryRepositoryProvider);
      final updated = await repo.toggleFeature(photoId);

      final newItems = state.items
          .map((photo) => photo.id == updated.id ? updated : photo)
          .toList();
      state = state.copyWith(items: newItems, isSubmitting: false);

      final albumNotifier = ref.read(galleryAlbumListNotifierProvider.notifier);
      if (updated.isFeatured) {
        albumNotifier.upsertAlbumCover(
          albumId: albumId,
          coverPhotoKey: updated.photoKey,
          coverPhotoUrl: updated.photoUrl,
        );
      } else {
        final album = ref.read(galleryAlbumByIdProvider(albumId));
        if (album?.coverPhotoKey == updated.photoKey) {
          albumNotifier.upsertAlbumCover(albumId: albumId, clearCover: true);
        }
      }

      return updated;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final albumPhotoListProvider = StateNotifierProvider.family<
    AlbumPhotoListNotifier, AlbumPhotoListState, String>(
  (ref, albumId) => AlbumPhotoListNotifier(ref, albumId),
);

final galleryAlbumByIdProvider =
    Provider.family<AlbumModel?, String>((ref, albumId) {
  final state = ref.watch(galleryAlbumListNotifierProvider).valueOrNull;
  if (state == null) return null;
  try {
    return state.items.firstWhere((a) => a.id == albumId);
  } catch (_) {
    return null;
  }
});

final galleryCanManageProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.hasPermission('gallery:create') ||
      user.role.isSchoolScopedAdmin ||
      user.role == UserRole.teacher;
});

final galleryCanDeleteAlbumProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role.isSchoolScopedAdmin;
});

final galleryCanInteractProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return false;
  return user.role == UserRole.parent ||
      user.role == UserRole.student ||
      user.role == UserRole.teacher ||
      user.role == UserRole.trustee;
});

class PhotoInteractionState {
  const PhotoInteractionState({
    this.photoId = '',
    this.reactionsCount = 0,
    this.hasReacted = false,
    this.comments = const [],
    this.totalComments = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
  });

  final String photoId;
  final int reactionsCount;
  final bool hasReacted;
  final List<PhotoCommentModel> comments;
  final int totalComments;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;

  PhotoInteractionState copyWith({
    String? photoId,
    int? reactionsCount,
    bool? hasReacted,
    List<PhotoCommentModel>? comments,
    int? totalComments,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return PhotoInteractionState(
      photoId: photoId ?? this.photoId,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      hasReacted: hasReacted ?? this.hasReacted,
      comments: comments ?? this.comments,
      totalComments: totalComments ?? this.totalComments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PhotoInteractionNotifier extends StateNotifier<PhotoInteractionState> {
  PhotoInteractionNotifier(this.ref, this.photoId)
      : super(PhotoInteractionState(photoId: photoId)) {
    load();
  }

  final Ref ref;
  final String photoId;

  void _applyInteraction(PhotoInteractionModel model,
      {bool keepLoading = false}) {
    state = state.copyWith(
      photoId: model.photoId,
      reactionsCount: model.reactionsCount,
      hasReacted: model.hasReacted,
      comments: model.comments,
      totalComments: model.totalComments,
      isLoading: keepLoading ? state.isLoading : false,
      isSubmitting: false,
      clearError: true,
    );
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(galleryRepositoryProvider);
      final interactions = await repo.getPhotoInteractions(photoId);
      _applyInteraction(interactions);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> toggleReaction() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(galleryRepositoryProvider);
      final interactions = state.hasReacted
          ? await repo.clearReaction(photoId)
          : await repo.setReaction(photoId);
      _applyInteraction(interactions);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
    }
  }

  Future<bool> addComment(String comment) async {
    final text = comment.trim();
    if (text.isEmpty) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(galleryRepositoryProvider);
      final interactions =
          await repo.addComment(photoId: photoId, comment: text);
      _applyInteraction(interactions);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteComment(String commentId) async {
    if (commentId.trim().isEmpty) return false;

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final repo = ref.read(galleryRepositoryProvider);
      final interactions =
          await repo.deleteComment(photoId: photoId, commentId: commentId);
      _applyInteraction(interactions);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final photoInteractionProvider = StateNotifierProvider.family<
    PhotoInteractionNotifier, PhotoInteractionState, String>(
  (ref, photoId) => PhotoInteractionNotifier(ref, photoId),
);
