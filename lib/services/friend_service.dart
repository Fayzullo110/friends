import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUsername;
  final DateTime createdAt;
  final String status; // pending, accepted, rejected

  FriendRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUsername,
    required this.createdAt,
    required this.status,
  });

  factory FriendRequest.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FriendRequest(
      id: doc.id,
      fromUserId: data['fromUserId'] as String? ?? '',
      toUserId: data['toUserId'] as String? ?? '',
      fromUsername: data['fromUsername'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUsername': fromUsername,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}

class FriendService {
  FriendService._();

  static final FriendService instance = FriendService._();

  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsRef =>
      _firestore.collection('friendRequests');

  CollectionReference<Map<String, dynamic>> _friendsRef(String uid) =>
      _firestore.collection('friends').doc(uid).collection('items');

  Future<void> sendRequest({
    required String fromUserId,
    required String fromUsername,
    required String toUserId,
  }) async {
    if (fromUserId == toUserId) return;

    final existing = await _requestsRef
        .where('fromUserId', isEqualTo: fromUserId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final req = FriendRequest(
      id: '',
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromUsername: fromUsername,
      createdAt: DateTime.now(),
      status: 'pending',
    );

    await _requestsRef.add(req.toMap());
  }

  Stream<List<FriendRequest>> watchIncoming({required String uid}) {
    return _requestsRef
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => FriendRequest.fromDoc(d)).toList());
  }

  Future<void> acceptRequest(String requestId) async {
    final reqSnap = await _requestsRef.doc(requestId).get();
    if (!reqSnap.exists) return;
    final req = FriendRequest.fromDoc(reqSnap);

    await _firestore.runTransaction((tx) async {
      tx.update(_requestsRef.doc(requestId), {'status': 'accepted'});

      final aRef = _friendsRef(req.fromUserId).doc(req.toUserId);
      final bRef = _friendsRef(req.toUserId).doc(req.fromUserId);

      tx.set(aRef, {
        'friendId': req.toUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(bRef, {
        'friendId': req.fromUserId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String requestId) async {
    await _requestsRef.doc(requestId).update({'status': 'rejected'});
  }

  Stream<List<String>> watchFriends({required String uid}) {
    return _friendsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => d.data()['friendId'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .toList());
  }
}
