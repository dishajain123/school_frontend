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
      photoUrl: json['photo_url'] as String?,
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
