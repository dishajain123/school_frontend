import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../data/models/chat/conversation_model.dart';
import '../data/models/chat/message_model.dart';
import '../data/repositories/chat_repository.dart';

// ── Conversation List ─────────────────────────────────────────────────────────

class ConversationNotifier
    extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    return _fetch();
  }

  Future<List<ConversationModel>> _fetch() async {
    final repo = ref.read(chatRepositoryProvider);
    return repo.listConversations();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Returns the conversation (existing or newly created).
  Future<ConversationModel?> startOneToOne(String participantId) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.createConversation(
        type: ConversationType.oneToOne.backendValue,
        participantIds: [participantId],
      );
      _upsert(conversation);
      return conversation;
    } catch (e) {
      rethrow;
    }
  }

  Future<ConversationModel?> createGroup({
    required String name,
    required List<String> participantIds,
    String? standardId,
    String? academicYearId,
  }) async {
    try {
      final repo = ref.read(chatRepositoryProvider);
      final conversation = await repo.createConversation(
        type: ConversationType.group.backendValue,
        participantIds: participantIds,
        name: name,
        standardId: standardId,
        academicYearId: academicYearId,
      );
      _upsert(conversation);
      return conversation;
    } catch (e) {
      rethrow;
    }
  }

  void _upsert(ConversationModel conversation) {
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((c) => c.id == conversation.id);
    if (idx == -1) {
      state = AsyncData([conversation, ...current]);
    } else {
      final updated = [...current];
      updated[idx] = conversation;
      state = AsyncData(updated);
    }
  }
}

final conversationNotifierProvider =
    AsyncNotifierProvider<ConversationNotifier, List<ConversationModel>>(
  ConversationNotifier.new,
);

// ── Chat Room State ───────────────────────────────────────────────────────────

class ChatRoomState {
  const ChatRoomState({
    this.messages = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.isConnected = false,
    this.isSending = false,
    this.error,
  });

  /// Messages stored newest-first (index 0 = newest).
  /// With ListView(reverse: true), index 0 renders at the bottom — newest at bottom ✓
  final List<MessageModel> messages;
  final int total;
  final int page;
  final int totalPages;
  final bool isLoadingMore;
  final bool isConnected;
  final bool isSending;
  final String? error;

  bool get hasMore => page <= totalPages;

  ChatRoomState copyWith({
    List<MessageModel>? messages,
    int? total,
    int? page,
    int? totalPages,
    bool? isLoadingMore,
    bool? isConnected,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isConnected: isConnected ?? this.isConnected,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Chat Room Notifier ────────────────────────────────────────────────────────

class ChatRoomNotifier
    extends AutoDisposeFamilyAsyncNotifier<ChatRoomState, String> {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _wsSub;
  bool _disposed = false;

  @override
  Future<ChatRoomState> build(String conversationId) async {
    ref.onDispose(_cleanup);

    final result = await _loadPage(conversationId, page: 1);
    // Connect WS after initial messages loaded
    _connectWs(conversationId);
    return result;
  }

  Future<ChatRoomState> _loadPage(
    String conversationId, {
    required int page,
  }) async {
    final repo = ref.read(chatRepositoryProvider);
    final result = await repo.listMessages(conversationId, page: page);
    // API returns newest-first; keep that order (index 0 = newest = bottom of chat)
    return ChatRoomState(
      messages: result.items,
      total: result.total,
      page: result.page + 1,
      totalPages: result.totalPages,
    );
  }

  Future<void> _connectWs(String conversationId) async {
    if (_disposed) return;
    try {
      final repo = ref.read(chatRepositoryProvider);
      _channel = await repo.connectToConversation(conversationId);
      if (_channel == null || _disposed) return;

      _updateState((s) => s.copyWith(isConnected: true));

      _wsSub = _channel!.stream.listen(
        (raw) {
          if (_disposed) return;
          try {
            final json = jsonDecode(raw as String) as Map<String, dynamic>;
            final incoming = MessageModel.fromWsJson(json);
            final cur = state.valueOrNull ?? const ChatRoomState();
            if (!cur.messages.any((m) => m.id == incoming.id)) {
              // Prepend: newest-first → new message at index 0 (bottom)
              _updateState((s) => s.copyWith(
                    messages: [incoming, ...s.messages],
                    total: s.total + 1,
                  ));
            }
          } catch (_) {}
        },
        onDone: () => _updateState((s) => s.copyWith(isConnected: false)),
        onError: (_) => _updateState((s) => s.copyWith(isConnected: false)),
        cancelOnError: false,
      );
    } catch (_) {
      _updateState((s) => s.copyWith(isConnected: false));
    }
  }

  void _updateState(ChatRoomState Function(ChatRoomState) updater) {
    if (_disposed) return;
    final cur = state.valueOrNull ?? const ChatRoomState();
    state = AsyncData(updater(cur));
  }

  void _cleanup() {
    _disposed = true;
    _wsSub?.cancel();
    _channel?.sink.close();
    _wsSub = null;
    _channel = null;
  }

  // ── Public Methods ─────────────────────────────────────────────────────────

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.isLoadingMore) return;

    _updateState((s) => s.copyWith(isLoadingMore: true));
    try {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.listMessages(arg, page: cur.page);
      final olderMessages = result.items;
      // Append older messages at the end (higher index = top of reversed list)
      _updateState((s) => s.copyWith(
            messages: [...s.messages, ...olderMessages],
            page: result.page + 1,
            totalPages: result.totalPages,
            total: result.total,
            isLoadingMore: false,
          ));
    } catch (_) {
      _updateState((s) => s.copyWith(isLoadingMore: false));
    }
  }

  Future<bool> sendText(String content) async {
    final text = content.trim();
    if (text.isEmpty) return false;
    final cur = state.valueOrNull;
    if (cur == null) return false;

    if (!cur.isConnected || _channel == null) {
      _updateState(
          (s) => s.copyWith(error: 'Not connected. Reconnecting…'));
      _connectWs(arg); // attempt reconnect
      return false;
    }

    try {
      _channel!.sink.add(jsonEncode({
        'content': text,
        'message_type': MessageType.text.backendValue,
      }));
      return true;
    } catch (e) {
      _updateState((s) => s.copyWith(error: 'Failed to send message.'));
      return false;
    }
  }

  Future<bool> sendFile({
    required String filePath,
    required String fileName,
    required MessageType messageType,
  }) async {
    final cur = state.valueOrNull;
    if (cur == null) return false;
    _updateState((s) => s.copyWith(isSending: true, clearError: true));

    try {
      final repo = ref.read(chatRepositoryProvider);
      final multipart =
          await MultipartFile.fromFile(filePath, filename: fileName);
      final fileKey = await repo.uploadChatFile(arg, multipart);

      if (!cur.isConnected || _channel == null) {
        _updateState((s) =>
            s.copyWith(isSending: false, error: 'Not connected.'));
        return false;
      }

      _channel!.sink.add(jsonEncode({
        'message_type': messageType.backendValue,
        'file_key': fileKey,
      }));
      _updateState((s) => s.copyWith(isSending: false));
      return true;
    } catch (_) {
      _updateState((s) =>
          s.copyWith(isSending: false, error: 'Failed to send file.'));
      return false;
    }
  }

  Future<void> markAllRead() async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    try {
      final unreadIds = cur.messages.map((m) => m.id).toList();
      if (unreadIds.isEmpty) return;
      await ref.read(chatRepositoryProvider).markRead(arg, unreadIds);
    } catch (_) {}
  }

  Future<void> reconnect() async {
    _cleanup();
    _disposed = false;
    _connectWs(arg);
  }

  void clearError() =>
      _updateState((s) => s.copyWith(clearError: true));
}

final chatRoomProvider = AsyncNotifierProvider.autoDispose
    .family<ChatRoomNotifier, ChatRoomState, String>(
  ChatRoomNotifier.new,
);