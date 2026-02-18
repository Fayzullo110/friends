import 'dart:async';

import '../models/user_status.dart';
import 'auth_service.dart';

class UserStatusService {
  static final UserStatusService instance = UserStatusService._();
  UserStatusService._();

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
    final res = await AuthService.instance.api.postJson(
      '/api/statuses',
      {
        'text': text,
        'emoji': emoji,
        'musicTitle': musicTitle,
        'musicArtist': musicArtist,
        'musicUrl': musicUrl,
      },
      (json) => UserStatus.fromJson(json),
    );
    return res.id;
  }

  /// Watch active statuses from followed users
  Stream<List<UserStatus>> watchFriendsStatuses({
    required String currentUserId,
    required List<String> followingIds,
  }) {
    final controller = StreamController<List<UserStatus>>();
    List<UserStatus>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/statuses');
        final all = rows.map(UserStatus.fromJson).toList();
        final allowed = <String>{...followingIds, currentUserId};
        final next = all.where((s) => allowed.contains(s.userId)).toList();
        if (last == null || !_statusesEqual(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (_) {
        controller.add(const <UserStatus>[]);
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 12), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  /// Watch current user's active status
  Stream<UserStatus?> watchMyStatus(String userId) {
    final controller = StreamController<UserStatus?>();
    UserStatus? last;

    Future<void> tick() async {
      try {
        final response = await AuthService.instance.api.get('/api/statuses/me');
        if (response.statusCode == 204) {
          controller.add(null);
          return;
        }
        AuthService.instance.api.throwForNon2xx(response);
        final decoded = AuthService.instance.api.decodeBody(response);
        if (decoded is Map<String, dynamic>) {
          final next = UserStatus.fromJson(decoded);
          if (last == null || !_statusEqual(last!, next)) {
            last = next;
            controller.add(next);
          }
          return;
        }
        if (last != null) {
          last = null;
          controller.add(null);
        }
      } catch (_) {
        if (last != null) {
          last = null;
          controller.add(null);
        }
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 12), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  bool _statusesEqual(List<UserStatus> a, List<UserStatus> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_statusEqual(a[i], b[i])) return false;
    }
    return true;
  }

  bool _statusEqual(UserStatus a, UserStatus b) {
    if (a.id != b.id) return false;
    if (a.userId != b.userId) return false;
    if (a.text != b.text) return false;
    if (a.emoji != b.emoji) return false;
    if (a.musicUrl != b.musicUrl) return false;
    if (a.createdAt.millisecondsSinceEpoch != b.createdAt.millisecondsSinceEpoch) {
      return false;
    }
    return true;
  }

  /// Mark status as seen
  Future<void> markSeen({
    required String statusId,
    required String userId,
  }) async {
    await AuthService.instance.api.postNoContent('/api/statuses/$statusId/seen');
  }

  /// Delete a status (only by owner)
  Future<void> deleteStatus({
    required String statusId,
    required String userId,
  }) async {
    await AuthService.instance.api.deleteNoContent('/api/statuses/$statusId');
  }

  /// Get status count for a user
  Future<int> getStatusCount(String userId) async {
    final rows = await AuthService.instance.api.getListOfMaps('/api/statuses');
    final all = rows.map(UserStatus.fromJson).toList();
    return all.where((s) => s.userId == userId).length;
  }
}
