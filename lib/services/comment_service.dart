import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment.dart';

class CommentService {
  CommentService._();

  static final CommentService instance = CommentService._();

  CollectionReference<Map<String, dynamic>> _commentsRef(String postId) {
    return FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments');
  }

  CollectionReference<Map<String, dynamic>> _reelCommentsRef(String reelId) {
    return FirebaseFirestore.instance
        .collection('reels')
        .doc(reelId)
        .collection('comments');
  }

  Stream<List<Comment>> watchComments({required String postId}) {
    return _commentsRef(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Comment.fromDoc(d, postId: postId))
              .toList(),
        )
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    required String text,
    String? parentCommentId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final comment = Comment(
      id: '',
      postId: postId,
      authorId: authorId,
      authorUsername: authorUsername,
      text: trimmed,
      type: CommentType.text,
      mediaUrl: null,
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: const [],
      parentCommentId: parentCommentId,
      dislikeCount: 0,
      dislikedBy: const [],
    );

    try {
      await _commentsRef(postId).add(comment.toMap());

      // Increment the post's commentCount for quick display.
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Stream<List<Comment>> watchReelComments({required String reelId}) {
    return _reelCommentsRef(reelId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Comment.fromDoc(d, postId: reelId))
              .toList(),
        )
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<void> addReelComment({
    required String reelId,
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final comment = Comment(
      id: '',
      postId: reelId,
      authorId: authorId,
      authorUsername: authorUsername,
      text: trimmed,
      type: CommentType.text,
      mediaUrl: null,
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: const [],
      parentCommentId: null,
      dislikeCount: 0,
      dislikedBy: const [],
    );

    try {
      await _reelCommentsRef(reelId).add(comment.toMap());

      // Increment the reel's commentCount for quick display.
      await FirebaseFirestore.instance
          .collection('reels')
          .doc(reelId)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> addReelGifComment({
    required String reelId,
    required String authorId,
    required String authorUsername,
    required String gifUrl,
  }) async {
    if (gifUrl.isEmpty) return;

    final comment = Comment(
      id: '',
      postId: reelId,
      authorId: authorId,
      authorUsername: authorUsername,
      text: '',
      type: CommentType.gif,
      mediaUrl: gifUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: const [],
      parentCommentId: null,
      dislikeCount: 0,
      dislikedBy: const [],
    );

    try {
      await _reelCommentsRef(reelId).add(comment.toMap());

      await FirebaseFirestore.instance
          .collection('reels')
          .doc(reelId)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> addGifComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    required String gifUrl,
    String? parentCommentId,
  }) async {
    if (gifUrl.isEmpty) return;

    final comment = Comment(
      id: '',
      postId: postId,
      authorId: authorId,
      authorUsername: authorUsername,
      text: '',
      type: CommentType.gif,
      mediaUrl: gifUrl,
      createdAt: DateTime.now(),
      likeCount: 0,
      likedBy: const [],
      parentCommentId: parentCommentId,
      dislikeCount: 0,
      dislikedBy: const [],
    );

    try {
      await _commentsRef(postId).add(comment.toMap());

      // Increment the post's commentCount for quick display.
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .update({
        'commentCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') {
        return;
      }
      rethrow;
    }
  }

  Future<void> toggleLikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final ref = _commentsRef(postId).doc(commentId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final likedBy = List<String>.from(data['likedBy'] as List<dynamic>? ?? []);
      var likeCount = data['likeCount'] as int? ?? 0;

      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
        likeCount = likeCount > 0 ? likeCount - 1 : 0;
      } else {
        likedBy.add(userId);
        likeCount += 1;
      }

      tx.update(ref, {
        'likedBy': likedBy,
        'likeCount': likeCount,
      });
    });
  }

  Future<void> toggleDislikeComment({
    required String postId,
    required String commentId,
    required String userId,
  }) async {
    final ref = _commentsRef(postId).doc(commentId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      final dislikedBy =
          List<String>.from(data['dislikedBy'] as List<dynamic>? ?? []);
      var dislikeCount = data['dislikeCount'] as int? ?? 0;

      if (dislikedBy.contains(userId)) {
        dislikedBy.remove(userId);
        dislikeCount = dislikeCount > 0 ? dislikeCount - 1 : 0;
      } else {
        dislikedBy.add(userId);
        dislikeCount += 1;
      }

      tx.update(ref, {
        'dislikedBy': dislikedBy,
        'dislikeCount': dislikeCount,
      });
    });
  }
}
