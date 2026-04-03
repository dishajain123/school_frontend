class AlbumModel {
  const AlbumModel({
    required this.id,
    required this.eventName,
    required this.eventDate,
    required this.schoolId,
    required this.academicYearId,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverPhotoKey,
    this.coverPhotoUrl,
    this.createdBy,
  });

  final String id;
  final String eventName;
  final DateTime eventDate;
  final String? description;
  final String? coverPhotoKey;
  final String? coverPhotoUrl;
  final String? createdBy;
  final String schoolId;
  final String academicYearId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id'] as String,
      eventName: json['event_name'] as String? ?? '',
      eventDate: DateTime.parse(json['event_date'] as String),
      description: json['description'] as String?,
      coverPhotoKey: json['cover_photo_key'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      createdBy: json['created_by'] as String?,
      schoolId: json['school_id'] as String,
      academicYearId: json['academic_year_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  AlbumModel copyWith({
    String? coverPhotoKey,
    String? coverPhotoUrl,
    bool clearCoverPhoto = false,
  }) {
    return AlbumModel(
      id: id,
      eventName: eventName,
      eventDate: eventDate,
      description: description,
      coverPhotoKey:
          clearCoverPhoto ? null : (coverPhotoKey ?? this.coverPhotoKey),
      coverPhotoUrl:
          clearCoverPhoto ? null : (coverPhotoUrl ?? this.coverPhotoUrl),
      createdBy: createdBy,
      schoolId: schoolId,
      academicYearId: academicYearId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class AlbumListResponse {
  const AlbumListResponse({
    required this.items,
    required this.total,
  });

  final List<AlbumModel> items;
  final int total;

  factory AlbumListResponse.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return AlbumListResponse(
      items: items
          .map((e) => AlbumModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? items.length,
    );
  }
}
