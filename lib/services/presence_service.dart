import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  final _firestore = FirebaseFirestore.instance;

  Future<void> setOnline(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': online,
      'lastActiveAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
