import 'package:cloud_firestore/cloud_firestore.dart';

class BlockService {
  BlockService._();
  static final BlockService instance = BlockService._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _blockedRef(String uid) =>
      _firestore.collection('blocked').doc(uid).collection('items');

  Stream<List<String>> watchBlocked({required String uid}) =>
      _blockedRef(uid).snapshots().map(
            (snap) => snap.docs
                .map((d) => d.data()['userId'] as String? ?? '')
                .where((id) => id.isNotEmpty)
                .toList(),
          );

  Future<List<String>> getBlockedOnce({required String uid}) async {
    final snap = await _blockedRef(uid).get();
    return snap.docs
        .map((d) => d.data()['userId'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
  }

  Future<void> block({required String fromUserId, required String toUserId}) async {
    if (fromUserId == toUserId) return;
    await _blockedRef(fromUserId).doc(toUserId).set({
      'userId': toUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblock({required String fromUserId, required String toUserId}) async {
    await _blockedRef(fromUserId).doc(toUserId).delete();
  }

  Future<bool> isBlocked({
    required String fromUserId,
    required String toUserId,
  }) async {
    final snap = await _blockedRef(fromUserId).doc(toUserId).get();
    return snap.exists;
  }
}