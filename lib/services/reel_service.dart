import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reel.dart';

class ReelService {
  ReelService._();

  static final ReelService instance = ReelService._();

  final _reelsRef = FirebaseFirestore.instance
      .collection('reels')
      .withConverter<Reel>(
        fromFirestore: (doc, _) => Reel.fromDoc(doc),
        toFirestore: (reel, _) => reel.toMap(),
      );

  Stream<List<Reel>> watchReels() {
    return _reelsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<void> createTextReel({
    required String authorId,
    required String authorUsername,
    required String caption,
  }) async {
    final now = DateTime.now();
    final reel = Reel(
      id: '',
      authorId: authorId,
      authorUsername: authorUsername,
      caption: caption,
      mediaUrl: null,
      mediaType: 'text',
      likeCount: 0,
      commentCount: 0,
      createdAt: now,
    );

    await _reelsRef.add(reel);
  }

  Future<void> toggleLike({
    required String reelId,
    required String userId,
  }) async {
    final ref = FirebaseFirestore.instance.collection('reels').doc(reelId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data();
      final likedBy = List<String>.from(
        (data?['likedBy'] as List<dynamic>? ?? const []).map((e) => e as String),
      );
      var likeCount = data?['likeCount'] as int? ?? 0;

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

  Future<void> incrementShareCount({required String reelId}) async {
    final docRef = FirebaseFirestore.instance.collection('reels').doc(reelId);
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
    required String sourceReelId,
    required String newAuthorId,
    required String newAuthorUsername,
  }) async {
    final sourceRef = FirebaseFirestore.instance.collection('reels').doc(sourceReelId);
    final snap = await sourceRef.get();
    if (!snap.exists) return;

    final data = snap.data() ?? <String, dynamic>{};

    final now = DateTime.now();
    final reel = Reel(
      id: '',
      authorId: newAuthorId,
      authorUsername: newAuthorUsername,
      caption: data['caption'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String?,
      mediaType: data['mediaType'] as String? ?? 'video',
      likeCount: 0,
      commentCount: 0,
      shareCount: 0,
      createdAt: now,
    );

    await _reelsRef.add(reel);

    await incrementShareCount(reelId: sourceReelId);
  }
}
