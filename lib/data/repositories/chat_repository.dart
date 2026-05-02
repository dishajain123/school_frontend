import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import '../models/chat/conversation_model.dart';
import '../models/chat/message_model.dart';

class MessageListResult {
  const MessageListResult({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  final List<MessageModel> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
}

class MessageReactionResult {
  const MessageReactionResult({
    required this.messageId,
    required this.conversationId,
    required this.status,
    required this.reactions,
    this.reaction,
    this.myReaction,
  });

  final String messageId;
  final String conversationId;
  final String status;
  final String? reaction;
  final String? myReaction;
  final List<MessageReactionSummary> reactions;

  factory MessageReactionResult.fromJson(Map<String, dynamic> json) {
    return MessageReactionResult(
      messageId: json['message_id'] as String,
      conversationId: json['conversation_id'] as String,
      status: (json['status'] ?? '').toString(),
      reaction: json['reaction'] as String?,
      myReaction: json['my_reaction'] as String?,
      reactions: ((json['reactions'] as List<dynamic>?) ?? const [])
          .map(
              (e) => MessageReactionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.role,
    this.displayNameOverride,
    this.fullName,
    this.email,
    this.phone,
  });

  final String id;
  final String role;
  final String? displayNameOverride;
  final String? fullName;
  final String? email;
  final String? phone;

  String get displayName {
    if (displayNameOverride != null && displayNameOverride!.isNotEmpty) {
      return displayNameOverride!;
    }
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    return phone ?? id;
  }

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String,
      role: json['role'] as String? ?? '',
      displayNameOverride: json['display_name'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

class ChatRepository {
  const ChatRepository(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureStorage _secureStorage;

  // ── Conversations ──────────────────────────────────────────────────────────

  Future<List<ConversationModel>> listConversations() async {
    final response = await _dio.get(ApiConstants.chatConversations);
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationModel> createConversation({
    required String type,
    required List<String> participantIds,
    String? name,
    String? standardId,
    String? academicYearId,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'participant_ids': participantIds,
      if (name != null && name.isNotEmpty) 'name': name,
      if (standardId != null) 'standard_id': standardId,
      if (academicYearId != null) 'academic_year_id': academicYearId,
    };
    final response =
        await _dio.post(ApiConstants.chatConversations, data: body);
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete(ApiConstants.chatConversationById(conversationId));
  }

  // ── Messages ───────────────────────────────────────────────────────────────

  /// Returns messages for a conversation — backend returns newest first (DESC).
  Future<MessageListResult> listMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final response = await _dio.get(
      ApiConstants.chatMessages(conversationId),
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return MessageListResult(
      items: items,
      total: data['total'] as int? ?? 0,
      page: data['page'] as int? ?? 1,
      pageSize: data['page_size'] as int? ?? 30,
      totalPages: data['total_pages'] as int? ?? 0,
    );
  }

  Future<int> markRead(
    String conversationId,
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) return 0;
    final response = await _dio.patch(
      ApiConstants.chatMarkRead(conversationId),
      data: {'message_ids': messageIds},
    );
    return (response.data as Map<String, dynamic>)['updated'] as int? ?? 0;
  }

  Future<MessageReactionResult> reactToMessage({
    required String messageId,
    required String emoji,
  }) async {
    final response = await _dio.patch(
      ApiConstants.chatMessageReaction(messageId),
      data: {'emoji': emoji},
    );
    return MessageReactionResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<String> uploadChatFile(
    String conversationId,
    MultipartFile file,
  ) async {
    final formData = FormData.fromMap({'file': file});
    final response = await _dio.post(
      ApiConstants.chatUploadFile(conversationId),
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return (response.data as Map<String, dynamic>)['key'] as String;
  }

  // ── User search (for new conversation picker) ──────────────────────────────

  Future<List<UserSearchResult>> searchUsers({String? query}) async {
    return searchUsersWithFilters(query: query);
  }

  Future<List<UserSearchResult>> searchUsersWithFilters({
    String? query,
    String? role,
    String? standardId,
    String? section,
    String? subjectId,
    String? academicYearId,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': 1,
        'page_size': 20,
        if (query != null && query.isNotEmpty) 'q': query,
        if (role != null && role.isNotEmpty) 'role': role,
        if (standardId != null && standardId.isNotEmpty)
          'standard_id': standardId,
        if (section != null && section.isNotEmpty) 'section': section,
        if (subjectId != null && subjectId.isNotEmpty) 'subject_id': subjectId,
        if (academicYearId != null && academicYearId.isNotEmpty)
          'academic_year_id': academicYearId,
      };
      final response = await _dio.get(
        ApiConstants.chatUsers,
        queryParameters: params,
      );
      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => UserSearchResult.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<UserSearchResult>> searchUsersAcrossRoles({
    String? query,
    required List<String> roles,
    String? standardId,
    String? section,
    String? subjectId,
    String? academicYearId,
  }) async {
    if (roles.isEmpty) return const <UserSearchResult>[];
    final uniqueRoles = roles
        .map((r) => r.trim().toUpperCase())
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueRoles.isEmpty) return const <UserSearchResult>[];

    final futures = uniqueRoles
        .map(
          (role) => searchUsersWithFilters(
            query: query,
            role: role,
            standardId: standardId,
            section: section,
            subjectId: subjectId,
            academicYearId: academicYearId,
          ),
        )
        .toList();

    final results = await Future.wait(futures);
    final map = <String, UserSearchResult>{};
    for (final list in results) {
      for (final user in list) {
        map.putIfAbsent(user.id, () => user);
      }
    }
    return map.values.toList();
  }

  // ── WebSocket ──────────────────────────────────────────────────────────────

  Future<WebSocketChannel?> connectToConversation(
    String conversationId,
  ) async {
    final token = await _secureStorage.readToken();
    if (token == null || token.isEmpty) return null;
    final url = ApiConstants.chatWebSocket(token, conversationId);
    try {
      return WebSocketChannel.connect(Uri.parse(url));
    } catch (_) {
      return null;
    }
  }
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(
    ref.read(dioClientProvider),
    ref.read(secureStorageProvider),
  );
});
