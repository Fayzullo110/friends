enum ChatMessageType { text, gif, voice, video, image, file }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderUsername;
  final String? senderPhotoUrl;
  final ChatMessageType type;
  final String? text;
  final String? mediaUrl;
  final String? replyToMessageId;
  final String? replyToSenderId;
  final String? replyToSenderUsername;
  final ChatMessageType? replyToType;
  final String? replyToText;
  final String? replyToMediaUrl;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final List<String> seenBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderUsername,
    this.senderPhotoUrl,
    required this.type,
    this.text,
    this.mediaUrl,
    this.replyToMessageId,
    this.replyToSenderId,
    this.replyToSenderUsername,
    this.replyToType,
    this.replyToText,
    this.replyToMediaUrl,
    required this.createdAt,
    required this.reactions,
    required this.seenBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final data = json;
    final typeStr = data['type'] as String? ?? 'text';

    return ChatMessage(
      id: data['id'].toString(),
      senderId: data['senderId'].toString(),
      senderUsername: data['senderUsername'] as String? ?? '',
      senderPhotoUrl: data['senderPhotoUrl'] as String?,
      type: _typeFromString(typeStr),
      text: data['text'] as String?,
      mediaUrl: data['mediaUrl'] as String?,
      replyToMessageId: data['replyToMessageId']?.toString(),
      replyToSenderId: data['replyToSenderId']?.toString(),
      replyToSenderUsername: data['replyToSenderUsername'] as String?,
      replyToType: data['replyToType'] == null
          ? null
          : _typeFromString(data['replyToType']?.toString()),
      replyToText: data['replyToText'] as String?,
      replyToMediaUrl: data['replyToMediaUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      reactions: _decodeReactions(data['reactions']),
      seenBy: (data['seenBy'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    String typeStr;
    switch (type) {
      case ChatMessageType.gif:
        typeStr = 'gif';
        break;
      case ChatMessageType.voice:
        typeStr = 'voice';
        break;
      case ChatMessageType.video:
        typeStr = 'video';
        break;
      case ChatMessageType.image:
        typeStr = 'image';
        break;
      case ChatMessageType.file:
        typeStr = 'file';
        break;
      case ChatMessageType.text:
        typeStr = 'text';
    }

    return {
      'id': id,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderPhotoUrl': senderPhotoUrl,
      'type': typeStr,
      'text': text,
      'mediaUrl': mediaUrl,
      'replyToMessageId': replyToMessageId,
      'replyToSenderId': replyToSenderId,
      'replyToSenderUsername': replyToSenderUsername,
      'replyToType': replyToType == null
          ? null
          : (() {
              switch (replyToType!) {
                case ChatMessageType.gif:
                  return 'gif';
                case ChatMessageType.voice:
                  return 'voice';
                case ChatMessageType.video:
                  return 'video';
                case ChatMessageType.image:
                  return 'image';
                case ChatMessageType.file:
                  return 'file';
                case ChatMessageType.text:
                  return 'text';
              }
            })(),
      'replyToText': replyToText,
      'replyToMediaUrl': replyToMediaUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'reactions': _encodeReactions(reactions),
      'seenBy': seenBy,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  static Map<String, List<String>> _decodeReactions(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) {
        final list = (value as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList();
        return MapEntry(key, list);
      });
    }
    return {};
  }

  static Map<String, List<String>> _encodeReactions(
      Map<String, List<String>> reactions) {
    return reactions.map((key, value) => MapEntry(key, List<String>.from(value)));
  }

  static ChatMessageType _typeFromString(String? value) {
    switch (value) {
      case 'gif':
        return ChatMessageType.gif;
      case 'voice':
        return ChatMessageType.voice;
      case 'video':
        return ChatMessageType.video;
      case 'image':
        return ChatMessageType.image;
      case 'file':
        return ChatMessageType.file;
      case 'text':
      default:
        return ChatMessageType.text;
    }
  }
}
