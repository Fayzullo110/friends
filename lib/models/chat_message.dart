import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatMessageType { text, gif, voice, video, image, file }

class ChatMessage {
  final String id;
  final String senderId;
  final ChatMessageType type;
  final String text;
  final String? mediaUrl;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;
  final List<String> seenBy;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.text,
    this.mediaUrl,
    required this.createdAt,
    required this.reactions,
    required this.seenBy,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final typeStr = data['type'] as String? ?? 'text';

    ChatMessageType type;
    switch (typeStr) {
      case 'gif':
        type = ChatMessageType.gif;
        break;
      case 'voice':
        type = ChatMessageType.voice;
        break;
      case 'video':
        type = ChatMessageType.video;
        break;
      case 'image':
        type = ChatMessageType.image;
        break;
      case 'file':
        type = ChatMessageType.file;
        break;
      default:
        type = ChatMessageType.text;
    }

    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      type: type,
      text: data['text'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: _decodeReactions(data['reactions']),
      seenBy: (data['seenBy'] as List<dynamic>? ?? const [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
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
      'senderId': senderId,
      'type': typeStr,
      'text': text,
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'reactions': _encodeReactions(reactions),
      'seenBy': seenBy,
    };
  }

  static Map<String, List<String>> _decodeReactions(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return raw.map((key, value) {
        final list = (value as List<dynamic>? ?? const [])
            .map((e) => e as String)
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
}
