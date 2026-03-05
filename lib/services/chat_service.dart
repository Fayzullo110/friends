import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';
import 'dart:async';

import 'auth_service.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  bool _isBackendChatId(String chatId) => int.tryParse(chatId) != null;

  // TODO: Replace with backend API reference
  // final _chatsRef = FirebaseFirestore.instance.collection('chats');

  String directChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/typing',
      body: {
        'isTyping': isTyping,
      },
    );
  }

  Stream<Map<String, bool>> watchTyping({required String chatId}) {
    if (!_isBackendChatId(chatId)) {
      return Stream.value(const <String, bool>{});
    }
    final controller = StreamController<Map<String, bool>>();
    Map<String, bool>? last;

    Future<void> tick() async {
      try {
        final ids = await AuthService.instance.api.getList('/api/chats/$chatId/typing');
        final next = <String, bool>{
          for (final id in ids) id.toString(): true,
        };
        if (last == null || !_typingEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        const empty = <String, bool>{};
        if (last == null || !_typingEqual(last!, empty)) {
          last = empty;
          controller.add(empty);
        }
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 2), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  bool _typingEqual(Map<String, bool> a, Map<String, bool> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  String selfChatId(String uid) => 'self_$uid';

  Stream<List<Chat>> watchMyChats({required String uid}) {
    final controller = StreamController<List<Chat>>();
    List<Chat>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/chats');
        final next = rows.map(Chat.fromJson).toList();
        if (last == null || !_chatsEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  /// Watches the number of chats that have an unread last message for [uid].
  ///
  /// A chat is considered "unread" if its most recent message was sent by
  /// someone else and that message's [seenBy] does not contain [uid].
  Stream<int> watchUnreadChatCount({required String uid}) {
    final controller = StreamController<int>();
    int? last;

    Future<int> fetch() async {
      final res = await AuthService.instance.api.getJson(
        '/api/chats/unread-count',
        (json) => json,
      );
      final raw = (res['count'] as num?) ?? 0;
      return raw.toInt();
    }

    Future<void> tick() async {
      try {
        final unread = await fetch();
        if (last == null || last != unread) {
          last = unread;
          controller.add(unread);
        }
      } catch (_) {
        if (last == null || last != 0) {
          last = 0;
          controller.add(0);
        }
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 12), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Stream<List<AppUser>> watchUsers({required String excludeUid}) {
    final controller = StreamController<List<AppUser>>();
    List<AppUser>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/users/recent');
        final next = rows
            .where((u) => u['id'].toString() != excludeUid)
            .map((u) => AppUser(
                  id: u['id'].toString(),
                  email: u['email'] as String? ?? '',
                  username: u['username'] as String? ?? '',
                  photoUrl: u['photoUrl'] as String?,
                ))
            .toList();
        if (last == null || !_usersEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  bool _usersEqual(List<AppUser> a, List<AppUser> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ua = a[i];
      final ub = b[i];
      if (ua.id != ub.id) return false;
      if (ua.username != ub.username) return false;
      if (ua.photoUrl != ub.photoUrl) return false;
    }
    return true;
  }

  Future<List<AppUser>> searchUsers({
    required String query,
    required String excludeUid,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return <AppUser>[];
    final rows = await AuthService.instance.api
        .getListOfMaps('/api/users/search?q=${Uri.encodeQueryComponent(q)}');
    return rows
        .where((u) => u['id'].toString() != excludeUid)
        .map((u) => AppUser(
              id: u['id'].toString(),
              email: u['email'] as String? ?? '',
              username: u['username'] as String? ?? '',
              photoUrl: u['photoUrl'] as String?,
            ))
        .toList();
  }

  Future<List<ChatMessage>> fetchMessagesPage({
    required String chatId,
    int limit = 100,
    int offset = 0,
  }) async {
    if (!_isBackendChatId(chatId)) {
      return const <ChatMessage>[];
    }

    final safeLimit = limit < 1 ? 1 : (limit > 200 ? 200 : limit);
    final safeOffset = offset < 0 ? 0 : offset;

    final rows = await AuthService.instance.api.getListOfMaps(
      '/api/chats/$chatId/messages?limit=$safeLimit&offset=$safeOffset',
    );
    return rows.map(ChatMessage.fromJson).toList();
  }

  Stream<List<ChatMessage>> watchMessages({
    required String chatId,
    int limit = 100,
    int offset = 0,
    Duration pollInterval = const Duration(seconds: 6),
  }) {
    if (!_isBackendChatId(chatId)) {
      return Stream.value(const <ChatMessage>[]);
    }
    final controller = StreamController<List<ChatMessage>>();
    List<ChatMessage>? last;

    Future<void> tick() async {
      try {
        final next = await fetchMessagesPage(
          chatId: chatId,
          limit: limit,
          offset: offset,
        );
        if (last == null || !_messagesEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        // swallow
      }
    }

    tick();
    final timer = Timer.periodic(pollInterval, (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  bool _messagesEqual(List<ChatMessage> a, List<ChatMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ma = a[i];
      final mb = b[i];
      if (ma.id != mb.id) return false;
      if (ma.text != mb.text) return false;
      if (ma.type != mb.type) return false;
      if (ma.mediaUrl != mb.mediaUrl) return false;
      if (ma.seenBy.length != mb.seenBy.length) return false;
    }
    return true;
  }

  bool _chatsEqual(List<Chat> a, List<Chat> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ca = a[i];
      final cb = b[i];
      if (ca.id != cb.id) return false;
      if (ca.lastMessage != cb.lastMessage) return false;
      if (ca.updatedAt.millisecondsSinceEpoch != cb.updatedAt.millisecondsSinceEpoch) {
        return false;
      }
    }
    return true;
  }

  Future<String> createOrGetDirectChat({
    required AppUser me,
    required AppUser other,
  }) async {
    final otherId = int.parse(other.id);
    final chat = await AuthService.instance.api.postJson(
      '/api/chats/direct/$otherId',
      const {},
      (json) => Chat.fromJson(json),
    );
    return chat.id;
  }

  Future<String> createOrGetSelfChat({
    required AppUser me,
  }) async {
    // Backend does not implement explicit self chat; reuse direct with yourself not allowed.
    return selfChatId(me.id);
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/messages',
      body: {
        'type': 'text',
        'text': trimmed,
      },
    );
  }

  Future<void> sendGif({
    required String chatId,
    required String senderId,
    required String gifUrl,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    if (gifUrl.isEmpty) return;
    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/messages',
      body: {
        'type': 'gif',
        'mediaUrl': gifUrl,
      },
    );
    //       createdAt: DateTime.now(),
    //       reactions: {},
    //       seenBy: [senderId],
    //     ).toMap(),
    //   );
    //   tx.update(chatRef, {
    //     'lastMessage': 'GIF',
    //     'updatedAt': FieldValue.serverTimestamp(),
    //   });
    // });
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await _sendMedia(
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.image,
      mediaUrl: imageUrl,
      lastMessageLabel: 'Photo',
    );
  }

  Future<void> sendVideo({
    required String chatId,
    required String senderId,
    required String videoUrl,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await _sendMedia(
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.video,
      mediaUrl: videoUrl,
      lastMessageLabel: 'Video',
    );
  }

  Future<void> sendFile({
    required String chatId,
    required String senderId,
    required String fileUrl,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await _sendMedia(
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.file,
      mediaUrl: fileUrl,
      lastMessageLabel: 'File',
    );
  }

  Future<void> sendVoice({
    required String chatId,
    required String senderId,
    required String audioUrl,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await _sendMedia(
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.voice,
      mediaUrl: audioUrl,
      lastMessageLabel: 'Voice message',
    );
  }

  Future<void> markMessagesSeen({
    required String chatId,
    required List<String> messageIds,
    required String userId,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    if (messageIds.isEmpty) return;

    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/messages/seen',
      body: {
        'messageIds': messageIds.map((e) => int.parse(e)).toList(),
      },
    );
  }

  Future<String> createGroupChat({
    required AppUser me,
    required List<AppUser> others,
    required String title,
  }) async {
    final memberIds = <int>{int.parse(me.id)};
    for (final u in others) {
      memberIds.add(int.parse(u.id));
    }
    final chat = await AuthService.instance.api.postJson(
      '/api/chats/group',
      {
        'title': title,
        'memberIds': memberIds.where((id) => id != int.parse(me.id)).toList(),
      },
      (json) => Chat.fromJson(json),
    );
    return chat.id;
  }

  Future<void> _sendMedia({
    required String chatId,
    required String senderId,
    required ChatMessageType type,
    required String mediaUrl,
    required String lastMessageLabel,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    if (mediaUrl.isEmpty) return;

    String typeStr = 'text';
    if (type == ChatMessageType.gif) typeStr = 'gif';
    if (type == ChatMessageType.voice) typeStr = 'voice';
    if (type == ChatMessageType.video) typeStr = 'video';
    if (type == ChatMessageType.image) typeStr = 'image';
    if (type == ChatMessageType.file) typeStr = 'file';

    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/messages',
      body: {
        'type': typeStr,
        'mediaUrl': mediaUrl,
      },
    );
    // final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    // final chatRef = _chatsRef.doc(chatId);

    // await FirebaseFirestore.instance.runTransaction((tx) async {
    //   tx.set(
    //     msgRef,
    //     ChatMessage(
    //       id: msgRef.id,
    //       senderId: senderId,
    //       senderUsername: '', // TODO: get from backend
    //       type: type,
    //       text: '',
    //       mediaUrl: mediaUrl,
    //       createdAt: DateTime.now(),
    //       reactions: const {},
    //       seenBy: const [],
    //     ).toMap(),
    //   );
    //   tx.update(chatRef, {
    //     'lastMessage': lastMessageLabel,
    //     'updatedAt': FieldValue.serverTimestamp(),
    //   });
    // });
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    if (!_isBackendChatId(chatId)) return;
    await AuthService.instance.api.postNoContent(
      '/api/chats/$chatId/messages/$messageId/reactions/${Uri.encodeComponent(emoji)}',
    );
    // final msgRef =
    //     _chatsRef.doc(chatId).collection('messages').doc(messageId);

    // await FirebaseFirestore.instance.runTransaction((tx) async {
    //   final snap = await tx.get(msgRef);
    //   if (!snap.exists) return;

    //   final data = snap.data()!;
    //   final reactions = ChatMessage._decodeReactions(data['reactions'] ?? {});

    //   final userReactions = reactions[emoji] ?? [];
    //   if (userReactions.contains(userId)) {
    //     userReactions.remove(userId);
    //   } else {
    //     userReactions.add(userId);
    //   }
    //   reactions[emoji] = userReactions;

    //   await tx.update(msgRef, {'reactions': ChatMessage._encodeReactions(reactions)});
    // });
  }
}
