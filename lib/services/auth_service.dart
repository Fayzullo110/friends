import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String _googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  late final ApiClient _api;

  ApiClient get api => _api;

  void init({required String baseUrl}) {
    _api = ApiClient(baseUrl: baseUrl, enableLogging: false);
    // Emit initial auth state so StreamBuilder doesn't stay in waiting state.
    _userController.add(_currentUser);
  }

  // Stream of current user (emits null on logout)
  final _userController = StreamController<AppUser?>.broadcast();

  Stream<AppUser?> get userChanges async* {
    yield _currentUser;
    yield* _userController.stream;
  }

  AppUser? _currentUser;

  AppUser? get currentUser => _currentUser;

  Future<void> _loadMe() async {
    try {
      final user = await _api.getJson('/api/users/me', (json) => AppUser.fromJson(json));
      _currentUser = user;
      _userController.add(user);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('Unauthorized')) {
        // Expected when token is missing/expired; keep logs quiet.
      } else {
        debugPrint('[AuthService] Failed to load /me: $e');
      }
      await logout(); // clear token if invalid
    }
  }

  Future<void> initFromStoredToken() async {
    try {
      final token = await _api.getStoredToken();
      if (token == null || token.trim().isEmpty) {
        _currentUser = null;
      } else {
        await _loadMe();
      }
    } catch (e) {
      debugPrint('[AuthService] No stored token or invalid: $e');
    }
    // Ensure at least one emission even if the request was skipped/failed.
    _userController.add(_currentUser);
  }

  Future<void> refreshMe() async {
    if (_currentUser == null) return;
    await _loadMe();
  }

  Future<void> updateTheme({
    required String? themeKey,
    required int? themeSeedColor,
  }) async {
    if (_currentUser == null) return;

    await _api.patchNoContent(
      '/api/users/me',
      body: {
        'themeKey': themeKey,
        'themeSeedColor': themeSeedColor,
      },
    );

    _currentUser = _currentUser!.copyWith(
      themeKey: themeKey,
      themeSeedColor: themeSeedColor,
    );
    _userController.add(_currentUser);

    await refreshMe();
  }

  Future<bool> isUsernameAvailable(String username) async {
    final u = username.trim();
    if (u.isEmpty) return false;
    return await _api.getBool(
      '/api/users/username-available?u=${Uri.encodeQueryComponent(u)}',
    );
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required int age,
  }) async {
    final payload = {
      'email': email.trim(),
      'username': username.trim(),
      'password': password,
      if (firstName.trim().isNotEmpty) 'firstName': firstName.trim(),
      if (lastName.trim().isNotEmpty) 'lastName': lastName.trim(),
      if (age > 0) 'age': age,
    };
    final response = await _api.postJson('/api/auth/signup', payload, (json) {
      return {
        'accessToken': json['accessToken'] as String,
        'user': json['user'] as Map<String, dynamic>,
      };
    });
    await _api.storeToken(response['accessToken'] as String);
    final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final payload = {
      'identifier': email.trim(),
      'password': password,
    };
    final response = await _api.postJson('/api/auth/login', payload, (json) {
      return {
        'accessToken': json['accessToken'] as String,
        'user': json['user'] as Map<String, dynamic>,
      };
    });
    await _api.storeToken(response['accessToken'] as String);
    final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  Future<AppUser> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    return signIn(email: identifier, password: password);
  }

  Future<AppUser> signInWithGoogle() async {
    if (kIsWeb && _googleWebClientId.trim().isEmpty) {
      throw Exception(
        'Missing GOOGLE_WEB_CLIENT_ID. Run Flutter with --dart-define=GOOGLE_WEB_CLIENT_ID=... for web Google sign-in.',
      );
    }

    final googleSignIn = GoogleSignIn(
      scopes: const <String>['email', 'profile'],
      clientId: kIsWeb ? _googleWebClientId : null,
    );

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in canceled');
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google sign-in failed: missing idToken');
    }

    final response = await _api.postJson(
      '/api/auth/oauth/google',
      {
        'idToken': idToken,
      },
      (json) => {
        'accessToken': json['accessToken'] as String,
        'user': json['user'] as Map<String, dynamic>,
      },
    );

    await _api.storeToken(response['accessToken'] as String);
    final user = AppUser.fromJson(response['user'] as Map<String, dynamic>);
    _currentUser = user;
    _userController.add(user);
    return user;
  }

  Future<void> logout() async {
    await _api.clearToken();
    _currentUser = null;
    _userController.add(null);
  }

  Future<List<AppUser>> searchUsersByUsername(String query) async {
    final q = query.trim();
    if (q.isEmpty) return <AppUser>[];
    final rows = await _api.getListOfMaps(
      '/api/users/search?q=${Uri.encodeQueryComponent(q)}',
    );
    return rows.map(AppUser.fromJson).toList();
  }

  Future<void> updateProfile({
    required String uid,
    required String username,
    String? bio,
    String? photoUrl,
  }) async {
    final updated = await _api.patchJson(
      '/api/users/me',
      {
        'username': username.trim(),
        'bio': bio,
        'photoUrl': photoUrl,
      },
      (json) => AppUser.fromJson(json),
    );
    _currentUser = updated;
    _userController.add(updated);
  }

  void dispose() {
    _userController.close();
  }
}
