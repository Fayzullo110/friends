import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_notification.dart';
import 'block_service.dart';
import 'auth_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Stream<List<AppNotification>> watchMyNotifications({required String uid}) {
    final controller = StreamController<List<AppNotification>>();
    List<AppNotification>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/notifications');
        final next = rows.map(AppNotification.fromJson).toList();
        if (last == null || !_equals(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (e) {
        debugPrint('[NotificationService] Failed to fetch notifications: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Stream<List<AppNotification>> watchMyUnreadNotifications({
    required String uid,
  }) {
    final controller = StreamController<List<AppNotification>>();
    List<AppNotification>? last;

    Future<void> tick() async {
      try {
        final rows = await AuthService.instance.api.getListOfMaps('/api/notifications/unread');
        final next = rows.map(AppNotification.fromJson).toList();
        if (last == null || !_equals(last!, next)) {
          last = next;
          controller.add(next);
        }
      } catch (e) {
        debugPrint('[NotificationService] Failed to fetch unread notifications: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    tick();
    final timer = Timer.periodic(const Duration(seconds: 15), (_) => tick());
    controller.onCancel = () {
      timer.cancel();
      controller.close();
    };
    return controller.stream;
  }

  Future<void> createNotification({
    required String toUserId,
    required AppNotificationType type,
    required String fromUserId,
    required String fromUsername,
    String? postId,
  }) async {
    // if (toUserId.isEmpty) return;
    // if (toUserId == fromUserId) return;
    if (toUserId == fromUserId) return;

    // If the receiver has blocked the sender, silently skip the notification.
    final receiverBlockedSender = await BlockService.instance.isBlocked(
      fromUserId: toUserId,
      toUserId: fromUserId,
    );
    if (receiverBlockedSender) return;

    await AuthService.instance.api.postNoContent(
      '/api/notifications',
      body: {
        'toUserId': int.parse(toUserId),
        'type': _typeToBackend(type),
        'postId': postId == null ? null : int.tryParse(postId),
      },
    );
  }

  Future<void> markAllAsRead({required String uid}) async {
    await AuthService.instance.api.postNoContent('/api/notifications/mark-all-read');
  }
}

String _typeToBackend(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.like:
      return 'like';
    case AppNotificationType.comment:
      return 'comment';
    case AppNotificationType.friendRequest:
      return 'friend_request';
    case AppNotificationType.friendAccepted:
      return 'friend_accepted';
    case AppNotificationType.follow:
      return 'follow';
  }
}

bool _equals(List<AppNotification> a, List<AppNotification> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final na = a[i];
    final nb = b[i];
    if (na.id != nb.id) return false;
    if (na.isRead != nb.isRead) return false;
    if (na.type != nb.type) return false;
    if (na.postId != nb.postId) return false;
    if (na.fromUserId != nb.fromUserId) return false;
  }
  return true;
}
