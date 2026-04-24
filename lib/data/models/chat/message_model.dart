enum MessageType {
  text,
  image,
  file,
  audio,
}

extension MessageTypeX on MessageType {
  static MessageType fromString(String? value) {
    switch ((value ?? '').toUpperCase()) {
      case 'IMAGE':
        return MessageType.image;
      case 'FILE':
        return MessageType.file;
      case 'AUDIO':
        return MessageType.audio;
      default:
        return MessageType.text;
    }
  }

  String get backendValue {
    switch (this) {
      case MessageType.text:
        return 'TEXT';
      case MessageType.image:
        return 'IMAGE';
      case MessageType.file:
        return 'FILE';
      case MessageType.audio:
        return 'AUDIO';
    }
  }

  bool get isMedia => this == MessageType.image;
  bool get isFile => this == MessageType.file;
}

class MessageModel {
  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.messageType,
    required this.sentAt,
    required this.schoolId,
    this.content,
    this.fileKey,
    this.reactions = const [],
    this.myReaction,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final String? fileKey;
  final DateTime sentAt;
  final String schoolId;
  final List<MessageReactionSummary> reactions;
  final String? myReaction;

  bool isMine(String currentUserId) => senderId == currentUserId;

  bool get hasFile => fileKey != null && fileKey!.isNotEmpty;

  String get displayPreview {
    if (content != null && content!.isNotEmpty) return content!;
    switch (messageType) {
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.audio:
        return '🎵 Audio';
      case MessageType.text:
        return '';
    }
  }

  /// From REST paginated response — full shape.
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final sentAtStr = (json['sent_at'] ?? json['created_at']) as String;
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageTypeX.fromString(json['message_type'] as String?),
      fileKey: json['file_key'] as String?,
      sentAt: DateTime.parse(sentAtStr).toLocal(),
      schoolId: json['school_id'] as String? ?? '',
      reactions: ((json['reactions'] as List<dynamic>?) ?? const [])
          .map(
              (e) => MessageReactionSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      myReaction: json['my_reaction'] as String?,
    );
  }

  /// From WebSocket broadcast — stripped shape:
  /// {id, conversation_id, sender_id, content, message_type, file_key, sent_at}
  /// Note: no school_id, no created_at/updated_at.
  factory MessageModel.fromWsJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageTypeX.fromString(json['message_type'] as String?),
      fileKey: json['file_key'] as String?,
      sentAt: DateTime.parse(json['sent_at'] as String).toLocal(),
      schoolId: '',
      reactions: const [],
      myReaction: null,
    );
  }

  MessageModel copyWith({
    String? content,
    String? fileKey,
    List<MessageReactionSummary>? reactions,
    String? myReaction,
    bool clearMyReaction = false,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content ?? this.content,
      messageType: messageType,
      fileKey: fileKey ?? this.fileKey,
      sentAt: sentAt,
      schoolId: schoolId,
      reactions: reactions ?? this.reactions,
      myReaction: clearMyReaction ? null : (myReaction ?? this.myReaction),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MessageModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class MessageReactionSummary {
  const MessageReactionSummary({
    required this.emoji,
    required this.count,
  });

  final String emoji;
  final int count;

  factory MessageReactionSummary.fromJson(Map<String, dynamic> json) {
    return MessageReactionSummary(
      emoji: (json['emoji'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'emoji': emoji,
        'count': count,
      };
}
