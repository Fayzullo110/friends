import 'auth_service.dart';

class PresenceService {
  PresenceService._();

  static final PresenceService instance = PresenceService._();

  Future<void> setOnline(bool online) async {
    final me = AuthService.instance.currentUser;
    if (me == null) return;
    await AuthService.instance.api.postNoContent(
      '/api/presence',
      body: {
        'online': online,
      },
    );
  }
}
