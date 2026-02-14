import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_status.dart';

class UserStatusService {
  static final UserStatusService instance = UserStatusService._();
  UserStatusService._();

  final _statusesRef = FirebaseFirestore.instance
      .collection('userStatuses')
      .withConverter<UserStatus>(
        fromFirestore: (doc, _) => UserStatus.fromDoc(doc),
        toFirestore: (status, _) => status.toMap(),
      );

  /// Create a new status
  Future<String> createStatus({
    required String userId,
    required String username,
    String? photoUrl,
    required String text,
    String? emoji,
    String? musicTitle,
    String? musicArtist,
    String? musicUrl,
  }) async {
    final now = DateTime.now();
    final status = UserStatus(
      id: '',
      userId: userId,
      username: username,
      photoUrl: photoUrl,
      text: text,
      emoji: emoji,
      musicTitle: musicTitle,
      musicArtist: musicArtist,
      musicUrl: musicUrl,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      seenBy: [userId],
    );

    print('[UserStatusService] Creating status: ${status.toMap()}');

    final doc = await _statusesRef.add(status);
    
    print('[UserStatusService] Status created with ID: ${doc.id}');
    return doc.id;
  }

  /// Watch active statuses from followed users
  Stream<List<UserStatus>> watchFriendsStatuses({
    required String currentUserId,
    required List<String> followingIds,
  }) {
    final now = Timestamp.fromDate(DateTime.now());

    return _statusesRef
        .where('userId', whereIn: [...followingIds, currentUserId])
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList())
        .handleError((error, stackTrace) {
      return <UserStatus>[];
    });
  }

  /// Watch current user's active status
  Stream<UserStatus?> watchMyStatus(String userId) {
    final now = Timestamp.fromDate(DateTime.now());

    return _statusesRef
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: now)
        .orderBy('expiresAt', descending: false)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.data())
        .handleError((error, stackTrace) {
      return null;
    });
  }

  /// Mark status as seen
  Future<void> markSeen({
    required String statusId,
    required String userId,
  }) async {
    final docRef = _statusesRef.doc(statusId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;
      final status = snap.data();
      if (status == null) return;

      final currentSeenBy = List<String>.from(status.seenBy);
      if (!currentSeenBy.contains(userId)) {
        currentSeenBy.add(userId);
        tx.update(docRef, {'seenBy': currentSeenBy});
      }
    });
  }

  /// Delete a status (only by owner)
  Future<void> deleteStatus({
    required String statusId,
    required String userId,
  }) async {
    final docRef = _statusesRef.doc(statusId);
    final snap = await docRef.get();
    if (!snap.exists) return;

    final status = snap.data();
    if (status == null) return;

    if (status.userId != userId) {
      throw Exception('Only the owner can delete this status');
    }

    await docRef.delete();
  }

  /// Get status count for a user
  Future<int> getStatusCount(String userId) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snap = await _statusesRef
        .where('userId', isEqualTo: userId)
        .where('expiresAt', isGreaterThan: now)
        .count()
        .get();
    return snap.count ?? 0;
  }
}
