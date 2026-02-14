import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppUser?> get userChanges {
    return _auth.userChanges().asyncMap((user) async {
      if (user == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          return AppUser(
            id: user.uid,
            email: user.email ?? '',
            username: user.email?.split('@').first ?? 'user',
          );
        }
        return AppUser.fromDoc(doc);
      } catch (_) {
        // If Firestore is offline or unavailable, fall back to a minimal user
        // so the app can still proceed with authentication.
        return AppUser(
          id: user.uid,
          email: user.email ?? '',
          username: user.email?.split('@').first ?? 'user',
        );
      }
    });
  }

  /// Returns true if the given username is not used by any user.
  Future<bool> isUsernameAvailable(String username) async {
    final normalized = username.trim();
    if (normalized.isEmpty) return false;

    final snap = await _firestore
        .collection('users')
        .where('username', isEqualTo: normalized)
        .limit(1)
        .get();

    return snap.docs.isEmpty;
  }

  /// Search users by username prefix (case-sensitive for now).
  Future<List<AppUser>> searchUsersByUsername(String query,
      {int limit = 20}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final snap = await _firestore
        .collection('users')
        .where('username', isGreaterThanOrEqualTo: trimmed)
        .where('username', isLessThanOrEqualTo: '$trimmed\uf8ff')
        .limit(limit)
        .get();

    return snap.docs.map(AppUser.fromDoc).toList();
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
  }) async {
    final normalizedUsername = username.trim();

    // Ensure username is unique across all users.
    final available = await isUsernameAvailable(normalizedUsername);
    if (!available) {
      throw FirebaseAuthException(
        code: 'username-already-in-use',
        message: 'This username is already taken. Please choose another one.',
      );
    }

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final user = AppUser(
      id: uid,
      email: email,
      username: normalizedUsername,
      firstName: firstName.trim().isEmpty ? null : firstName.trim(),
      lastName: lastName.trim().isEmpty ? null : lastName.trim(),
      age: age,
    );
    await _firestore.collection('users').doc(uid).set(user.toMap());
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      final user = AppUser(
        id: uid,
        email: email,
        username: email.split('@').first,
      );
      await _firestore.collection('users').doc(uid).set(user.toMap());
      return user;
    }
    return AppUser.fromDoc(doc);
  }

  /// Sign in using either an email address or a username.
  ///
  /// If [identifier] contains '@', it is treated as an email.
  /// Otherwise, we look up the user by username in Firestore and then
  /// authenticate with their email.
  Future<AppUser> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-identifier',
        message: 'Please enter your email or username.',
      );
    }

    if (trimmed.contains('@')) {
      // Treat as email login.
      return signIn(email: trimmed, password: password);
    }

    // Treat as username: look up the corresponding user document.
    final snap = await _firestore
        .collection('users')
        .where('username', isEqualTo: trimmed)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found-username',
        message: 'No account found for that username.',
      );
    }

    final data = snap.docs.first.data();
    final email = data['email'] as String?;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-email-missing',
        message: 'This account is missing an email address.',
      );
    }

    return signIn(email: email, password: password);
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    String? bio,
    String? photoUrl,
  }) async {
    final normalized = username.trim();
    if (normalized.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-username',
        message: 'Username cannot be empty.',
      );
    }

    // Ensure username is either unchanged or still unique.
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final currentUsername = (userDoc.data() ?? const {})['username'] as String?;
    if (currentUsername == null || currentUsername != normalized) {
      final available = await isUsernameAvailable(normalized);
      if (!available) {
        throw FirebaseAuthException(
          code: 'username-already-in-use',
          message: 'This username is already taken. Please choose another one.',
        );
      }
    }

    final update = <String, dynamic>{
      'username': normalized,
      'bio': bio,
      'photoUrl': photoUrl,
    };

    await _firestore.collection('users').doc(uid).set(
          update,
          SetOptions(merge: true),
        );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
