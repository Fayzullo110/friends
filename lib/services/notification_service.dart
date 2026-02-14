import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_notification.dart';
import 'block_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .doc(uid)
        .collection('items');
  }

  Stream<List<AppNotification>> watchMyNotifications({required String uid}) {
    return _itemsRef(uid)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromDoc(d))
              .toList(),
        )
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Stream<List<AppNotification>> watchMyUnreadNotifications({
    required String uid,
  }) {
    return _itemsRef(uid)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromDoc(d))
              .toList(),
        )
        .handleError((error, stackTrace) {
      // Keep UI alive if Firestore is temporarily unavailable.
    });
  }

  Future<void> createNotification({
    required String toUserId,
    required AppNotificationType type,
    required String fromUserId,
    required String fromUsername,
    String? postId,
  }) async {
    if (toUserId.isEmpty) return;
    if (toUserId == fromUserId) return;

    // If the receiver has blocked the sender, silently skip the notification.
    final receiverBlockedSender = await BlockService.instance.isBlocked(
      fromUserId: toUserId,
      toUserId: fromUserId,
    );
    if (receiverBlockedSender) return;

    final n = AppNotification(
      id: '',
      type: type,
      fromUserId: fromUserId,
      fromUsername: fromUsername,
      postId: postId,
      createdAt: DateTime.now(),
    );

    try {
      await _itemsRef(toUserId).add(n.toMap());
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return;
      rethrow;
    }
  }

  Future<void> markAllAsRead({required String uid}) async {
    final query = await _itemsRef(uid)
        .where('isRead', isEqualTo: false)
        .limit(100)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
