import '../../../core/utils/media_url_resolver.dart';

class PhotoModel {
  const PhotoModel({
    required this.id,
    required this.albumId,
    required this.photoKey,
    required this.isFeatured,
    required this.schoolId,
    required this.uploadedAt,
    required this.createdAt,
    required this.updatedAt,
    this.photoUrl,
    this.caption,
    this.uploadedBy,
  });

  final String id;
  final String albumId;
  final String photoKey;
  final String? photoUrl;
  final String? caption;
  final String? uploadedBy;
  final bool isFeatured;
  final String schoolId;
  final DateTime uploadedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotoModel(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      photoKey: json['photo_key'] as String,
      photoUrl: MediaUrlResolver.resolveNullable(json['photo_url'] as String?),
      caption: json['caption'] as String?,
      uploadedBy: json['uploaded_by'] as String?,
      isFeatured: json['is_featured'] as bool? ?? false,
      schoolId: json['school_id'] as String,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  PhotoModel copyWith({
    bool? isFeatured,
    String? photoUrl,
  }) {
    return PhotoModel(
      id: id,
      albumId: albumId,
      photoKey: photoKey,
      photoUrl: photoUrl ?? this.photoUrl,
      caption: caption,
      uploadedBy: uploadedBy,
      isFeatured: isFeatured ?? this.isFeatured,
      schoolId: schoolId,
      uploadedAt: uploadedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PhotoListResponse {
  const PhotoListResponse({
    required this.items,
    required this.total,
  });

  final List<PhotoModel> items;
  final int total;

  factory PhotoListResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return PhotoListResponse(
      items: items
          .map((e) => PhotoModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? items.length,
    );
  }
}

class PhotoCommentModel {
  const PhotoCommentModel({
    required this.id,
    required this.photoId,
    required this.comment,
    required this.commentedBy,
    required this.commenterRole,
    required this.schoolId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String photoId;
  final String comment;
  final String commentedBy;
  final String commenterRole;
  final String schoolId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PhotoCommentModel.fromJson(Map<String, dynamic> json) {
    return PhotoCommentModel(
      id: json['id'] as String,
      photoId: json['photo_id'] as String,
      comment: json['comment'] as String? ?? '',
      commentedBy: json['commented_by'] as String? ?? '',
      commenterRole: json['commenter_role'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class PhotoInteractionModel {
  const PhotoInteractionModel({
    required this.photoId,
    required this.reactionsCount,
    required this.hasReacted,
    required this.comments,
    required this.totalComments,
  });

  final String photoId;
  final int reactionsCount;
  final bool hasReacted;
  final List<PhotoCommentModel> comments;
  final int totalComments;

  factory PhotoInteractionModel.fromJson(Map<String, dynamic> json) {
    final commentItems = json['comments'] as List<dynamic>? ?? [];
    return PhotoInteractionModel(
      photoId: json['photo_id'] as String,
      reactionsCount: json['reactions_count'] as int? ?? 0,
      hasReacted: json['has_reacted'] as bool? ?? false,
      comments: commentItems
          .map((e) => PhotoCommentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalComments: json['total_comments'] as int? ?? commentItems.length,
    );
  }
}
