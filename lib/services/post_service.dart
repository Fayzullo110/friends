import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/post.dart';

class PostService {
  PostService._();

  static final PostService instance = PostService._();

  final _postsRef =
      FirebaseFirestore.instance.collection('posts').withConverter<Post>(
            fromFirestore: (doc, _) => Post.fromDoc(doc),
            toFirestore: (post, _) => post.toMap(),
          );

  Stream<List<Post>> watchRecentPosts() {
    return _postsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        // Swallow Firestore "offline" errors so the UI can stay up even if
        // the client temporarily can't reach the backend.
        .handleError((error, stackTrace) {
      // Intentionally no rethrow: listeners will just keep the last good data
      // (or an empty list) instead of crashing the app.
    });
  }

  Future<void> createTextPost({
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final post = Post(
      id: '',
      authorId: authorId,
      authorUsername: authorUsername,
      text: text,
      createdAt: DateTime.now(),
      mediaType: 'text',
    );
    await _postsRef.add(post);
  }

  Future<void> createMediaPost({
    required String authorId,
    required String authorUsername,
    required String text,
    required String mediaUrl,
    required String mediaType, // 'image' or 'video'
  }) async {
    final post = Post(
      id: '',
      authorId: authorId,
      authorUsername: authorUsername,
      text: text,
      createdAt: DateTime.now(),
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
    await _postsRef.add(post);
  }

  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists) return;
        final data = snap.data();
        final likedBy = List<String>.from(
          (data?['likedBy'] as List<dynamic>? ?? const []).map((e) => e as String),
        );

        if (likedBy.contains(userId)) {
          likedBy.remove(userId);
        } else {
          likedBy.add(userId);
        }

        final likeCount = likedBy.length;

        tx.update(docRef, {
          'likedBy': likedBy,
          'likeCount': likeCount,
        });
      });
    } on FirebaseException catch (e) {
      // When the client is offline or Firestore is temporarily unavailable,
      // ignore the error so tapping like doesn't crash the app.
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> setPinnedComment({
    required String postId,
    String? commentId,
  }) async {
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    try {
      await docRef.update({'pinnedCommentId': commentId});
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> incrementShareCount({required String postId}) async {
    final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    try {
      await docRef.update({'shareCount': FieldValue.increment(1)});
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> repost({
    required String sourcePostId,
    required String newAuthorId,
    required String newAuthorUsername,
  }) async {
    final sourceRef = FirebaseFirestore.instance.collection('posts').doc(sourcePostId);
    final snap = await sourceRef.get();
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};

    final repost = Post(
      id: '',
      authorId: newAuthorId,
      authorUsername: newAuthorUsername,
      text: data['text'] as String? ?? '',
      createdAt: DateTime.now(),
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'text',
    );

    await _postsRef.add(repost);

    await incrementShareCount(postId: sourcePostId);
  }
}
