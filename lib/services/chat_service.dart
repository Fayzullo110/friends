import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/chat.dart';
import '../models/chat_message.dart';

class ChatService {
  ChatService._();

  static final ChatService instance = ChatService._();

  final _chatsRef = FirebaseFirestore.instance.collection('chats');

  String directChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  String selfChatId(String uid) => 'self_$uid';

  Stream<List<Chat>> watchMyChats({required String uid}) {
    return _chatsRef
        .where('members', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Chat.fromDoc(d)).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  /// Watches the number of chats that have an unread last message for [uid].
  ///
  /// A chat is considered "unread" if its most recent message was sent by
  /// someone else and that message's [seenBy] does not contain [uid].
  Stream<int> watchUnreadChatCount({required String uid}) {
    return _chatsRef
        .where('members', arrayContains: uid)
        .snapshots()
        .asyncMap((snap) async {
      int count = 0;

      for (final chatDoc in snap.docs) {
        final messagesSnap = await chatDoc.reference
            .collection('messages')
            .orderBy('createdAt', descending: true)
            .limit(1)
            .get();

        if (messagesSnap.docs.isEmpty) continue;

        final msg = ChatMessage.fromDoc(messagesSnap.docs.first);
        if (msg.senderId != uid && !msg.seenBy.contains(uid)) {
          count++;
        }
      }

      return count;
    }).handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Stream<List<AppUser>> watchUsers({required String excludeUid}) {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map(
          (snap) => snap.docs
              .where((d) => d.id != excludeUid)
              .map((d) => AppUser.fromDoc(d))
              .toList(),
        )
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Stream<List<ChatMessage>> watchMessages({required String chatId}) {
    return _chatsRef
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d)).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<String> createOrGetDirectChat({
    required AppUser me,
    required AppUser other,
  }) async {
    final chatId = directChatId(me.id, other.id);
    final docRef = _chatsRef.doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists) return;

      tx.set(docRef, {
        'members': [me.id, other.id],
        'memberUsernames': {
          me.id: me.username,
          other.id: other.username,
        },
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return chatId;
  }

   Future<String> createOrGetSelfChat({
    required AppUser me,
  }) async {
    final chatId = selfChatId(me.id);
    final docRef = _chatsRef.doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists) return;

      tx.set(docRef, {
        'members': [me.id],
        'memberUsernames': {
          me.id: me.username,
        },
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return chatId;
  }

  Future<void> sendText({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    final chatRef = _chatsRef.doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: senderId,
          type: ChatMessageType.text,
          text: trimmed,
          mediaUrl: null,
          createdAt: DateTime.now(),
          reactions: const {},
          seenBy: const [],
        ).toMap(),
      );

      tx.set(
        chatRef,
        {
          'lastMessage': trimmed,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> sendGif({
    required String chatId,
    required String senderId,
    required String gifUrl,
  }) async {
    final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    final chatRef = _chatsRef.doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: senderId,
          type: ChatMessageType.gif,
          text: '',
          mediaUrl: gifUrl,
          createdAt: DateTime.now(),
          reactions: const {},
          seenBy: const [],
        ).toMap(),
      );

      tx.set(
        chatRef,
        {
          'lastMessage': 'GIF',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> sendImage({
    required String chatId,
    required String senderId,
    required String imageUrl,
  }) async {
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
    await _sendMedia(
      chatId: chatId,
      senderId: senderId,
      type: ChatMessageType.voice,
      mediaUrl: audioUrl,
      lastMessageLabel: 'Voice message',
    );
  }

  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    final chatRef = _chatsRef.doc(chatId);
    if (isTyping) {
      await chatRef.set({
        'typing': {userId: true},
      }, SetOptions(merge: true));
    } else {
      await chatRef.set({
        'typing': {userId: FieldValue.delete()},
      }, SetOptions(merge: true));
    }
  }

  Future<void> markMessagesSeen({
    required String chatId,
    required List<String> messageIds,
    required String userId,
  }) async {
    if (messageIds.isEmpty) return;

    final chatRef = _chatsRef.doc(chatId);
    final batch = FirebaseFirestore.instance.batch();

    for (final id in messageIds) {
      final msgRef = chatRef.collection('messages').doc(id);
      batch.update(msgRef, {
        'seenBy': FieldValue.arrayUnion([userId]),
      });
    }

    await batch.commit();
  }

  Future<String> createGroupChat({
    required AppUser me,
    required List<AppUser> others,
    required String title,
  }) async {
    // Ensure current user is included and no duplicates.
    final allUsersById = <String, AppUser>{
      for (final u in [me, ...others]) u.id: u,
    };

    final memberIds = allUsersById.keys.toList();
    final memberUsernames = <String, String>{
      for (final entry in allUsersById.entries) entry.key: entry.value.username,
    };

    final docRef = _chatsRef.doc();

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (snap.exists) return;

      tx.set(docRef, {
        'members': memberIds,
        'memberUsernames': memberUsernames,
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'isGroup': true,
        'title': title,
      });
    });

    return docRef.id;
  }

  Future<void> _sendMedia({
    required String chatId,
    required String senderId,
    required ChatMessageType type,
    required String mediaUrl,
    required String lastMessageLabel,
  }) async {
    final msgRef = _chatsRef.doc(chatId).collection('messages').doc();
    final chatRef = _chatsRef.doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.set(
        msgRef,
        ChatMessage(
          id: msgRef.id,
          senderId: senderId,
          type: type,
          text: '',
          mediaUrl: mediaUrl,
          createdAt: DateTime.now(),
          reactions: const {},
          seenBy: const [],
        ).toMap(),
      );

      tx.set(
        chatRef,
        {
          'lastMessage': lastMessageLabel,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> toggleReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final msgRef =
        _chatsRef.doc(chatId).collection('messages').doc(messageId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(msgRef);
      if (!snap.exists) return;

      final data = snap.data() ?? <String, dynamic>{};
      final reactionsRaw = data['reactions'] as Map<String, dynamic>? ?? {};

      final currentList = List<String>.from(
        (reactionsRaw[emoji] as List<dynamic>? ?? const []),
      );

      if (currentList.contains(userId)) {
        currentList.remove(userId);
      } else {
        currentList.add(userId);
      }

      final updated = Map<String, dynamic>.from(reactionsRaw);
      if (currentList.isEmpty) {
        updated.remove(emoji);
      } else {
        updated[emoji] = currentList;
      }

      tx.update(msgRef, {'reactions': updated});
    });
  }
}
