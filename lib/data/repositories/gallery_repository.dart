import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/gallery/album_model.dart';
import '../models/gallery/photo_model.dart';

class GalleryRepository {
  const GalleryRepository(this._dio);
  final Dio _dio;

  String? _guessImageMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.bmp')) return 'image/bmp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return null;
  }

  Future<AlbumListResponse> listAlbums() async {
    final response = await _dio.get(ApiConstants.galleryAlbums);
    return AlbumListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlbumModel> createAlbum(Map<String, dynamic> payload) async {
    final response = await _dio.post(
      ApiConstants.galleryAlbums,
      data: payload,
    );
    return AlbumModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PhotoModel> uploadPhoto({
    required String albumId,
    required List<int> fileBytes,
    required String fileName,
    String? caption,
  }) async {
    final mimeType = _guessImageMimeType(fileName);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: mimeType == null ? null : DioMediaType.parse(mimeType),
      ),
      if (caption != null && caption.trim().isNotEmpty)
        'caption': caption.trim(),
    });

    final response = await _dio.post(
      ApiConstants.galleryAlbumPhotos(albumId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return PhotoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PhotoListResponse> listPhotos(String albumId) async {
    final response = await _dio.get(ApiConstants.galleryAlbumPhotos(albumId));
    return PhotoListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PhotoModel> toggleFeature(String photoId) async {
    final response =
        await _dio.patch(ApiConstants.galleryPhotoFeature(photoId));
    return PhotoModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PhotoInteractionModel> getPhotoInteractions(String photoId) async {
    final response =
        await _dio.get(ApiConstants.galleryPhotoInteractions(photoId));
    return PhotoInteractionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PhotoInteractionModel> setReaction(String photoId) async {
    final response = await _dio.put(ApiConstants.galleryPhotoReaction(photoId));
    return PhotoInteractionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PhotoInteractionModel> clearReaction(String photoId) async {
    final response =
        await _dio.delete(ApiConstants.galleryPhotoReaction(photoId));
    return PhotoInteractionModel.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<PhotoInteractionModel> addComment({
    required String photoId,
    required String comment,
  }) async {
    final response = await _dio.post(
      ApiConstants.galleryPhotoComments(photoId),
      data: {'comment': comment},
    );
    return PhotoInteractionModel.fromJson(
        response.data as Map<String, dynamic>);
  }
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository(ref.read(dioClientProvider));
});
