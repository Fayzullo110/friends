import 'package:flutter/material.dart';

import '../../theme/ios_icons.dart';
import '../../models/app_notification.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/post_service.dart';
import '../../services/reel_service.dart';
import '../../services/notification_preferences_service.dart';
import 'notification_settings_screen.dart';
import '../post/post_viewer_screen.dart';
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  List<_DigestRow> _digest(List<AppNotification> items) {
    final Map<String, _DigestRow> byKey = {};
    for (final n in items) {
      final key = '${n.type.name}:${n.fromUserId}:${n.postId ?? ''}';
      final existing = byKey[key];
      if (existing == null) {
        byKey[key] = _DigestRow(
          notification: n,
          count: 1,
        );
      } else {
        byKey[key] = existing.copyWith(count: existing.count + 1);
      }
    }
    final out = byKey.values.toList();
    out.sort((a, b) => b.notification.createdAt.compareTo(a.notification.createdAt));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final me = AuthService.instance.currentUser;
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const Center(child: Text('Please log in to see notifications.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(IOSIcons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: NotificationService.instance.watchMyNotifications(uid: me.id),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            NotificationService.instance.markAllAsRead(uid: me.id);
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return Center(
              child: Text(
                'No notifications yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            );
          }

          return FutureBuilder(
            future: NotificationPreferencesService.instance.getMyPreferences(),
            builder: (context, prefsSnap) {
              final digestEnabled = prefsSnap.data?.digestEnabled ?? false;
              if (!digestEnabled) {
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.08),
                  ),
                  itemBuilder: (context, index) {
                    return _NotificationTile(
                      notification: items[index],
                      theme: theme,
                    );
                  },
                );
              }

              final rows = _digest(items);
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rows.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
                itemBuilder: (context, index) {
                  return _DigestTile(row: rows[index], theme: theme);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DigestRow {
  final AppNotification notification;
  final int count;

  const _DigestRow({required this.notification, required this.count});

  _DigestRow copyWith({AppNotification? notification, int? count}) {
    return _DigestRow(
      notification: notification ?? this.notification,
      count: count ?? this.count,
    );
  }
}

class _DigestTile extends StatelessWidget {
  final _DigestRow row;
  final ThemeData theme;

  const _DigestTile({required this.row, required this.theme});

  @override
  Widget build(BuildContext context) {
    final n = row.notification;
    final text = row.count <= 1
        ? _NotificationTile(notification: n, theme: theme)._text()
        : '${_NotificationTile(notification: n, theme: theme)._text()} (${row.count}x)';

    return ListTile(
      onTap: () => _NotificationTile(notification: n, theme: theme)._open(context),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceVariant,
        child: Icon(
          _NotificationTile(notification: n, theme: theme)._iconForType(),
          size: 18,
          color: _NotificationTile(notification: n, theme: theme)._colorForType(),
        ),
      ),
      title: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        n.createdAt.toLocal().toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final ThemeData theme;

  const _NotificationTile({
    required this.notification,
    required this.theme,
  });

  IconData _iconForType() {
    switch (notification.type) {
      case AppNotificationType.like:
        return IOSIcons.heartFill;
      case AppNotificationType.comment:
        return IOSIcons.chatBubbleOutline;
      case AppNotificationType.friendRequest:
        return IOSIcons.personAdd;
      case AppNotificationType.friendAccepted:
        return IOSIcons.personFill;
      case AppNotificationType.follow:
        return IOSIcons.personAdd;
    }
  }

  Color _colorForType() {
    switch (notification.type) {
      case AppNotificationType.like:
        return Colors.pinkAccent;
      case AppNotificationType.comment:
        return theme.colorScheme.primary;
      case AppNotificationType.friendRequest:
        return Colors.blueAccent;
      case AppNotificationType.friendAccepted:
        return Colors.green;
      case AppNotificationType.follow:
        return theme.colorScheme.primary;
    }
  }

  String _text() {
    final name = notification.fromUsername.isNotEmpty
        ? notification.fromUsername
        : 'Someone';
    switch (notification.type) {
      case AppNotificationType.like:
        return '$name liked your content';
      case AppNotificationType.comment:
        return '$name commented on your content';
      case AppNotificationType.friendRequest:
        return '$name sent you a friend request';
      case AppNotificationType.friendAccepted:
        return '$name accepted your friend request';
      case AppNotificationType.follow:
        return '$name started following you';
    }
  }

  Future<void> _open(BuildContext context) async {
    try {
      switch (notification.type) {
        case AppNotificationType.follow:
        case AppNotificationType.friendRequest:
        case AppNotificationType.friendAccepted:
          if (notification.fromUserId.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProfileScreen(userId: notification.fromUserId),
            ),
          );
          return;
        case AppNotificationType.like:
        case AppNotificationType.comment:
          final id = notification.postId;
          if (id == null || id.isEmpty) return;

          try {
            final post = await PostService.instance.getPostById(postId: id);
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostViewerScreen(
                  posts: [post],
                  initialIndex: 0,
                ),
              ),
            );
            return;
          } catch (_) {
            // Fallback: some older code paths store reelId in postId.
            await ReelService.instance.getReelById(reelId: id);
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReelsScreen(initialReelId: id),
              ),
            );
            return;
          }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _open(context),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceVariant,
        child: Icon(
          _iconForType(),
          size: 18,
          color: _colorForType(),
        ),
      ),
      title: Text(
        _text(),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        notification.createdAt.toLocal().toString(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}
