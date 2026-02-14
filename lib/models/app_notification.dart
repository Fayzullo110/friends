import 'package:cloud_firestore/cloud_firestore.dart';

enum AppNotificationType {
  like,
  comment,
  friendRequest,
  friendAccepted,
  follow,
}

class AppNotification {
  final String id;
  final AppNotificationType type;
  final String fromUserId;
  final String fromUsername;
  final String? postId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.fromUserId,
    required this.fromUsername,
    required this.createdAt,
    this.isRead = false,
    this.postId,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final typeStr = data['type'] as String? ?? 'like';

    return AppNotification(
      id: doc.id,
      type: _typeFromString(typeStr),
      fromUserId: data['fromUserId'] as String? ?? '',
      fromUsername: data['fromUsername'] as String? ?? '',
      postId: data['postId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': _typeToString(type),
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'postId': postId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  static AppNotificationType _typeFromString(String value) {
    switch (value) {
      case 'comment':
        return AppNotificationType.comment;
      case 'friend_request':
        return AppNotificationType.friendRequest;
      case 'friend_accepted':
        return AppNotificationType.friendAccepted;
      case 'follow':
        return AppNotificationType.follow;
      case 'like':
        return AppNotificationType.like;
      default:
        return AppNotificationType.like;
    }
  }

  static String _typeToString(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.comment:
        return 'comment';
      case AppNotificationType.friendRequest:
        return 'friend_request';
      case AppNotificationType.friendAccepted:
        return 'friend_accepted';
      case AppNotificationType.follow:
        return 'follow';
      case AppNotificationType.like:
        return 'like';
    }
  }
}
