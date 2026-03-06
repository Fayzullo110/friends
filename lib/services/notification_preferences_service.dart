import '../models/notification_preferences.dart';
import 'auth_service.dart';

class NotificationPreferencesService {
  NotificationPreferencesService._();

  static final NotificationPreferencesService instance =
      NotificationPreferencesService._();

  Future<NotificationPreferences> getMyPreferences() async {
    return AuthService.instance.api.getJson(
      '/api/notification-preferences',
      (json) => NotificationPreferences.fromJson(json),
    );
  }

  Future<NotificationPreferences> updateMyPreferences({
    bool? notifyLikes,
    bool? notifyComments,
    bool? notifyFriendRequests,
    bool? notifyFriendAccepted,
    bool? notifyFollows,
    bool? digestEnabled,
  }) async {
    return AuthService.instance.api.patchJson(
      '/api/notification-preferences',
      {
        'notifyLikes': notifyLikes,
        'notifyComments': notifyComments,
        'notifyFriendRequests': notifyFriendRequests,
        'notifyFriendAccepted': notifyFriendAccepted,
        'notifyFollows': notifyFollows,
        'digestEnabled': digestEnabled,
      },
      (json) => NotificationPreferences.fromJson(json),
    );
  }
}
