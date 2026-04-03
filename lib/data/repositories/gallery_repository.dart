import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/gallery/album_model.dart';
import '../models/gallery/photo_model.dart';

class GalleryRepository {
  const GalleryRepository(this._dio);
  final Dio _dio;

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
    required File file,
    String? caption,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
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
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepository(ref.read(dioClientProvider));
});
