import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import 'notification_service.dart';
import 'block_service.dart';

class FollowService {
  FollowService._();

  static final FollowService instance = FollowService._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _followersRef(String uid) {
    return _firestore.collection('followers').doc(uid).collection('items');
  }

  CollectionReference<Map<String, dynamic>> _followingRef(String uid) {
    return _firestore.collection('following').doc(uid).collection('items');
  }

  Stream<List<String>> watchFollowers({required String uid}) {
    return _followersRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['userId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }

  Stream<List<String>> watchFollowing({required String uid}) {
    return _followingRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['userId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }

  Future<void> follow({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    // Do not allow follow if there is a block in either direction.
    final hasBlocked = await BlockService.instance.isBlocked(
      fromUserId: fromUserId,
      toUserId: toUserId,
    );
    final isBlockedByOther = await BlockService.instance.isBlocked(
      fromUserId: toUserId,
      toUserId: fromUserId,
    );

    if (hasBlocked || isBlockedByOther) {
      throw Exception('blocked');
    }

    final followersRef = _followersRef(toUserId).doc(fromUserId);
    final followingRef = _followingRef(fromUserId).doc(toUserId);

    await _firestore.runTransaction((tx) async {
      tx.set(followersRef, {
        'userId': fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(followingRef, {
        'userId': toUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    // Best-effort notification for the user being followed.
    try {
      final doc = await _firestore.collection('users').doc(fromUserId).get();
      final data = doc.data() ?? const <String, dynamic>{};
      final fromUsername = (data['username'] as String?) ?? '';

      await NotificationService.instance.createNotification(
        toUserId: toUserId,
        type: AppNotificationType.follow,
        fromUserId: fromUserId,
        fromUsername: fromUsername.isEmpty ? 'Someone' : fromUsername,
      );
    } on FirebaseException catch (_) {
      // If notifications fail (e.g. offline), silently ignore.
    }
  }

  Future<void> unfollow({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    final followersRef = _followersRef(toUserId).doc(fromUserId);
    final followingRef = _followingRef(fromUserId).doc(toUserId);

    await _firestore.runTransaction((tx) async {
      tx.delete(followersRef);
      tx.delete(followingRef);
    });
  }

  Stream<bool> watchIsFollowing({
    required String fromUserId,
    required String toUserId,
  }) {
    if (fromUserId.isEmpty || toUserId.isEmpty) {
      return Stream.value(false);
    }
    return _followingRef(fromUserId).doc(toUserId).snapshots().map((doc) => doc.exists);
  }

  Future<bool> isFollowing({
    required String fromUserId,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return false;
    final doc = await _followingRef(fromUserId).doc(toUserId).get();
    return doc.exists;
  }
}
