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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'like';

    return AppNotification(
      id: json['id'].toString(),
      type: _typeFromString(typeStr),
      fromUserId: json['fromUserId']?.toString() ?? '',
      fromUsername: json['fromUsername'] as String? ?? '',
      postId: json['postId']?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (json['createdAt'] as num?)?.toInt() ?? 0,
        isUtc: false,
      ),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': _typeToString(type),
      'fromUserId': fromUserId,
      'fromUsername': fromUsername,
      'postId': postId,
      'createdAt': createdAt.toIso8601String(),
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
