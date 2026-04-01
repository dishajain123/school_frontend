import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/notification/notification_model.dart';

class NotificationInboxResult {
  const NotificationInboxResult({
    required this.items,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<NotificationModel> items;
  final int total;
  final int unreadCount;
  final int page;
  final int pageSize;
  final int totalPages;

  factory NotificationInboxResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return NotificationInboxResult(
      items: rawItems
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      unreadCount: json['unread_count'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }
}

class NotificationRepository {
  const NotificationRepository(this._dio);
  final Dio _dio;

  Future<NotificationInboxResult> getInbox({
    bool? isRead,
    String? type,
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (isRead != null) params['is_read'] = isRead;
    if (type != null) params['type'] = type;

    final response = await _dio.get(
      ApiConstants.notifications,
      queryParameters: params,
    );
    return NotificationInboxResult.fromJson(
        response.data as Map<String, dynamic>);
  }

  Future<int> getUnreadCount() async {
    final response =
        await _dio.get(ApiConstants.notificationsUnreadCount);
    return (response.data as Map<String, dynamic>)['unread_count'] as int? ??
        0;
  }

  Future<int> markRead(List<String> ids) async {
    final response = await _dio.patch(
      ApiConstants.notificationsMarkRead,
      data: {'ids': ids},
    );
    return (response.data as Map<String, dynamic>)['updated'] as int? ?? 0;
  }

  Future<int> markAllRead() async {
    final response =
        await _dio.patch(ApiConstants.notificationsMarkAllRead);
    return (response.data as Map<String, dynamic>)['updated'] as int? ?? 0;
  }

  Future<int> clearRead() async {
    final response =
        await _dio.delete(ApiConstants.notificationsClearRead);
    return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(dioClientProvider));
});