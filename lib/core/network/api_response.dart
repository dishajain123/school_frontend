/// Generic wrapper for paginated list responses from the backend.
class ApiListResponse<T> {
  const ApiListResponse({
    required this.items,
    required this.total,
    this.page,
    this.pageSize,
    this.totalPages,
  });

  final List<T> items;
  final int total;
  final int? page;
  final int? pageSize;
  final int? totalPages;

  factory ApiListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return ApiListResponse<T>(
      items: rawItems.map((e) => fromJson(e as Map<String, dynamic>)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int?,
      pageSize: json['page_size'] as int?,
      totalPages: json['total_pages'] as int?,
    );
  }
}