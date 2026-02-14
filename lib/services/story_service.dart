import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/story.dart';
import '../models/story_comment.dart';

class StoryService {
  StoryService._();

  static final StoryService instance = StoryService._();

  final _storiesRef = FirebaseFirestore.instance
      .collection('stories')
      .withConverter<Story>(
        fromFirestore: (doc, _) => Story.fromDoc(doc),
        toFirestore: (story, _) => story.toMap(),
      );

  final _commentsRef = FirebaseFirestore.instance
      .collection('storyComments')
      .withConverter<StoryComment>(
        fromFirestore: (doc, _) => StoryComment.fromDoc(doc),
        toFirestore: (comment, _) => comment.toMap(),
      );

  /// Watch all non-expired stories ordered by creation time.
  Stream<List<Story>> watchActiveStories() {
    final now = DateTime.now();
    return _storiesRef
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  /// Watch all non-expired stories for a single author.
  Stream<List<Story>> watchUserStories({required String authorId}) {
    final now = DateTime.now();
    return _storiesRef
        .where('authorId', isEqualTo: authorId)
        .where('expiresAt', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('expiresAt')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<void> createTextStory({
    required String authorId,
    required String authorUsername,
    required String text,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final story = Story(
      id: '',
      authorId: authorId,
      authorUsername: authorUsername,
      mediaUrl: null,
      mediaType: 'text',
      text: text,
      createdAt: now,
      expiresAt: expiresAt,
      seenBy: const [],
      musicTitle: musicTitle,
      musicArtist: musicArtist,
      musicUrl: musicUrl,
    );

    await _storiesRef.add(story);
  }

  Future<void> createMediaStory({
    required String authorId,
    required String authorUsername,
    required String mediaUrl,
    required String mediaType, // 'image', 'video', or 'gif'
    String? text,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final story = Story(
      id: '',
      authorId: authorId,
      authorUsername: authorUsername,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      text: text,
      createdAt: now,
      expiresAt: expiresAt,
      seenBy: const [],
      musicTitle: musicTitle,
      musicArtist: musicArtist,
      musicUrl: musicUrl,
    );

    await _storiesRef.add(story);
  }

  Future<void> markSeen({
    required String storyId,
    required String userId,
  }) async {
    final docRef = _storiesRef.doc(storyId).withConverter(
          fromFirestore: (doc, _) => Story.fromDoc(doc),
          toFirestore: (story, _) => story.toMap(),
        );

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final story = snap.data();
      if (story == null) return;

      if (story.seenBy.contains(userId)) {
        return;
      }

      final updatedSeenBy = List<String>.from(story.seenBy)..add(userId);

      tx.update(docRef, {
        'seenBy': updatedSeenBy,
      });
    });
  }

  /// Toggle like on a story (like if not liked, unlike if already liked)
  Future<void> toggleLike({
    required String storyId,
    required String userId,
  }) async {
    final docRef = _storiesRef.doc(storyId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final story = snap.data();
      if (story == null) return;

      final currentLikedBy = List<String>.from(story.likedBy);
      if (currentLikedBy.contains(userId)) {
        currentLikedBy.remove(userId);
      } else {
        currentLikedBy.add(userId);
      }

      tx.update(docRef, {'likedBy': currentLikedBy});
    });
  }

  /// Watch comments for a specific story
  Stream<List<StoryComment>> watchStoryComments({required String storyId}) {
    return _commentsRef
        .where('storyId', isEqualTo: storyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable
    });
  }

  /// Add a comment to a story
  Future<void> addComment({
    required String storyId,
    required String authorId,
    required String authorUsername,
    required String text,
  }) async {
    final comment = StoryComment(
      id: '',
      storyId: storyId,
      authorId: authorId,
      authorUsername: authorUsername,
      text: text.trim(),
      createdAt: DateTime.now(),
    );

    await _commentsRef.add(comment);
  }

  /// Delete a comment (only the author can delete)
  Future<void> deleteComment({
    required String commentId,
    required String userId,
  }) async {
    final docRef = _commentsRef.doc(commentId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final comment = snap.data();
    if (comment == null) return;

    if (comment.authorId != userId) {
      throw Exception('Only the author can delete this comment');
    }

    await docRef.delete();
  }
}
